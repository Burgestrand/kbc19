class GooglePubSubJobAdapter
end

Rails.application.config.active_job.tap do |active_job|
  active_job.adapter = GooglePubSubJobAdapter.new
end