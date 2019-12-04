require 'rails_helper'

RSpec.describe GenericJob, type: :job do
  let(:job_class) { described_class }
  let(:test_adapter) {
    adapter = ActiveJob::QueueAdapters::TestAdapter.new
    adapter.perform_enqueued_jobs = true
    adapter
  }

  around(:each) do |example|
    ActiveJob::Base.enable_test_adapter(test_adapter)
    example.run
    ActiveJob::Base.disable_test_adapter
  end

  it "explodes when asked to" do
    expect {
      job_class.perform_later("explode")
    }.to raise_error
  end
end