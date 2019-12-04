namespace :active_job do
  desc "Create Google Pub/Sub topics and subscribers. Idempotent."
  task setup: :environment do
    adapter = ActiveJob::Base.queue_adapter
    adapter.queues.each do |name, queue|
      Rails.logger.info "Setting up queue: #{name}."
      queue.create_if_necessary!
    end
  end

  desc "Run the ActiveJob worker!"
  task work: :environment do
    adapter = ActiveJob::Base.queue_adapter

    Rails.logger.debug "Starting workers."

    subscribers = adapter.queues.map do |name, queue|
      worker_name = "Worker##{name}"

      Rails.logger.debug "[#{worker_name}] Starting."

      subscriber = queue.subscription.listen do |message|
        Rails.logger.info "[#{worker_name}] #{message}"
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
