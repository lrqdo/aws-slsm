# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/checks'

class ChecksTest < Minitest::Test
  def test_load_is_executed
    check = Check.new(
      '/usr/local/shared/aws-simple-linux-server-monitoring/plugins',
      'load 1',
      'Average > 10 2x60s'
    )
    assert check.run != [nil, nil]
  end
end
