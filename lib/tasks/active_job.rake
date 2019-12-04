namespace :active_job do
  desc "Create Google Pub/Sub topics and subscribers."
  task create_queues: :environment do
    adapter = ActiveJob::Base.queue_adapter
    adapter.queues.each do |name, queue|
      queue.create_if_necessary!
    end
  end
end
