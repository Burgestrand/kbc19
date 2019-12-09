require Rails.root.join('app/jobs/google_pub_sub_adapter').to_s

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

  active_job.queue_adapter = GooglePubSubAdapter.new(
    pubsub: pubsub,
    queues: %w[default morgue]
  )
end