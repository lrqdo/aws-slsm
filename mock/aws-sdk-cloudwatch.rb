# frozen_string_literal: true

module Aws
  module CloudWatch
    module Errors
      # Fake error throttling handling
      class Throttling < ::StandardError
      end
    end

    # Mock for Aws::Cloudwatch::Client
    class Client
      def initialize(opts)
        raise 'Key region is a minimum in Aws::CloudWatch::Client.new' unless opts.key?(:region)
      end

      def assert(message)
        raise "Fail assert: #{message}" unless yield
      end

      def assert_metric_unit_is_valid(unit)
        assert("\"#{unit}\" is a valid unit") do
          %w[
            Bits
            Bits/Second
            Bytes
            Bytes/Second
            Count
            Count/Second
            Gigabits
            Gigabits/Second
            Gigabytes
            Gigabytes/Second
            Kilobits
            Kilobits/Second
            Kilobytes
            Kilobytes/Second
            Megabits
            Megabits/Second
            Megabytes
            Megabytes/Second
            Microseconds
            Milliseconds
            None
            Percent
            Seconds
            Terabits
            Terabits/Second
            Terabytes
            Terabytes/Second
          ].include?(unit)
        end
      end

      def assert_comparison_operator_is_known(operator)
        assert("\"#{operator}\" is a valid comparison operator") do
          %w[
            GreaterThanOrEqualToThreshold
            GreaterThanThreshold
            LessThanThreshold
            LessThanOrEqualToThreshold
          ].include?(operator)
        end
      end

      def assert_statistic_is_known(stat)
        assert("\"#{stat}\" is a valid statistic") do
          %w[
            SampleCount
            Average
            Sum
            Minimum
            Maximum
          ].include?(stat)
        end
      end

      def assert_include(hash, key)
        assert("\"#{key}\" is in: #{hash}") do
          hash.key?(key)
        end
      end

      def assert_not_include(hash, key)
        assert("\"#{key}\" is not in: #{hash}") do
          !hash.key?(key)
        end
      end

      def put_metric_data(opts)
        assert_include(opts, :namespace)
        assert_include(opts, :metric_data)
        metric_data = opts[:metric_data][0]

        assert_include(metric_data, :metric_name)
        assert_include(metric_data, :dimensions)

        if metric_data.key?(:value)
          assert_not_include(metric_data, :statistic_values)
        else
          assert_include(metric_data, :statistic_values)
        end

        assert_metric_unit_is_valid(metric_data[:unit]) if metric_data.key?(:unit)
      end

      def put_metric_alarm(opts)
        assert_include(opts, :alarm_name)
        assert_include(opts, :metric_name)
        assert_include(opts, :namespace)
        assert_include(opts, :dimensions)
        assert_include(opts, :period)
        assert_include(opts, :evaluation_periods)
        assert_include(opts, :threshold)
        assert_statistic_is_known(opts[:statistic])
        assert_metric_unit_is_valid(opts[:unit])
        assert_comparison_operator_is_known(opts[:comparison_operator])
      end

      def delete_alarms(opts)
        assert('"alarm_names" is given') { opts.key?(:alarm_names) }
      end
    end
  end
end
