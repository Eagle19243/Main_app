

user = CreateAdminService.new.call
puts 'CREATED ADMIN USER: ' << user.email

count = CreateAdminService.new.create_additional_admins
puts "#{count} additional admins created"

CreateAdminService.new.create_admin_wallet

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

@Team_member = TeamMembership.create(team_member_id: User.first.id,
               team_id: @project_team.id,
               role: 0)
TaskMember.create(task_id: @task.id,team_membership_id: @Team_member.id  )
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

@Team_member = TeamMembership.create(team_member_id: User.first.id,
               team_id: @project_team.id,
               role: 0)
TaskMember.create(task_id: @task.id,team_membership_id: @Team_member.id  )

puts "#{count} additional admins created"


# title:"This is a Test project", description: "This is a Test project created by Erwin, Thanks for bidding!", user_id: 1, volunteers: 1, state: "progress", request_description: "This is a test project", short_description:"test project"
