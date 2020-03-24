class Task
  include ActiveModel::Model

  attr_accessor :uuid, :description, :project, :due, :priority
  attr_reader   :status, :entry, :modified, :end_date, :urgency, :errors

  def self.all
    Parser.parse
  end

  def initialize(task_hash = {})
    @uuid        = task_hash['uuid']
    @description = task_hash['description']
    @project     = task_hash['project']
    @due         = task_hash['due']
    @priority    = task_hash['priority']
    @status      = task_hash['status']
    @entry       = task_hash['entry']
    @modified    = task_hash['modify']
    @end_date    = task_hash['end']
    @urgency     = task_hash['urgency']
    @errors      = []
  end

  def self.find(uuid)
    Task.all.detect { |task| task.uuid ==  uuid }
  end

  def save
    persisted? ? update : create
  end

  def create
    `task add due:#{@due&.strftime('%Y-%m-%d')} project:#{@project} #{@description}`
  end

  def update
    `task #{@uuid} modify due:#{@due&.strftime('%Y-%m-%d')} project:#{@project} #{@description}`
  end

  def destroy
    `yes | task #{@uuid} delete`
  end

  def done!
    `task #{@uuid} done`
  end

  def done?
    @status == 'completed'
  end

  def deadline?
    @due.present? && @due >= Date.today
  end

  def to_model
    self
  end

  def model_name
    Name.new
  end

  def persisted?
    @uuid.present?
  end

  # duck typing ActiveModel::Name
  class Name
    attr_reader :name, :klass, :singular, :plural, :human, :collection, :param_key, :i18n_key, :route_key, :singular_route_key
    def initialize
      @name               = 'Task'
      @klass              = Task
      @singular           = 'task'
      @plural             = 'tasks'
      @human              = 'Task'
      @collection         = 'tasks'
      @param_key          = 'task'
      @i18n_key           = :task
      @route_key          = 'tasks'
      @singular_route_key = 'task'
    end
  end

  module Parser
    module_function

    DATE_COLUMNS = %w(due entry modified end)

    def parse
      JSON.parse(`task export`).map do |task_hash|
        date_converted_hash = task_hash.slice(*DATE_COLUMNS).reduce({}) { |acc, (key, val)|
          # acc.merge(key => Time.iso8601(val))
          acc.merge(key => Time.strptime(val, '%Y%m%dT%H%M%SZ') + 9.hours)
        }

        ::Task.new( task_hash.merge(date_converted_hash) )
      end
    end
  end
end
