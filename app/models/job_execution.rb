class JobExecution < ApplicationRecord
  # @!attribute provider_job_id
  # @return [String]

  # @!attribute duration
  # @return [Integer] duration in milliseconds

  # @note Calculates duration on the fly. Once you reach a large
  #       number of jobs you'll want to calculate this periodically,
  #       or keep a running tally.
  # @return [Integer] total duration in milliseconds.
  def self.total_duration
    sum(:duration)
  end
end
