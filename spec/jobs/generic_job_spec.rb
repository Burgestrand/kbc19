require 'rails_helper'

RSpec.describe GenericJob, type: :job do
  class MoreUsefulTestAdapter
    def initialize
      @jobs = []
    end

    attr_reader :jobs

    def dequeue
      raise "No jobs available" if jobs.empty?
      job, timestamp = jobs.shift
      [ActiveJob::Base.deserialize(job), timestamp && Time.at(timestamp)]
    end

    def enqueue(job)
      jobs << [job.serialize, nil]
    end

    def enqueue_at(job, timestamp)
      jobs << [job.serialize, timestamp]
    end
  end

  let(:test_adapter) { MoreUsefulTestAdapter.new }

  it "runs just fine when not exploding" do
    job = GenericJob.new("noop")

    expect {
      job.perform_now
    }.not_to change { test_adapter.jobs }
  end

  it "runs jobs 3 times on failure before moving to morgue" do
    start_timestamp = Time.now
    GenericJob.perform_later("explode")

    first_job, first_timestamp = test_adapter.dequeue
    expect(first_timestamp).to eq(nil)
    expect { first_job.perform_now }.to change { test_adapter.jobs }

    second_job, second_timestamp = test_adapter.dequeue
    expect(second_timestamp.to_i).to be_within(1.second).of((start_timestamp + 5.minutes).to_i)
    travel_to second_timestamp
    expect { second_job.perform_now }.to change { test_adapter.jobs }

    third_job, third_timestamp = test_adapter.dequeue
    expect(third_timestamp.to_i).to be_within(1.second).of((second_timestamp + 5.minutes).to_i)
    travel_to third_timestamp
    expect { third_job.perform_now }.to change { test_adapter.jobs }

    final_job, final_timestamp = test_adapter.dequeue
    expect(final_timestamp).to eq(nil)
    expect(final_job.queue_name).to eq("morgue")
  end
end