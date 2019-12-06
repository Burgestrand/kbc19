class GenericJob < ApplicationJob
  queue_as :default

  # Automatically retry failed jobs after 5 minutes, a maximum of 2 attempts.
  #
  # Once the maximum retries have been reached, put the job on a morgue queue
  # for later inspection.
  retry_on StandardError, wait: 5.minutes, attempts: 2 do |job, error|
    job.retry_job(wait: 0, queue: :morgue, error: error)
  end

  def perform(work)
    if work == "noop"
      # We do nada!
    elsif work == "work"
      # Yay, we simulate something important.
      sleep((rand * 5).floor)
    elsif work == "explode"
      raise "Something went to complete shit."
    else
      raise "We don't know what to do with this work: #{work}"
    end
  end
end