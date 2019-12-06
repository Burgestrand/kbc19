class JobExecution < ApplicationRecord
  # @!attribute provider_job_id
  # @return [String]

  # @!attribute duration
  # @return [Integer] duration in milliseconds

  def duration_in_seconds
    duration / 1000.0
  end
end
