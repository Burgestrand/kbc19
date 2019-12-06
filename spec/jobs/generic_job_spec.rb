require 'rails_helper'

RSpec.describe GenericJob, type: :job do
  let(:job_class) { described_class }

  it "runs just fine when not exploding"
  it "runs jobs 3 times on failure before moving to morgue"
end