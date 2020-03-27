module TasksHelper
  def task_tr_classes(task)
    [].tap { |classes|
      classes.push(*%w(table-success task-done task-hidden)) if task.done?
      classes.push('task-deadline') if task.deadline?
    }.join(' ')
  end
end
