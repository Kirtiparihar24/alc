desc "Convert cirrent locale file into redis i18n"
task :zimbra_config_to_redis => :environment do
  file_path ="#{Rails.root}/config/appconfig/zimbra_servers.yml"
  ZimbraConfig.zimbra_yaml_to_redis(file_path)
end
