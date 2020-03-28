module TaskwarriorCommand
  module_function

  def load
    `task status:pending or status:waiting or status:completed export`.then do |json|
      Parser.parse(json)
    end
  end

  def add(task)
    system(
      'task', 'add',
      *convert_add_or_modify_args(task)
    )
  end

  def modify(task)
    puts "task #{task.id} modify #{convert_add_or_modify_args(task).join(' ')}"
    system(
      'task', task.id, 'modify',
      *convert_add_or_modify_args(task)
    )
  end

  def convert_add_or_modify_args(task)
    %W(
      due:"#{task.due&.strftime('%Y-%m-%d')}"
      project:"#{task.project}"
      priority:"#{task.priority}"
      tags:"#{task.tags}"
      "#{task.description}"
    )
  end

  def done(task)
    system("task #{task.relative_id} done") if task.relative_id != '0'
  end

  def delete(task)
    system("yes | task #{task.id} delete")
  end

  ########################
  # Taskwarrior parser
  ########################
  # Get tasks as json by `task export` command.
  # And make Task objects.
  module Parser
    UNIXTIME2JST = lambda { |unix_time|
      unix_time &&
        ( Time.strptime(unix_time, '%Y%m%dT%H%M%SZ') + 9.hours )
    }

    module_function

    def parse(json_tasks)
      JSON.parse(json_tasks).map { |task_hash|
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
          'due'         => UNIXTIME2JST[ task_hash['due'] ]&.to_date,

          # change due type UNIX Time String to Time
          #   and adjust Time-Zone[JST]
          'entry'       => UNIXTIME2JST[ task_hash['entry']  ],
          'modify'      => UNIXTIME2JST[ task_hash['modify'] ],
          'end'         => UNIXTIME2JST[ task_hash['end']    ]
        }.

        then { |adjusted_params|
          Task.new(task_hash.merge(adjusted_params))
        }
      }
    end
  end
end
