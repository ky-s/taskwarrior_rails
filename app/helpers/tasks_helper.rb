module TasksHelper
  def task_tr(task)
    classes = task.done? ? 'table-success task-done' : ''
    classes = classes + ' task-deadline' if task.deadline?

    content_tag :tr, id: "task-#{task.id}", class: classes do
      yield
    end
  end
end
