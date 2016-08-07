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

  def project_funded(project)
    funded = 0
    project.tasks.to_a.each { |task|  budget += task }
    budget
  end

  def aliases_as
    "Silva, haha"
  end

  def project_calculus
    task = Task.last
    '

    <div class="progress-bar">
      <div class="current-progress" style="width: <%= 100 * (task.current_fund/task.budget) %>%"></div>
    </div>
    <span class="left">
      <strong>$<%= task.current_fund.to_i %></strong> funded
    </span>
    <span class="right">
      <strong><%= (100 * (task.current_fund/task.budget)).to_i %></strong>% of goal
    </span>
    <div class="do-buttons">
     <%=link_to "Do this task", new_do_request_path(task_id: task.id,free: false), class:"button small radius blue" %>&nbsp;<%=link_to "Do for free", new_do_request_path(task_id: task.id,free: true), class:"button small radius blue" %>&nbsp;<%=link_to "Fund this task", new_donation_path(task_id: task.id), class:"button small radius green" %>
     </div>
    '
  end
end
