# using Taskwarrior as back-end.
class Task
  include ActiveModel::Model

  attr_accessor :id, :description, :project, :due, :priority, :tags
  attr_reader   :status, :entry, :modified, :end_date, :urgency

  ########################
  # Class methods
  ########################
  def self.all
    Parser.parse.sort_by { |task|
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
    command_and_args = %W(
      task add
      due:"#{@due&.strftime('%Y-%m-%d')}"
      project:"#{@project}"
      priority:"#{@priority}"
      tags:"#{@tags}"
      "#{@description}"
    )

    puts command_and_args

    system(*command_and_args)
  end

  # ActiveRecord-duck
  def update(task_hash)
    @relative_id ||= task_hash['relative_id']
    @id          ||= task_hash['id']
    @description ||= task_hash['description']
    @project     ||= task_hash['project']
    @due         ||= task_hash['due']
    @priority    ||= task_hash['priority']
    @status      ||= task_hash['status']
    @entry       ||= task_hash['entry']
    @modified    ||= task_hash['modify']
    @end_date    ||= task_hash['end']
    @urgency     ||= task_hash['urgency']
    @tags        ||= task_hash['tags']

    command_and_args = %W(
      task #{@id} modify
      due:"#{@due&.strftime('%Y-%m-%d')}"
      project:"#{@project}"
      priority:"#{@priority}"
      tags:"#{@tags}"
      "#{@description}"
    )
    puts command_and_args

    system(*command_and_args)
  end

  # ActiveRecord-duck
  def destroy
    `yes | task #{@id} delete`
  end

  def done!
    `task #{@relative_id} done` if @relative_id != '0'
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

  ########################
  # Taskwarrior parser
  ########################
  # Get tasks as json by `task export` command.
  # And make Task objects.
  module Parser
    module_function

    TIME_COLUMNS = %w(entry modified end)

    UNIXTIME2JST = ->(unix_time) { unix_time && ( Time.strptime(unix_time, '%Y%m%dT%H%M%SZ') + 9.hours ) }

    def parse
      JSON.parse(`task export`).
        reject { |task_hash|
          task_hash['status'] == 'deleted'
        }.

        map { |task_hash|
          #-------------------------
          # make adjusted_params
          #-------------------------
          {
            # **** annotation ****
            # Taskwarrior's id is relative, and uuid is absolutely.
            # So, swap naming id and uuid.
            #   Taskwarrior id   => Task.relative_id
            #   Taskwarrior uuid => Task.id
            'relative_id' => task_hash['id'],
            'id'          => task_hash['uuid'],

            # change tags type Array[String]
            #   to Comma-separated String for Taskwarrior command and view
            'tags'        => task_hash['tags']&.join(','),

            # change due type UNIX Time String to Date
            #   and adjust Time-Zone[JST]
            'due'         => UNIXTIME2JST[ task_hash['due'] ]&.to_date
          }.merge(
            # change TIME_COLUMNS type UNIX Time String to Time
            #   and adjust Time-Zone[JST]
            task_hash.slice(*TIME_COLUMNS).reduce({}) { |acc, (key, val)|
              acc.merge(key => UNIXTIME2JST[val])
            }
          ).

          then { |adjusted_params|
            ::Task.new(task_hash.merge(adjusted_params))
          }
        }
    end
  end
end
