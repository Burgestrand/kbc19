require 'rails_helper'

RSpec.describe GooglePubSubActiveJobAdapter do
  class FakeJob < ActiveJob::Base
    queue_as :test_queue

    def perform(work)
    end
  end

  let(:queue_name) { "test_queue" }
  let(:job_adapter) { described_class.new(pubsub: :emulator, queues: [queue_name]) }
  let(:test_queue) { job_adapter.queues.fetch(queue_name) }

  around(:each) do |example|
    test_queue.create_if_necessary!
    example.run
    test_queue.destroy!(this_is_not_accidental: true)
  end

  describe "#enqueue" do
    it "publishes the job to its topic" do
      job = FakeJob.new("test-job-1")

      expect(test_queue.subscription.pull).to be_empty
      job_adapter.enqueue(job)
      expect(test_queue.subscription.wait_for_messages).not_to be_empty
    end

    it "assigns message id to the job"
  end

  describe ".decode_message" do
    it "decodes into a job that is executable"
    it "assigns message id as provider job id"
  end
end