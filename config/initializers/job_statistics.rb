ActiveSupport::Notifications.subscribe 'perform.active_job' do |event|
  job = event.payload.fetch(:job)

  JobExecution.create! do |job_execution|
    job_execution.provider_job_id = job.provider_job_id
    job_execution.duration = event.duration
  end
end