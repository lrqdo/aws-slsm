# frozen_string_literal: true

require 'rake/testtask'

desc 'Run tests'
task default: %i[
  install
  rubocop
  minitest
  prepare
  script
  script_remove_alarms
  script_set_alarms
]

desc 'Install dependencies'
task :install do
  sh 'bundle install'
end

desc 'Rubocop style'
task :rubocop do
  sh 'rubocop'
end

desc 'Minitest'
task :minitest do
  sh 'ruby ./test/test_checks.rb'
end

desc 'Prepare environment'
task :prepare do
  sh 'mkdir -p /var/lib/aws-simple-linux-server-monitoring'
  sh 'rm -f /var/lib/aws-simple-linux-server-monitoring/alarm_created'
end

desc 'Script full execution'
task :script do
  sh 'ruby -I/var/www/mock ./src/aws-slsm'
end

desc 'Script remove alarms'
task :script_remove_alarms do
  sh 'ruby -I/var/www/mock ./src/aws-slsm --remove-alarms'
end

desc 'Script set alarms'
task :script_set_alarms do
  sh 'ruby -I/var/www/mock ./src/aws-slsm --set-alarms'
end
