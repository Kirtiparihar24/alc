#zimbra_server_config:
#  liviatech.com:
#    key: value
#    url: url

#  mail.livialegal.com:
#    key: value
#    url: url
#{"zimbra_server_config"=>{"liviatech.com"=>{"url"=>"http://mail.liviatech.com", "key"=>"1da8c376385e599bcdda7199296fe1f548066a01b883598cb36ce1885b25cc65"}, "mail.livialegal.com"=>{"url"=>"http://portalmail01.livialegal.com", "key"=>"163289ceaaa1fd4f44e16a61a4fb949c0a7317590a72c9e2a798f6f0446308f1"}}} 

class ZimbraConfig <  Ohm::Model

  attribute :domain
  attribute :url
  attribute :domain_key
  def validate
    assert_present :domain
    assert_present :url
    assert_present :domain_key
    assert_unique :domain
  end
  index :domain
  
  def self.zimbra_yaml_to_redis(file_name="#{Rails.root}/config/appconfig/zimbra_servers.yml")
    if File.exist?(file_name) 
      zimbra_yaml = YAML::load(File.open(file_name))   
      zimbra_yaml["zimbra_server_config"].each do |k,v|
      ZimbraConfig.create(:domain=>k,:url=>v["url"],:domain_key=>v["key"])
      end
    end
  end

  def self.to_hash
    zimbra_hash= {}
    zimbra_hash["zimbra_server_config"]= {}
    ZimbraConfig.all.each do |zc|
      zimbra_hash["zimbra_server_config"][zc.domain] = {"url"=>zc.url,"key"=>zc.domain_key}     
    end

    zimbra_hash
  end
    
  
end
