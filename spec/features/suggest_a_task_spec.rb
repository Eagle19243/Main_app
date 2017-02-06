require 'rails_helper'

feature "Suggest a Task", js: true, vcr: { cassette_name: 'bitgo' } do
  before do
    users = FactoryGirl.create_list(:user, 2, confirmed_at: Time.now)
    @user = users.first
    @regular_user = users.last
    @project = FactoryGirl.create(:project, user: @user)
  end

  context "As Regular User" do
    before do
      login_as(@regular_user, :scope => :user, :run_callbacks => false)
    end

    context "When you visit the project page" do
      before do
        visit project_path(@project)
        @task_area = find("#Tasks")
      end

      scenario "Then you can see 'Task' button" do
        expect(find("ul.m-tabs")).to have_content "Tasks"
      end

      context "When you click 'Task' button" do
        before do
          find("ul.m-tabs li a[data-tab='Tasks']").trigger("click")
          wait_for_ajax
        end

        scenario "Then the 'Tasks' screen appeared" do
          expect(@task_area).to be_visible
        end

        scenario "Then the 'Suggest a task' link is the area" do
          expect(@task_area).to have_selector("#suggest-new-task")          
        end

        context "When you click 'Suggest a task' link" do
          before do
            @task_area.find("#suggest-new-task").trigger("click")
            wait_for_ajax
            sleep 2

            @modal = find("#newTaskModal")
          end

          scenario "Then a modal appeared" do
            expect(@modal).to be_visible
          end

          context "When you fill all the fields and click 'Create task' button" do
            before do
              @task = FactoryGirl.build(:task, project: @project)

              @modal.fill_in 'task[title]', with: @task.title
              @modal.fill_in 'task[budget]', with: @task.budget
              @modal.fill_in 'task[condition_of_execution]', with: @task.condition_of_execution
              @modal.fill_in 'task[proof_of_execution]', with: @task.proof_of_execution
              @modal.fill_in 'task[deadline]', with: @task.deadline

              @modal.click_button "Create Task"
              sleep 2
            end

            scenario "Then new task has been created" do
              expect(@project.tasks.count).not_to be_zero
            end

            context "When you navigate the project page" do
              before do
                visit project_path(@project)
              end

              context "When you click 'Task' button" do
                before do
                  find("ul.m-tabs li a[data-tab='Tasks']").trigger("click")
                  wait_for_ajax

                  @pending_section = first(".trello-column")
                end

                scenario "Then the task has been appeared in the 'Pending approval' section" do
                  expect(@pending_section.find(".card-title")).to have_content @task.title
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

                  scenario "Then all the information of the task is present in the modal" do
                    expect(@task_modal).to have_content @task.title
                    expect(@task_modal).to have_content @task.condition_of_execution
                    expect(@task_modal).to have_content @task.proof_of_execution
                  end

                  scenario "Then 'Delete task' button exists in the modal" do
                    expect(@task_modal).to have_selector("button.approve-link")
                  end

                  scenario "Then 'Approve' button does not exist in the modal" do
                    expect(@task_modal).not_to have_selector("#approveTaskPopover")
                  end

                  scenario "Then 'Activity' section exists in the modal" do
                    expect(@task_modal).to have_selector("#task-activity")
                  end

                  scenario "Then 'Activity' section contains the activity of the current user" do
                    expect(find("#task-activity")).to have_content "This task was proposed by #{@regular_user.name}"
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  context "As project leader" do
    before do
      login_as(@user, :scope => :user, :run_callbacks => false)
    end

    context "When you visit the project page" do
      before do
        visit project_path(@project)
        @task_area = find("#Tasks")
      end

      scenario "Then you can see 'Task' button" do
        expect(find("ul.m-tabs")).to have_content "Tasks"
      end

      context "When you click 'Task' button" do
        before do
          find("ul.m-tabs li a[data-tab='Tasks']").trigger("click")
          wait_for_ajax
        end

        scenario "Then the 'Tasks' screen appeared" do
          expect(@task_area).to be_visible
        end

        scenario "Then the 'Suggest a task' link is the area" do
          expect(@task_area).to have_selector("#suggest-new-task")          
        end

        context "When you click 'Suggest a task' link" do
          before do
            @task_area.find("#suggest-new-task").trigger("click")
            wait_for_ajax
            sleep 2

            @modal = find("#newTaskModal")
          end

          scenario "Then a modal appeared" do
            expect(@modal).to be_visible
          end

          context "When you fill all the fields and click 'Create task' button" do
            before do
              @task = FactoryGirl.build(:task, project: @project)

              @modal.fill_in 'task[title]', with: @task.title
              @modal.fill_in 'task[budget]', with: @task.budget
              @modal.fill_in 'task[condition_of_execution]', with: @task.condition_of_execution
              @modal.fill_in 'task[proof_of_execution]', with: @task.proof_of_execution
              @modal.fill_in 'task[deadline]', with: @task.deadline

              @modal.click_button "Create Task"
              sleep 2
            end

            scenario "Then new task has been created" do
              expect(@project.tasks.count).not_to be_zero
            end

            context "When you navigate the project page" do
              before do
                visit project_path(@project)
              end

              context "When you click 'Task' button" do
                before do
                  find("ul.m-tabs li a[data-tab='Tasks']").trigger("click")
                  wait_for_ajax

                  @pending_section = first(".trello-column")
                end

                scenario "Then the task has been appeared in the 'Pending approval' section" do
                  expect(@pending_section.find(".card-title")).to have_content @task.title
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

                  scenario "Then all the information of the task is present in the modal" do
                    expect(@task_modal).to have_content @task.title
                    expect(@task_modal).to have_content @task.condition_of_execution
                    expect(@task_modal).to have_content @task.proof_of_execution
                  end

                  scenario "Then 'Delete task' button exists in the modal" do
                    expect(@task_modal).to have_selector("button.approve-link")
                  end

                  scenario "Then 'Approve' button exists in the modal" do
                    expect(@task_modal).to have_selector("#approveTaskPopover")
                  end

                  scenario "Then 'Activity' section exists in the modal" do
                    expect(@task_modal).to have_selector("#task-activity")
                  end

                  scenario "Then 'Activity' section contains the activity of the current user" do
                    expect(find("#task-activity")).to have_content "This task was proposed by #{@user.name}"
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end