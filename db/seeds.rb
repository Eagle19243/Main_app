# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
User.create!(name:  "Test User",
             email: "test@test.com",
             password:              "test1234",
             password_confirmation: "test1234")
user = CreateAdminService.new.call
puts 'CREATED ADMIN USER: ' << user.email
count = CreateAdminService.new.create_additional_admins
puts "#{count} additional admins created"