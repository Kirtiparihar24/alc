# This class is helpful for redis i18n implementation
# 
#---
# en:
#  text_menu_contacts: "Business Contacts"
#  text_menu_accounts: "Accounts"
#  text_menu_opportunity: "Opportunities"
#  errors:
#      template:
#        header: "%{count} errors prohibited this %{model} from being saved"

class DynamicI18n
  
  def self.redis_con
    @@redis= Redis.new()
  end

  DynamicI18n.redis_con
  #@@redis = Redis.new
  # yaml to redis for i18n
  # file name is "/abc/en.yml"

  def self.i18n_yaml_to_redis(file_name)
    # for picking up initial key for iterating
    # TODO may be it can be automated further 
    i18n_key = file_name.split("/").last.split(".").first
    #i18n_key = "en"
    if File.exist?(file_name)
      i18n_yml = YAML::load(File.open(file_name))
      i18n_yml[i18n_key].each do |k,v|
        # if yaml data  contain further nested then create nestedkey or add key to redis 
        if i18n_yml[i18n_key][k].is_a?(Hash)
          self.add_value_to_redis("#{i18n_key}",i18n_yml[i18n_key])
        else
          create("#{i18n_key}.#{k}","#{v}")
        end
      end
    end
    #@@redis.save
  end

  # en.
  #  errors:
  #    template:
  #      header: "%{count} errors prohibited this %{model} from being saved"
  # THis method generates folloeing key and set its respective value
  #en.errors.template.header="%{count} errors prohibited this %{model} from being saved"
  def self.add_value_to_redis(i18n_key,k)

    k.each do |key,value|
    
      if k[key].is_a?(Hash)
        self.add_value_to_redis(i18n_key+"."+key,k[key])
      else
        create("#{i18n_key}.#{key}","#{value}")
      end
    end 
  end

  # Add to en(master) it will add to all company 
  # Company is a redis hash which contain company id or company name as per requirement 
  # and its i18n value like us_20
  # any data is added to master it will find all the respective company and add data 
  def self.i18n_add_to_master(key,val)
    create("#{key}","#{val}")
    key = key.split(".").drop(1).join(".")
    # find out all company and add to all company 
    # like after create callback 
    company_array = @@redis.hgetall("company")
    company_array.each do |ckey,cvalue|
      create("#{cvalue}.#{key}",val)
    end
  end

  # for removing data from master and company
  def self.i18n_remove_from_master(key)
    remove("#{key}")
    #key = en.abc.xyz
    key = key.split(".").drop(1).join(".")
    # key abc.xyz
    company_array = @@redis.hgetall("company")
    company_array.each do |ckey,cvalue|
      destroy("#{cvalue}.#{key}")
    end
  end

  # add to redis
  def self.create(key,value)
    key = key.strip
    if value =~ /:/
      @@redis.set(key,value.to_json)
    else
      @@redis.set(key,"#{value}")
    end
  end

  # remove from redis
  def self.destroy(key)
    @@redis.del(key)
  end
  
  # get data from redis
  def self.find(key)
    @@redis.get(key)
  end

  #This contain name = "company name or id",value en_20
  def self.add_company(name,value)
    @@redis.hset("company",name,value)
  end

  #This contain name = "company name or id"
  def self.remove_company(name)
    @@redis.hdel("company",name)
  end

  # find out word and replace it
  def self.search_and_replace_word(search_value,replace_value,i18n="*")
    i18n_keys = find_all(i18n)
    i18n_keys.each do |i18n_key|
      value = @@redis.get(i18n_key)
      value.gsub!(/\b#{search_value}\b/,replace_value)
      @@redis.set(i18n_key,value)
    end   
  end

  # add master clone to another company
  # i18n_key is us_20
  def self.clone_master_data_for_company(i18n_key)
    # find out all master keys i.e en
    master_keys= find_all("en.*")
    master_keys.each do |key|
    clone_key = "#{i18n_key}.#{key.split('.').drop(1).join(".")}"
    value = @@redis.get(key)
    if value =~ /:/
      value =  ActiveSupport::JSON.decode(value)
    end
      create(clone_key,value)
    end
  end
  def self.find_all(key)
    @@redis.keys(key)
  end
  # get all company hashes
  def self.get_companies
    @@redis.hgetall("company")
  end

   # add new label to en 
   # this will add to master
  def self.update_new_label(file_name)
    yaml_redis = DynamicI18n.yaml_to_redis_hash(file_name)
    en_keys = DynamicI18n.find_all("en.*")
    new_labels = yaml_redis.keys - en_keys
    new_labels.each do |label|
      i18n_add_to_master(label,yaml_redis[label])
    end
    
  end
 #help to create redis keys
  def self.yaml_to_redis_hash(file_name)
    keys= {}
    if File.exist?(file_name) 
      yaml_hash = YAML::load(File.open(file_name))
      yaml_hash.each do |k,v|
      # if yaml data  contain further nested then create nestedkey or add key to redis 
       keys= add_key_to_array(yaml_hash[k],k,keys)
     end
         
     keys
    end
  end

  # en.
  #  errors:
  #    template:
  #      header: 
  # This method generates folloeing key and set its respective value
  # en.errors.template.header
  def self.add_key_to_array(yaml_hash,yaml_key,keys={})
    if yaml_hash.is_a?(Hash)
      yaml_hash.each do |key,value|
       if yaml_hash[key].is_a?(Hash)
         add_key_to_array(yaml_hash[key],yaml_key+"."+key,keys)
       else
          keys["#{yaml_key}.#{key}"] = value
       
       end
      end 
    else
      keys[yaml_key] = yaml_hash
    end

    keys
  end
end

