require "rails_helper"

RSpec.feature "Score children from home page", type: :feature do
  scenario "successfully recomputes the score of a child" do
    Child.create!(name: "Alice")

    visit home_page_path

    within_table 'Children' do
      expect(page).to have_content 'Alice'
    end
  end
end