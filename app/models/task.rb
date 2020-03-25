class Task
  include ActiveModel::Model

  attr_accessor :id, :description, :project, :due, :priority, :tags
  attr_reader   :status, :entry, :modified, :end_date, :urgency

  def self.all
    Parser.parse
  end

  def self.projects
    self.all.map(&:project).uniq
  end

  def initialize(task_hash = {})
    @abs_id      = task_hash['abs_id']
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

  def self.find(id)
    Task.all.detect { |task| task.id ==  id }
  end

  def save
    persisted? ? update : create
  end

  def create
    command = <<~COMMAND
      task add                            \
        due:#{@due&.strftime('%Y-%m-%d')} \
        project:#{@project}               \
        priority:#{@priority}             \
        tags:"#{@tags}"                   \
        #{@description}
    COMMAND

    Rails.logger.debug command
    system command
  end

  def update(task_hash)
    @due, @project, @description, @priority, @tags =
      task_hash.values_at('due', 'project', 'description', 'priority', 'tags')

    command = <<~COMMAND
      task #{@id} modify                  \
        due:#{@due&.strftime('%Y-%m-%d')} \
        project:#{@project}               \
        priority:#{@priority}             \
        tags:"#{@tags}"                   \
        #{@description}
    COMMAND

    Rails.logger.debug command
    system command
  end

  def destroy
    `yes | task #{@id} delete`
  end

  def done!
    `task #{@abs_id} done` if @abs_id != '0'
  end

  def done?
    @status == 'completed'
  end

  def deadline?
    @due.present? && @due >= Date.today
  end

  def persisted?
    @id.present?
  end

  module Parser
    module_function

    TIME_COLUMNS = %w(entry modified end)

    def parse
      JSON.parse(`task export`).map { |task_hash|
        # abs_id is task_warrior id
        task_hash['abs_id'] = task_hash['id']
        task_hash['id']     = task_hash['uuid']

        task_hash['tags']   = task_hash['tags']&.join(',')

        if task_hash['due']
          task_hash['due'] = (Time.strptime(task_hash['due'], '%Y%m%dT%H%M%SZ') + 9.hours).to_date
        end

        time_converted_hash = task_hash.slice(*TIME_COLUMNS).reduce({}) { |acc, (key, val)|
          # acc.merge(key => Time.iso8601(val))
          acc.merge(key => Time.strptime(val, '%Y%m%dT%H%M%SZ') + 9.hours)
        }

        ::Task.new( task_hash.merge(time_converted_hash) )
      }.
      # reject deleted tasks
      reject { |task|
        task.status == 'deleted'
      }
    end
  end
end
