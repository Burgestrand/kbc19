require "rails_helper"

RSpec.feature "View home page", type: :feature do
  scenario "lists all job executions and a summary" do
    JobExecution.create!(provider_job_id: "Job-1", duration: 4000)
    JobExecution.create!(provider_job_id: "Job-2", duration: 2000)
    JobExecution.create!(provider_job_id: "Job-3", duration: 6000)

    visit home_page_path

    expect(page).to have_content 'Total number of jobs: 3'
    expect(page).to have_content 'Total duration of jobs: 12.0s'
  end
end