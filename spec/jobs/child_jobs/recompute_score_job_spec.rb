require 'rails_helper'

RSpec.describe ChildJobs::RecomputeScoreJob, type: :job do
  let(:job_class) { described_class }

  around(:each) do |example|
    ActiveJob::Base.enable_test_adapter(ActiveJob::QueueAdapters::TestAdapter.new)
    example.run
    ActiveJob::Base.disable_test_adapter
  end

  it "matches with enqueued job" do
    job_class.perform_later
    expect(job_class).to have_been_enqueued
  end
end