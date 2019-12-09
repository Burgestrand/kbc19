namespace :active_job do
  desc "Create Google Pub/Sub topics and subscribers. Idempotent."
  task setup: :environment do
    adapter = ActiveJob::Base.queue_adapter
    adapter.queues.each do |name, queue|
      Rails.logger.info "Setting up queue: #{name}."
      queue.create_if_necessary!
    end
  end

  namespace :emulator do
    task :start do
      sh "gcloud beta emulators pubsub start"
    end
  end

  desc "Run the ActiveJob worker!"
  task work: :environment do
    queues_argument = ENV.fetch("QUEUES") do
      abort "You must specify QUEUES= environment variable, e.g. QUEUES=default"
    end

    queues = Set.new(queues_argument.split(","))
    abort "No work queues specified in QUEUES. Aborting." if queues.empty?

    adapter = ActiveJob::Base.queue_adapter

    subscribers = queues.map do |name|
      worker_name = "Worker##{name}"
      queue = adapter.queues.fetch(name) do
        abort "Unknown queue name, #{name}!"
      end

      Rails.logger.debug "[#{worker_name}] Starting."

      subscriber = queue.subscription.listen do |message|
        Rails.logger.debug "[#{worker_name}] Executing ##{message.message_id}"
        GooglePubSubAdapter.execute(message)
      end
      
      subscriber.on_error do |error|
        Rails.logger.error "[#{worker_name}] #{error}"
      end

      subscriber.start
    end

    begin
      # We loop here, because sleep might sporadically wake up.
      loop { sleep }
    rescue Interrupt
      Rails.logger.debug "Gracefully shutting down workers."
      subscribers.each(&:stop!)
    end
  end
end
