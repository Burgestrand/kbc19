require 'google/cloud/pubsub'

class GooglePubSubActiveJobAdapter
  class Error < StandardError; end

  EMULATOR = {
    emulator_host: "localhost:8085",
    project_id: "google-pubsub-emulator".freeze
  }

  # @param [ActiveJob::Base]
  # @return [String]
  def self.encode_job(job)
    job.serialize.to_json
  end

  # @param [Google::Cloud::Pubsub::ReceivedMessage] message
  # @return [ActiveJob::Base]
  def self.decode_message(message)
    serialized_job = JSON.parse(message.data)
    job = ActiveJob::Base.deserialize(serialized_job)
    job.provider_job_id = message.message_id
    job.scheduled_at = message.attributes["timestamp"]&.to_i
    job
  end

  # A tiny abstraction around Google Pub/Sub topics and subscribers.
  class Queue
    def initialize(name, pubsub:)
      @name = name.to_s
      @pubsub = pubsub
      @topic = pubsub.find_topic(topic_name)
      @subscription = pubsub.find_subscription(subscription_name)

      if topic.present? && (subscription.blank? || !subscription.topic.exists?)
        # Note: `#create_if_necessary!` has an invariant based on this error.
        raise Error, "No active subscription found for queue topic #{name}"
      end
    end

    def create_if_necessary!
      if topic.blank?
        @topic = pubsub.create_topic(topic_name).tap do |topic|
          raise error, "Unable to create topic #{topic_name}" if topic.nil?
        end
      end

      @subscription = @topic.find_subscription(subscription_name) || @topic.create_subscription(subscription_name)
      @subscription.tap do |subscription|
        raise Error, "Unable to create subscription #{subscription_name}" if subscription.nil?

        # Default subscription expiry is 31 days. We want none of that.
        subscription.expires_in = nil unless pubsub.project_id == EMULATOR.fetch(:project_id)
      end
    end

    def destroy!(this_is_not_accidental:)
      @topic.delete
      @subscription.delete
    end

    # @return [String]
    attr_reader :name

    # @return [Google::Cloud::Pubsub]
    attr_reader :pubsub

    # @return [Google::Cloud::Pubsub::Topic]
    attr_reader :topic

    # @return [Google::Cloud::Pubsub::Subscription]
    attr_reader :subscription

    # @return [String] google pub/sub short name for our topic
    private def topic_name
      name
    end

    # @return [String] google pub/sub short name for our main subscription
    private def subscription_name
      "#{name}-subscription-main"
    end
  end

  # @param [Google::Cloud::Pubsub, :emulator] :pubsub:
  # @param [Array<String>] :queues: whitelist of queue names allowed in jobs
  def initialize(pubsub:, queues:)
    pubsub = Google::Cloud::PubSub.new(EMULATOR) if pubsub == :emulator

    @pubsub = pubsub
    @queues = queues.reduce({}) { |hash, queue_name|
      queue_name = queue_name.to_s
      hash.merge(queue_name => Queue.new(queue_name, pubsub: pubsub))
    }.freeze
  end

  # @return [Hash<String, Queue>] whitelist of queues, as passed into #initialize
  attr_reader :queues

  # @return [Google::Cloud::Pubsub] pubsub instance this adapter was created with.
  attr_reader :pubsub

  #
  # ActiveJob adapter API.
  #

  # Enqueue a job for immediate execution.
  def enqueue(job)
    enqueue_at(job, nil)
  end

  # Enqueue a job for execution some time later.
  #
  # @param [ActiveJob::Base] job
  # @param [Numeric] timestamp UNIX timestamp
  def enqueue_at(job, timestamp)
    queue = queues.fetch(job.queue_name)
    serialized_job = self.class.encode_job(job)
    attributes = timestamp && { "timestamp" => Integer(timestamp) }
    message = queue.topic.publish(serialized_job, attributes)
    # NOTE: This is not strictly necessary, but it feels
    # consistent with how decode_message works.
    job.provider_job_id = message.message_id
  end
end

Rails.application.config.active_job.tap do |active_job|
  pubsub = if Rails.env.production?
    credentials = JSON.parse(ENV.fetch("GOOGLE_CLOUD_CREDENTIALS"))
    Google::Cloud::Pubsub.new(credentials: credentials)
  elsif Rails.env.development?
    credentials = JSON.parse(Rails.application.credentials.fetch(:GOOGLE_CLOUD_CREDENTIALS))
    Google::Cloud::Pubsub.new(credentials: credentials)
  elsif Rails.env.test?
    :emulator
  end

  active_job.queue_adapter = GooglePubSubActiveJobAdapter.new(
    pubsub: pubsub,
    queues: %w[default]
  )
end