#This is requied by resque server 
require 'resque'

#This is required to load workers task from lib's subfolder 
Dir["#{RAILS_ROOT}/lib/workers/*.rb"].each { |f| require(f) }

