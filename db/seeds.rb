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

puts "Created project 1"
puts @project.id

@project_team = Team.create(name: "Team #{@project.id}", project: @project)

puts "Created team"
puts @project_team.id

@task = Task.create(title: "Example Task",
            user_id: User.first.id,
            project_id: @project.id,
            state: "pending",
            budget: 100,
            deadline: Date.new)

puts "Created task"

TeamMembership.create(team_member_id: User.first.id,
               team_id: @project_team.id,
               state: 'admin',
               task_id: @task.id)

puts "Created membership"

@project = Project.create(title: "Test project 2",
               user_id: User.first.id,
               state: "pending",
               short_description: "This is project 1")

puts "Created project 2"

@project_team = Team.create(name: "Team #{@project.id}", project: @project)

puts "Created team"

@task = Task.create(title: "Example Task 2",
            user_id: User.first.id,
            project_id: @project.id,
            state: "pending",
            budget: 100,
            deadline: Date.new)

puts "Created task"

TeamMembership.create(team_member_id: User.first.id,
               team_id: @project_team.id,
               state: 'admin',
               task_id: @task.id)
puts "#{count} additional admins created"


# title:"This is a Test project", description: "This is a Test project created by Erwin, Thanks for bidding!", user_id: 1, volunteers: 1, state: "progress", request_description: "This is a test project", short_description:"test project"
