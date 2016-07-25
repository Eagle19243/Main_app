module ActivitiesHelper
  def activity_title(activity)
    activity.targetable_type.underscore.split('_').map!(&:upcase).join(' ')
  end

  def activity_text(activity)
    send("#{activity.targetable_type.underscore}_notifier", activity)
  end

  def default_notifier(activity)
    object = activity.targetable
    content_tag(:div, nil, class: 'pro-text') do
      [
        (link_to object.title, object),
        " was successful #{activity.action}"
      ].join.html_safe
    end
  end

  alias_method :project_notifier, :default_notifier
  alias_method :task_notifier, :default_notifier

  def project_comment_notifier(activity)
    comment = activity.targetable
    content_tag(:div, nil, class: 'pro-text') do
      [
        (link_to 'The comment', [comment.project, comment]),
        " was successful #{activity.action}",
        " to this project ",
        (link_to comment.project.title, comment.project),
      ].join.html_safe
    end
  end
end
