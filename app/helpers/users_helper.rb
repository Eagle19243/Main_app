module UsersHelper
  def user_short_info(user)
    result = @user.location.to_s
    result += ' - ' if result.present?
    result += "Member since #{@user.created_at.strftime('%B %Y')}"
  end

  def project_budget(project)
    budget = 0
    project.tasks.to_a.each { |task|  budget += task }
    budget
  end

  def aliases_as
    "Silva, haha"
  end
end
