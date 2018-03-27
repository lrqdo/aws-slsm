# frozen_string_literal: true

require 'checks'
require 'aws-sdk-cloudwatch'
require 'net/http'
require 'socket'

# Main class for execution and communication with cloudwatch
class Monitoring
  attr_reader :cloudwatch
  attr_reader :namespace
  attr_reader :action
  attr_reader :server_name
  attr_reader :instance_id
  attr_reader :var_dir
  attr_reader :checks

  def initialize(opts = {})
    @server_name = _get_unique_server_name
    @namespace = opts[:namespace]
    @action = opts[:action]
    @var_dir = opts[:var_dir]
    raise "Dir #{@var_dir} does not exist !" unless Dir.exist?(@var_dir)
    @checks = CheckRepository.new(opts[:plugin_dir], opts[:checks]).checks
    @cloudwatch = _get_cloudwatch_client(
      opts[:aws_key],
      opts[:aws_secret],
      opts[:aws_region]
    )
  end

  def _get_unique_server_name
    @instance_id = _get_instance_id
    hostname = Socket.gethostbyname(Socket.gethostname).first

    # If the hostname is an IP address
    server_name = \
      if /ip-.*-.*-.*-.*\./ =~ hostname
        metadata = _get_iam_metadata
        if metadata.key?['InstanceProfileArn']
          # Capture profile name from "arn:aws:iam::xxxx:instance-profile/profile_name"
          instance_profile = metadata['InstanceProfileArn'].match(
            %r{^arn:aws:iam:.*:instance-profile/(?<name>.*)$}
          )['name']
          # be sure the name is unique
          "#{instance_profile}_#{@instance_id}"
        else
          @instance_id
        end
      else
        hostname
      end
    server_name
  end

  def _get_iam_metadata
    iam_metadata = Net::HTTP.get('169.254.169.254', '/latest/meta-data/iam/info')
    JSON.parse(iam_metadata)
  rescue Errno::ENETUNREACH, Errno::ECONNREFUSED, SocketError
    sleep(1)
    retry
  end

  def _get_cloudwatch_client(key, secret, region)
    if key.nil? || key == '-'
      Aws::CloudWatch::Client.new(region: region)
    else
      Aws::CloudWatch::Client.new(
        access_key_id: key,
        secret_access_key: secret,
        region: region
      )
    end
  end

  def _get_instance_id
    Net::HTTP.get('169.254.169.254', '/latest/meta-data/instance-id')
  rescue Errno::EHOSTUNREACH
    Socket.gethostbyname(Socket.gethostname).first
  rescue Errno::ENETUNREACH, Errno::ECONNREFUSED, SocketError
    sleep(1)
    retry
  end

  def create
    @checks.each do |name, check|
      alarm_name = "#{@namespace}-#{@server_name}_#{name}"
      puts "#{__LINE__}: creating alarm #{alarm_name}"

      _, unit = check.run
      @cloudwatch.put_metric_alarm(
        namespace: @namespace,
        metric_name: name,
        alarm_name: alarm_name,
        unit: unit,
        alarm_description: "#{name} (#{check.script} #{check.args}} problem on #{@server_name}",
        actions_enabled: true,
        alarm_actions: [@action],
        ok_actions: [@action],
        insufficient_data_actions: [@action],
        statistic: check.statistic,
        period: check.duration_period,
        dimensions: [
          {
            name: 'servers',
            value: @instance_id,
          },
        ],
        evaluation_periods: check.evaluation_periods,
        threshold: check.threshold,
        comparison_operator: check.comparison_operator,
        treat_missing_data: check.treat_missing_data
      )
    end
  rescue Aws::CloudWatch::Errors::Throttling
    puts 'We have been throttled, sleeping...'
    sleep 2
    retry
  end

  def run
    create unless File.exist?("#{@var_run}/alarm_created")
    @checks.each do |name, check|
      puts "#{__LINE__}: running probe #{name}"
      value, unit = check.run
      puts "#{__LINE__}: put #{name} | value: #{value} | unit: #{unit}"
      @cloudwatch.put_metric_data(
        namespace: @namespace,
        metric_data: [
          metric_name: name,
          dimensions: [
            {
              name: 'servers',
              value: @instance_id,
            },
          ],
          timestamp: Time.now,
          value: value.to_f,
          unit: unit,
        ]
      )
    end
  end

  def delete
    alarms_to_delete = []
    @checks.each do |name, _|
      alarm_name = "#{@namespace}-#{@server_name}_#{name}"
      alarms_to_delete << alarm_name
    end
    puts "#{__LINE__}: removing alarms #{alarms_to_delete}"
    @cloudwatch.delete_alarms(
      alarm_names: alarms_to_delete
    )
  rescue Aws::CloudWatch::Errors::Throttling
    puts 'We have been throttled, sleeping...'
    sleep 2
    retry
  end
end
