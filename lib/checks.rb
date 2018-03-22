# frozen_string_literal: true

require 'English'

# Check repository
class CheckRepository
  attr_reader :checks

  def initialize(plugin_dir, checks_conf = {})
    @checks = {}
    checks_conf.each do |name, conf|
      @checks[name] = Check.new(
        plugin_dir,
        conf['probe'],
        conf['alarm'],
        conf['options']
      )
    end
  end
end

# Parse and execute check
class Check
  attr_reader :plugin_dir
  attr_reader :args
  attr_reader :comparison_operator
  attr_reader :duration_period
  attr_reader :evaluation_periods
  attr_reader :script
  attr_reader :statistic
  attr_reader :threshold
  attr_reader :treat_missing_data

  def initialize(plugin_dir, probe, alarm, _options = nil)
    @plugin_dir = plugin_dir

    # We parse something like probe: 'inodes /home x y z'
    probe_parsed = probe.match(/^(?<script>[^\s]+)\s*(?<args>.*)$/)
    @script = probe_parsed[:script]
    @args = probe_parsed[:args]

    # We parse something like alarm: 'Average >= 90 2x300s'
    alarm_parsed = alarm.match(
      /^(?<statistic>[^\s]+) (?<operator>[>=<]+) (?<threshold>[0-9\.]+) (?<period>[0-9]+)x(?<duration>[0-9]+)s$/
    )

    @statistic = alarm_parsed[:statistic]
    @comparison_operator = operator(alarm_parsed[:operator])
    @threshold = alarm_parsed[:threshold]
    @evaluation_periods = alarm_parsed[:period]
    @duration_period = alarm_parsed[:duration]
    @treat_missing_data = 'missing'
  end

  def operator(math_operator)
    {
      '<' => 'LessThanThreshold',
      '>' => 'GreaterThanThreshold',
      '<=' => 'LessThanOrEqualToThreshold',
      '>=' => 'GreaterThanOrEqualToThreshold',
    }[math_operator]
  end

  def run
    command = "#{@plugin_dir}/#{@script} #{@args}"
    puts "#{__LINE__}: executing: '#{command}'"
    output = `#{command}`.chomp

    if $CHILD_STATUS == 0
      output.split(' ')
    else
      STDERR.puts "#{__LINE__}: fail executing '#{command}'"
      %w[nil nil]
    end
  end
end
