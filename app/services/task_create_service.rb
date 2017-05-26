class TaskCreateService
  attr_reader :task, :user, :project

  def initialize(task_params, user, project)
    raise ArgumentError, "Incorrect argument type" unless task_params.is_a?(Hash)
    raise ArgumentError, "Incorrect argument type" unless user.is_a?(User)
    raise ArgumentError, "Incorrect argument type" unless project.is_a?(Project)

    @task = project.tasks.new(task_params.merge(user_id: user.id))
    @task.target_number_of_participants = 1
    @user = user
    @project = project
  end

  def create_task
    return false unless task.valid?
    return false unless task_budget_is_greater_than_or_equal_to_a_minimum?

    ActiveRecord::Base.transaction do
      if task.save
        user.create_activity(task, 'created')
        # Suggesting a task adds user to teammates
        TeamService.add_team_member(task.project.team, user, "teammate")
        true
      else
        false
      end
    end
  end

  private
  def task_budget_is_greater_than_or_equal_to_a_minimum?
    if task.satoshi_budget >= Task::MINIMUM_FUND_BUDGET
      true
    else
      task.errors.add(:budget, 'must be higher than a minimum budget')
      false
    end
  end
end
