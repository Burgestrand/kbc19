require 'rails_helper'

RSpec.describe GenericJob, type: :job do
  it "runs just fine when not exploding" do
    job = GenericJob.new("noop")

    expect {
      job.perform_now
    }.not_to have_enqueued_job
  end

  it "runs jobs 3 times on failure before moving to morgue"
end