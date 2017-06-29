module TasksHelper
  def freelancers_options
    s = ''
    User.all.each do |user|
      s << "<option value='#{user.id}' data-img-src='#{gravatar_image_url(user.email, size: 50)}'>#{user.display_name}</option>"
    end
    s.html_safe
  end

  def get_activity_detail(activity)
    case activity.targetable_type
    when 'Task'
      task_activity_detail(activity)
    when 'TaskComment'
      task_comments_activity_detail(activity)
    when 'TeamMembership'
      team_membership_activity_detail(activity)
    end
  end

  def task_activity_detail(activity)
    if activity.created?
      'This task was proposed by'
    elsif activity.edited?
      'This task was edited by'
    elsif activity.incomplete?
      'This task was reviewed and rejected by'
    end
  end

  def task_comments_activity_detail(_activity)
    'This task was commented by'
  end

  def team_membership_activity_detail(activity)
    "#{activity.archived_targetable.team_member.display_name} was removed from this task by" if activity.deleted?
  end
end
