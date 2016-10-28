# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
# User.create!(name:  "Test User",
#              email: "test@test.com",
#              password:              "test1234",
#              password_confirmation: "test1234")

user = CreateAdminService.new.call
puts 'CREATED ADMIN USER: ' << user.email

count = CreateAdminService.new.create_additional_admins
puts "#{count} additional admins created"

@project = Project.create(title: "Test project",
               user_id: User.first.id,
               state: "pending",
               short_description: "This is project 1")

@project_team = Team.create(name: "Team #{@project.id}", project: @project)

@task = Task.create(title: "Example Task",
            user_id: User.first.id,
            project_id: Project.where(title: "Test project").first.id,
            state: "pending",
            budget: 100,
            deadline: Date.new)

TeamMembership.create(team_member_id: User.first.id,
               team_id: @project_team.id,
               state: 'admin',
               task_id: @task.id)

@project = Project.create(title: "Test project 2",
               user_id: User.first.id,
               state: "pending",
               short_description: "This is project 1")

@project_team = Team.create(name: "Team #{@project.id}", project: @project)

@task = Task.create(title: "Example Task 2",
            user_id: User.first.id,
            project_id: Project.where(title: "Test project 2").first.id,
            state: "pending",
            budget: 100,
            deadline: Date.new)

TeamMembership.create(team_member_id: User.first.id,
               team_id: @project_team.id,
               state: 'admin',
               task_id: @task.id)
puts "#{count} additional admins created"
