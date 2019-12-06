class StaticPageController < ApplicationController
  def home
    render :home, locals: {
      job_executions: JobExecution.all
    }
  end
end
