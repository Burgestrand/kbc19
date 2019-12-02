class ChildJobs::RecomputeScoreJob < ApplicationJob
  queue_as :default

  def perform(child)
    raise "Hell"
  end
end