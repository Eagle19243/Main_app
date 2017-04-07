require 'rails_helper'

feature "Project Page", js: true do
  before do
    @project_leader = FactoryGirl.create(:user, confirmed_at: Time.now)
    @usual_user = FactoryGirl.create(:user, confirmed_at: Time.now)
    @project = FactoryGirl.create(:project, user: @project_leader)
  end

  context "When you visit your project page as project leader" do
    before do
      login_as(@project_leader, :scope => :user, :run_callbacks => false)
      visit project_path(@project)
    end

    scenario "Then you can see the project image" do
      expect(page).to have_xpath("//img[contains(@src, @project.picture.file.filename)]")
    end

    scenario "Then you can see the project manager's image" do
      expect(page.find(".b-project-info__user")).to have_xpath("//img[contains(@src, @project.user.picture.file.filename)]")
    end

    scenario "Then you can see the project title" do
      expect(page.find(".b-project-info__title")).to have_content @project.title
    end

    scenario "Then you can see the project activities" do
      expect(page).to have_selector(".task-progress-wrapper")
    end

    scenario "Then you can see the project plan tab" do
      expect(page.find(".tabs-menu")).to have_selector("#tab-plan")
    end

    scenario "Then you can see the project tasks tab" do
      expect(page.find(".tabs-menu")).to have_content("Tasks")
    end

    scenario "Then you can see the project revisions tab" do
      expect(page).to have_selector("#editSource")
    end

    scenario "Then you can see the project team tab" do
      expect(page.find(".tabs-menu")).to have_content("Team")
    end

    scenario "Then you can see the project team tab" do
      expect(page.find(".tabs-menu")).to have_content("Requests")
    end
  end

  context "When you visit project page as usual logged in user" do
    before do
      login_as(@usual_user, :scope => :user, :run_callbacks => false)
      visit project_path(@project)
    end

    scenario "Then you cannot see the project team tab" do
      expect(page.find(".tabs-menu")).not_to have_content("Requests")
    end
  end
end
