require 'google/cloud/pubsub'

class GooglePubSubAdapter
  EMULATOR = {
    emulator_host: "localhost:8085",
    project_id: "google-pubsub-emulator".freeze
  }.freeze

  class Error < StandardError; end

  # A tiny abstraction around Google Pub/Sub topics and subscribers.
  class Queue
    # @param [#to_s] name
    # @param [Google::Cloud::Pubsub] :pubsub:
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

    # Idempotent. Create topic/subscription if necessary, otherwise does nothing.
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

    # Remove both topic and subscription. Beware.
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

  # Perform the logic necessary to execute the job within the message.
  #
  # @note Delayed jobs are a bit special in how they're executed.
  # @param [Google::Cloud::Pubsub::ReceivedMessage] message
  def self.execute(message)
    job = decode_message(message)
    delayed_by = if job.scheduled_at.present?
      job.scheduled_at - Time.now.to_i
    end

    if delayed_by && delayed_by > 0
      # Modify ack! deadline so that the message is automatically rescheduled
      # once it's past its deadline.
      message.modify_ack_deadline!(delayed_by)
    else
      job.perform_now
      message.ack!
    end
  end

  # @param [Google::Cloud::Pubsub, :emulator] :pubsub:
  # @param [Array<String>] :queues: whitelist of queue names allowed in jobs
  def initialize(pubsub:, queues:)
    if pubsub == :emulator
      # Cloud client hangs forever if emulator isn't started. Let's double-check
      # the connection before we try to hook it up.
      begin
        host, port = EMULATOR.fetch(:emulator_host).split(":", 2)
        Socket.tcp(host, port, { connect_timeout: 0.1 }, &:close)
      rescue Errno::ECONNREFUSED
        raise Error, "Emulator does not appear to be running at #{host}:#{port}"
      end

      pubsub = Google::Cloud::PubSub.new(EMULATOR)
    end

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
    queue = queues.fetch(job.queue_name) do
      raise Error, "Unknown queue #{job.queue_name} — did you forget to add it to the adapter whitelist?"
    end
    serialized_job = self.class.encode_job(job)
    attributes = timestamp && { "timestamp" => Integer(timestamp) }
    message = queue.topic.publish(serialized_job, attributes)
    # NOTE: This is not strictly necessary, but it feels
    # consistent with how decode_message works.
    job.provider_job_id = message.message_id
  end
end
