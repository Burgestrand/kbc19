require 'google/cloud/pubsub'

class GooglePubSubActiveJobAdapter
  # A tiny abstraction around Google Pub/Sub topics and subscribers.
  class Queue < Struct.new(:topic, :subscription)
  end

  # @param [Google::Cloud::Pubsub] :pubsub:
  # @param [Array<String>] :queues: whitelist of queue names allowed in jobs
  def initialize(pubsub:, queues:)
    @pubsub = pubsub
    @queues = queues.reduce({}).map { |hash, queue_name|
      topic = pubsub.find_topic(queue_name)
      subscription = pubsub.find_subscription("#{queue_name}-subscription-main")
      hash.merge(queue_name => Queue.new(topic: topic, subscription: subscription))
    }
  end

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
  pubsub = Google::Cloud::Pubsub.new(credentials: ENV.fetch("GOOGLE_CLOUD_CREDENTIALS"))
  active_job.adapter = GooglePubSubActiveJobAdapter.new(pubsub: pubsub)
end