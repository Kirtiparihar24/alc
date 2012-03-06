# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.
require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

# Required to load thinking_sphinx rake task
require 'thinking_sphinx/tasks'

# Required to load resque server's rake task
require 'resque/tasks'

# Required in resque worker need a Rails environment.
task "resque:setup" => :environment
