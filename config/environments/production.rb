# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.cache_template_loading            = true
ActionController::Base.cache_store= :file_store, "#{RAILS_ROOT}/tmp/cache/"
# See everything in the log (default is :info)
# config.log_level = :debug

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host = "http://assets.example.com"
ActionController::Base.cache_store= :file_store, "#{RAILS_ROOT}/tmp/cache/"
# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = true

# Enable threaded mode
#config.threadsafe!

ENV["HOST_NAME"] = "https://localhost:3001/"
if ENV["HOST_NAME"] == "https://production.liviatech.com"

  config.action_mailer.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
   :address => "lvmail01.livialegal.com",
   :port => 25,
   :domain => "lvmail01.livialegal.com",
   :authentication => :plain,
   :user_name => "support@liviatech.com",
   :password => "Accounts@2011",
  }
end
  
# This reg_exp allowed only 10.50.4.* subnet ips.
AUTHORIZE_SUBNET = /^(10)\.(50)\.(4)\.([0-9]{1,3})$/
LOCAL_IP = /^(127)\.(0)\.(0)\.(1)$/
