

require "rake/testtask"

task :default => [:test]

Rake::TestTask.new do |test|
  test.libs << "test"
  test.libs << "."
  test.test_files = Dir[ "test/test_*.rb" ]
  test.verbose = true
  test.warning = false
end

