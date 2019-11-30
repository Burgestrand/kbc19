require 'rails_helper'

RSpec.describe ChildJobs::RecomputeScoreJob do 
  let(:job_class) { described_class }

  it "matches with enqueued job" do
    ActiveJob::Base.queue_adapter = :test
    job_class.perform_later
    expect(job_class).to have_been_enqueued
  end
end