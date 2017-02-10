require 'rails_helper'

feature "Create a Task", js: true, vcr: { cassette_name: 'bitgo' } do
  before do
    users = FactoryGirl.create_list(:user, 2, confirmed_at: Time.now)
    @user = users.first
    @regular_user = users.last

    @project = FactoryGirl.create(:project, user: @user)
    @task = FactoryGirl.create(:task, project: @project)
    @project_team = @project.create_team(name: "Team#{@project.id}")
    @team_membership = TeamMembership.create(team_member_id: @user.id, team_id: @project_team.id, role:1)
  end

  context "As project leader" do
    before do
      login_as(@user, :scope => :user, :run_callbacks => false)
    end

    context "When you navigate the project page" do
      before do
        visit project_path(@project)
      end

      context "When you click 'Task' button" do
        before do
          find("ul.m-tabs li a[data-tab='Tasks']").trigger("click")
          wait_for_ajax

          @funding_section = all(".trello-column .pr-card")[0]
        end

        context "When you click the task" do
          before do
            @funding_section.click
            sleep 2

            @task_modal = find("#myModal")
          end

          scenario "Then the task modal appeared" do
            expect(@task_modal).to be_visible
          end

          scenario "Then the comments section exists in the modal" do
            expect(@task_modal).to have_selector("#Task-comments")
          end

          context "When you put some text into comments field and attach a file" do
            before do
              @comment = "new comment"
              @attach = "photo.png"
              @comments_section = find("#Task-comments")
              @form = find("#comment-form")

              @form.fill_in "task_comment[body]", with: @comment

              @form.attach_file 'task_comment[attachment]', Rails.root + "spec/fixtures/#{@attach}"

              @form.click_button "Send"
              sleep 2
            end

            scenario "Then the text appeared in the comments section" do
              expect(@comments_section).to have_content @comment
            end

            scenario "Then the attached file appeared in the comments section" do
              expect(@comments_section).to have_xpath("//img[contains(@src, @attach)]")
            end

            context "When you reload the page and reopen the task modal" do
              before do
                visit project_path(@project)

                find("ul.m-tabs li a[data-tab='Tasks']").trigger("click")
                wait_for_ajax

                funding_section = all(".trello-column .pr-card")[0]

                funding_section.click
                sleep 2

                @comments = find("#Task-comments")
              end

              scenario "Then the comment exists in the comments section" do
                expect(@comments).to have_content @comment
              end

              scenario "Then the attach exists in the comments section" do
                expect(@comments).to have_xpath("//img[contains(@src, @attach)]")
              end
            end
          end
        end
      end
    end
  end

  context "As a non team member" do
    before do
      login_as(@regular_user, :scope => :user, :run_callbacks => false)
    end

    context "When you navigate the project page" do
      before do
        visit project_path(@project)
      end

      context "When you click 'Task' button" do
        before do
          find("ul.m-tabs li a[data-tab='Tasks']").trigger("click")
          wait_for_ajax

          @pending_section = all(".trello-column .pr-card")[0]
        end

        context "When you click the task" do
          before do
            @pending_section.click
            sleep 2

            @task_modal = find("#myModal")
          end

          scenario "Then the task modal appeared" do
            expect(@task_modal).to be_visible
          end

          scenario "Then the comments history exists in the modal" do
            expect(@task_modal).to have_selector("#Task-comments")
          end

          scenario "Then the comments form does not exist in the modal" do
            expect(@task_modal).not_to have_selector("#comment-form")
          end
        end
      end
    end
  end

  context "As anonymous" do
    context "When you navigate the project page" do
      before do
        visit project_path(@project)
      end

      context "When you click 'Task' button" do
        before do
          find("ul.m-tabs li a[data-tab='Tasks']").trigger("click")
          wait_for_ajax

          @pending_section = all(".trello-column")[1]
        end

        context "When you click the task" do
          before do
            @pending_section.click
            sleep 2

            @task_modal = find("#myModal")
          end

          scenario "Then the task modal appeared" do
            expect(@task_modal).to be_visible
          end

          scenario "Then the comments form does not exist in the modal" do
            expect(@task_modal).not_to have_selector("#comment-form")
          end
        end
      end
    end
  end
end