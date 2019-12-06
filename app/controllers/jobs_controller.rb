class JobsController < ApplicationController
  def no_op
    job = GenericJob.perform_later "no-op"
    flash[:notice] = "No-op job ##{job.provider_job_id} created."

    redirect_back(fallback_location: root_url, status: :see_other)
  end

  def exploding
    job = GenericJob.perform_later "exploding"
    flash[:notice] = "Exploding job ##{job.provider_job_id} created."

    redirect_back(fallback_location: root_url, status: :see_other)
  end
end