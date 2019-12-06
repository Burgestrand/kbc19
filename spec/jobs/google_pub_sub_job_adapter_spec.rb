require 'rails_helper'

RSpec.describe GooglePubSubActiveJobAdapter do
  class FakeJob < ActiveJob::Base
    queue_as :test_queue

    def perform(work)
      "Performed: #{work}"
    end
  end

  let(:queue_name) { "test_queue" }
  let(:job_adapter) { described_class.new(pubsub: :emulator, queues: [queue_name]) }
  let(:test_queue) { job_adapter.queues.fetch(queue_name) }
  let(:job) { FakeJob.new("enqueue-test-job") }

  around(:each) do |example|
    test_queue.create_if_necessary!
    example.run
    test_queue.destroy!(this_is_not_accidental: true)
  end

  describe "#enqueue" do
    it "publishes the job with associated information" do
      expect(test_queue.subscription.pull).to be_empty
      job_adapter.enqueue(job)

      message = test_queue.subscription.wait_for_messages[0]
      decoded_job = described_class.decode_message(message)

      expect(decoded_job).to be_a(FakeJob)
      expect(decoded_job.provider_job_id).not_to be_empty
      expect(decoded_job.provider_job_id).to eq(message.message_id)

      expect(decoded_job.scheduled_at).to be_blank

      expect(decoded_job.perform_now).to eq("Performed: enqueue-test-job")
    end

    it "assigns message id to the job" do
      expect {
        job_adapter.enqueue(job)
      }.to change { job.provider_job_id }.from(nil)
    end
  end

  describe "#enqueue_at" do
    it "publishes the job with associated timestamp" do
      future_timestamp = 10.minutes.from_now.to_i

      expect(test_queue.subscription.pull).to be_empty
      job_adapter.enqueue_at(job, future_timestamp)

      message = test_queue.subscription.wait_for_messages[0]
      decoded_job = described_class.decode_message(message)

      expect(decoded_job).to be_a(FakeJob)
      expect(decoded_job.provider_job_id).not_to be_blank
      expect(decoded_job.provider_job_id).to eq(message.message_id)

      expect(decoded_job.scheduled_at).to eq(future_timestamp)
    end
  end
end