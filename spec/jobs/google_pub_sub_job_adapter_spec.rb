require 'rails_helper'

RSpec.describe GooglePubSubActiveJobAdapter do
  class FakeJob < ActiveJob::Base
    queue_as :test_queue

    @count = 0

    class << self
      attr_accessor :count
    end

    def perform(a, b)
      # Note: don't try to run parallel tests with this implementation.
      self.class.count += 1
    end
  end

  let(:queue_name) { "test_queue" }
  let(:job_adapter) { described_class.new(pubsub: :emulator, queues: [queue_name]) }
  let(:test_queue) { job_adapter.queues.fetch(queue_name) }
  let(:job) { FakeJob.new(2, 2) }

  around(:each) do |example|
    test_queue.create_if_necessary!
    example.run
    test_queue.destroy!(this_is_not_accidental: true)
  end

  describe ".execute" do
    it "executes #enqueue'd messages right away" do
      expect(test_queue.subscription.pull).to be_empty
      job_adapter.enqueue(job)

      message = test_queue.subscription.wait_for_messages[0]
      decoded_job = described_class.decode_message(message)

      expect(message).to receive(:ack!).and_call_original

      expect { described_class.execute(message) }
        .to change { FakeJob.count }.by(1)
    end

    it "delays execution/re-queueing of #enqueue_at'd messages" do
      future_timestamp = 10.minutes.from_now.to_i

      expect(test_queue.subscription.pull).to be_empty
      job_adapter.enqueue_at(job, future_timestamp)

      message = test_queue.subscription.wait_for_messages[0]
      decoded_job = described_class.decode_message(message)

      expect(message).not_to receive(:ack!)
      expect(message).to receive(:modify_ack_deadline!).with(10.minutes)

      expect { described_class.execute(message) }
        .not_to change { FakeJob.count }
    end
  end

  describe "#enqueue" do
    it "publishes the job without a timestamp" do
      expect(job_adapter).to receive(:enqueue_at).with(job, nil)
      job_adapter.enqueue(job)
    end
  end

  describe "#enqueue_at" do
    it "assigns message id to job" do
      expect {
        job_adapter.enqueue(job)
      }.to change { job.provider_job_id }.from(nil)
    end

    it "publishes the job without timestamp" do
      expect(test_queue.subscription.pull).to be_empty
      job_adapter.enqueue_at(job, nil)

      message = test_queue.subscription.wait_for_messages[0]
      decoded_job = described_class.decode_message(message)

      expect(decoded_job).to be_a(FakeJob)
      expect(decoded_job.provider_job_id).not_to be_blank
      expect(decoded_job.provider_job_id).to eq(message.message_id)
      expect(decoded_job.scheduled_at).to be_blank
    end

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