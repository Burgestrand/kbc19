require 'rails_helper'

RSpec.describe "Job statistics", type: :job do
  it "records statistics when jobs are run" do
    job = GenericJob.new("noop")
    job.provider_job_id = "Job this"

    expect {
      job.perform_now
    }.to change { JobExecution.count }.from(0).to(1)

    execution = JobExecution.first!
    expect(execution.provider_job_id).to eq("Job this")
    expect(execution.duration).to be > 0
  end
end