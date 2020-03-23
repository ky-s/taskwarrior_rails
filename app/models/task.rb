class Task
  def self.all
    Parser.parse("#{ENV['HOME']}")
  end

  def initialize(task_hash)
    @uuid        = task_hash[:uuid]
    @description = task_hash[:description]
    @project     = task_hash[:project]
    @status      = task_hash[:status]
    @due         = task_hash[:due]
    @entry       = task_hash[:entry]
    @modified    = task_hash[:modify]
  end

  module Parser
    module_function

    DATA_FILE_ABSOLUTE_PATHS = %w(
      /.task/pending.data
      /.task/completed.data
      /.task/backlog.data
    )

    DATE_COLUMNS = [:due, :entry, :modified]


    def parse(home_path)
      # read each task data
      task_lines = DATA_FILE_ABSOLUTE_PATHS.reduce([]) { |lines, file_path|
        lines + File.readlines(home_path + file_path, chomp: true)
      }

      task_lines.map do |line|
        # convert ruby hash syntax
        line[0]  = '{'; line[-1] = '}'
        task_hash = eval(line.gsub('" ', '",'))

        # convert to Date from UNIX time
        date_converted_hash = task_hash.slice(*DATE_COLUMNS).reduce({}) { |acc, key, val|
          acc.merge(key => Time.at(val.to_i))
        }

        ::Task.new( task_hash.merge(date_converted_hash) )
      end
    end
  end
end
