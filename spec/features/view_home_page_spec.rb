require "rails_helper"

RSpec.feature "View home page", type: :feature do
  scenario "lists all job executions and a summary" do
    JobExecution.create!(provider_job_id: "Job-1", duration: 4000)
    JobExecution.create!(provider_job_id: "Job-2", duration: 2000)
    JobExecution.create!(provider_job_id: "Job-3", duration: 6000)

    visit home_page_path

    within_table 'Job Executions' do
      expect(page).to have_content '12.0s'
      expect(page).to have_content 'Job-1'
    end
  end
end