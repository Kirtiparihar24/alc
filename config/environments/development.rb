# Settings specified here will take precedence over those in config/environment.rb
#require 'rack/bug'
# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.

#require 'metric_fu'
#require 'rack/bug'
#require 'ruby-debug'


#config.middleware.use "Rack::Bug",
#    :secret_key => "someverylongandveryhardtoguesspreferablyrandomstring"
#config.cache_classes = true
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = false
config.action_controller.perform_caching             = true
#config.cache_store = :mem_cache_store
#config.cache_store = :file_store, "#{RAILS_ROOT}/tmp/cache/"
ActionController::Base.cache_store= :file_store, "#{RAILS_ROOT}/tmp/cache/"
# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = true
#config.middleware.use("Rack::Bug")
#config.middleware.use("Rack::Bug", :password => 'muzak')
#config.threadsafe!


#config.after_initialize do
 # Bullet.enable = true
 # Bullet.alert = true
 # Bullet.bullet_logger = true
 # Bullet.console = true
 # Bullet.growl = false
 # Bullet.xmpp = { :account => 'bullets_account@jabber.org',
 #                :password => 'bullets_password_for_jabber',
  #                :receiver => 'your_account@jabber.org',
  #                :show_online_status => false }
 # Bullet.rails_logger = true
 # Bullet.disable_browser_cache = true
#end

ENV["HOST_NAME"] = "http://localhost:3000"

# This reg_exp allowed only 10.50.4.* subnet ips.
AUTHORIZE_SUBNET = /^(10)\.(50)\.(4)\.([0-9]{1,3})$/
LOCAL_IP = /^(127)\.(0)\.(0)\.(1)$/


