# using Taskwarrior as back-end.
class Task
  include ActiveModel::Model

  attr_accessor :id, :description, :project, :due, :priority, :tags
  attr_reader   :status, :entry, :modified, :end_date, :urgency

  ########################
  # Class methods
  ########################
  def self.all
    TaskwarriorCommand.load.sort_by { |task|
      [
        # 1. undone is upper, done is lower
        task.done? ? 1 : 0,

        # 2. due date asc, nil is lower
        task.due || Date.new(2999, 12, 31),

        # 3. High, Middle, Low, nil order
        ['H', 'M', 'L', nil].index(task.priority)
      ]
    }
  end

  def self.find(id)
    self.all.detect { |task| task.id == id }
  end

  def self.projects
    self.all.map(&:project).uniq
  end

  ########################
  # Instance methods
  ########################
  def initialize(task_hash = {})
    @relative_id = task_hash['relative_id']
    @id          = task_hash['id']
    @description = task_hash['description']
    @project     = task_hash['project']
    @due         = task_hash['due']
    @priority    = task_hash['priority']
    @status      = task_hash['status']
    @entry       = task_hash['entry']
    @modified    = task_hash['modify']
    @end_date    = task_hash['end']
    @urgency     = task_hash['urgency']
    @tags        = task_hash['tags']
  end

  # ActiveRecord-duck
  def save
    persisted? ? update : create
  end

  # ActiveRecord-duck
  def create
    TaskwarriorCommand.add(self)
  end

  # ActiveRecord-duck
  def update(task_hash)
    @description = task_hash['description']
    @project     = task_hash['project']
    @due         = task_hash['due']
    @priority    = task_hash['priority']
    @tags        = task_hash['tags']

    TaskwarriorCommand.modify(self)
  end

  # ActiveRecord-duck
  def destroy
    TaskwarriorCommand.delete(self)
  end

  def done!
    TaskwarriorCommand.done(self)
  end

  def done?
    @status == 'completed'
  end

  def deadline?
    @due.present? && @due <= Date.today
  end

  def persisted?
    @id.present?
  end
end
