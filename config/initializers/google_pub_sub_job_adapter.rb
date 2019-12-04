require 'google/cloud/pubsub'

class GooglePubSubActiveJobAdapter
  class Error < StandardError; end

  # A tiny abstraction around Google Pub/Sub topics and subscribers.
  class Queue
    def initialize(name, pubsub:)
      @name = name.to_s
      @pubsub = pubsub
      @topic = pubsub.find_topic(topic_name)
      @subscription = pubsub.find_subscription(subscription_name)

      if topic.present? && subscription.blank?
        # Note: `#create_if_necessary!` has an invariant based on this error.
        raise Error, "No subscription found for queue topic #{name}"
      end
    end

    def create_if_necessary!
      # We assume that our initializer would've failed if our topic exists but
      # not our subscription.
      return unless topic.blank?
      @topic = pubsub.create_topic(topic_name)
      @subscription = topic.create_subscription(subscription_name).yield_self do |subscription|
        # Default subscription expiry is 31 days. We want none of that.
        subscription.expires_in = nil
      end
    end

    # @returns [String]
    attr_reader :name

    # @returns [Google::Cloud::Pubsub]
    attr_reader :pubsub

    # @returns [Google::Cloud::Pubsub::Topic]
    attr_reader :topic

    # @returns [Google::Cloud::Pubsub::Subscription]
    attr_reader :subscription

    # @returns [String] google pub/sub short name for our topic
    private def topic_name
      name
    end

    # @returns [String] google pub/sub short name for our main subscription
    private def subscription_name
      "#{name}-subscription-main"
    end
  end

  # @param [Google::Cloud::Pubsub] :pubsub:
  # @param [Array<String>] :queues: whitelist of queue names allowed in jobs
  def initialize(pubsub:, queues:)
    @pubsub = pubsub
    @queues = queues.reduce({}) { |hash, queue_name|
      hash.merge(queue_name => Queue.new(queue_name, pubsub: pubsub))
    }.freeze
  end

  # @returns [Hash<String, Queue>] whitelist of queues, as passed into #initialize
  attr_reader :queues

  # @returns [Google::Cloud::Pubsub] pubsub instance this adapter was created with.
  attr_reader :pubsub

  #
  # ActiveJob adapter API.
  #

  def enqueue(job)
    queue = queues.fetch(job.queue_name)
    message = queue.topic.publish(job.serialize)
    job.provider_job_id = message.message_id
  end

  def enqueue_at(job, timestamp)
    raise NotImplementedError
  end
end

Rails.application.config.active_job.tap do |active_job|
  credentials = if Rails.env.production?
    JSON.parse(ENV.fetch("GOOGLE_CLOUD_CREDENTIALS"))
  else
    JSON.parse(Rails.application.credentials.fetch(:GOOGLE_CLOUD_CREDENTIALS))
  end

  pubsub = Google::Cloud::Pubsub.new(credentials: credentials)
  active_job.queue_adapter = GooglePubSubActiveJobAdapter.new(
    pubsub: pubsub,
    queues: %w[default]
  )
end