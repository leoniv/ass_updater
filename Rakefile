require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

task :default => :test

desc 'Run tests with simplecov'
task :test_with_simplecov do
  ENV["SIMPLECOV"] = 'YES'
  Rake::Task["test"].invoke
end
