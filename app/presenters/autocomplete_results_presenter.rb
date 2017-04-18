class AutocompleteResultsPresenter
  attr_reader :projects, :tasks

  def initialize(projects, tasks)
    @projects = projects
    @tasks = tasks
  end

  def results
    objects = []
    objects << present_projects
    objects << present_tasks
    objects.flatten
  end

  def to_json
    JSON.generate(results)
  end

  private
  def present_projects
    projects.map { |p| AutocompleteProjectPresenter.new(p).result }
  end

  def present_tasks
    tasks.map { |t| AutocompleteTaskPresenter.new(t).result }
  end
end
