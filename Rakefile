require 'rubygems'
require 'cucumber'
require 'cucumber/rake/task'
require 'puppetlabs_spec_helper/rake_tasks' # needed for some module packaging tasks
require 'puppet_blacksmith/rake_tasks'

Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = "features --format pretty"
end
