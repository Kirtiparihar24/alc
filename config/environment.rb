# Be sure to restart your server when you modify this file
# Specifies gem version of Rails to use when vendor/rails is not present
require 'thread'
RAILS_GEM_VERSION = '2.3.14' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

#ActiveSupport::CoreExtensions::Date::Conversions::DATE_FORMATS[:default]='%m/%d/%Y'

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :activity_observer,:comment_observer
  #config.load_paths += Dir["#{RAILS_ROOT}/app/models/[a-z]*"]
config.active_record.observers = [:comment_observer, :mail_notification_observer]
#config.active_record.observers =:mail_notification_observer
  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'
  
  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  config.load_paths << "#{RAILS_ROOT}/app/sweepers"
  config.active_record.schema_format = :sql
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }

  # Have migrations with numeric prefix instead of UTC timestamp.
  config.active_record.timestamped_migrations = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_content_type = "text/html"
  config.reload_plugins = true if RAILS_ENV == 'development'
#  config.action_mailer.smtp_settings =
#     {
#        :address               => 'lvmail01.livialegal.com',
#        :port                  => '25',
#        :domain                => 'lvmail01.livialegal.com',
#        :user_name             => 'support@liviatech.com',
#        :password              => 'support2010',
#        :authentication => :plain,
#        #:enable_ssl          =>  true
#        :enable_starttls_auto  => true
#
#      }
#livia smtp is not working. This only for to testing, need to remove later once livia smtp up
#   config.action_mailer.smtp_settings =
#      {
#    :enable_starttls_auto => true,
#    :address => "smtp.gmail.com",
#    :port => "587",
#    :domain => "livialegal.com",
#    :authentication => :plain,
#    :user_name => "livialegal.com@gmail.com",
#    :password => "livia2010"
#      }
  #config.action_controller.request_forgery_protection_token = :authenticity_token
  #config.action_controller.allow_forgery_protection = true
  config.after_initialize do
    include GeneralFunction
    Paperclip.interpolates :company_id do |attachment, style|
      attachment.instance.company_id
    end
  end

 # Following code is for memory leeks
#    config.gem 'oink'
#    begin
#      require 'hodel_3000_compliant_logger'
#      config.logger = Hodel3000CompliantLogger.new(config.log_path)
#    rescue LoadError => e
#      $stderr.puts "Hodel3000CompliantLogger unavailable, oink will be disabled"
#    end

end
#[ "app/models" ].each do |path|
#  Dir["#{RAILS_ROOT}/#{path}/**/*.rb"].each do |file|
#    load file
#  end
#end

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance_tag|
  html_tag
end

# Set LIVIA date format as default.
ActiveSupport::CoreExtensions::Date::Conversions::DATE_FORMATS[:default]='%m/%d/%Y'
APP_URLS = YAML.load_file(Pathname.new(RAILS_ROOT) + 'config/appconfig/helpdesk_setup.yml').symbolize_keys

HAS_HELPDESK = false

ExceptionNotification::Notifier.sender_address = %("Application Error" <liviaservices@liviatech.com>)
# defaults to "[ERROR] "
ExceptionNotification::Notifier.email_prefix = "[APP] "
ExceptionNotification::Notifier.exception_recipients = %w(sapna.chaurasia@livialegal.com ajay.arsud@livialegal.com milind.kanchan@livialegal.com)
