require "bundler/setup"
require "bundler/gem_tasks"
require "bump/tasks"
require "wwtd/tasks"

task :test do
  sh "bundle exec rspec spec/"
end

task default: :wwtd
