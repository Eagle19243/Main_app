module UsersHelper
  def user_short_info(user)
    result = @user.location.to_s
    result += ' - ' if result.present?
    result += "Member since #{@user.created_at.strftime('%B %Y')}"
  end
end