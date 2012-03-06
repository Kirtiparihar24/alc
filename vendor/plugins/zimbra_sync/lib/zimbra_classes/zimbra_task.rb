
module ZimbraTask

  def self.create_task(key, host, email, zimbra_task_hash,  zimbra_comp_hash, location)
    timestamp = ZimbraUserApi.get_timestamp
    preauth = ZimbraUserApi.calculate_preauth(key, email.to_s, timestamp)
    token = ZimbraUserApi.authenticate_with_preauth(host, email.to_s, preauth, timestamp)
    resp = ZimbraUserApi.createtaskrequest(host, token.authToken, zimbra_task_hash,  zimbra_comp_hash, location)
    resp_hash = {}
    resp.__xmlattr.each { |key, value|
      resp_hash[key.name] = value
    }
    
    return resp_hash
  end


  def self.update_task(key, host, email, zimbra_task_hash,  zimbra_comp_hash, location)
    timestamp = ZimbraUserApi.get_timestamp
    preauth = ZimbraUserApi.calculate_preauth(key, email.to_s, timestamp)
    token = ZimbraUserApi.authenticate_with_preauth(host, email.to_s, preauth, timestamp)
    resp = ZimbraUserApi.modifytaskrequest(host, token.authToken, zimbra_task_hash,  zimbra_comp_hash, location)
    resp_hash = {}
    resp.__xmlattr.each { |key, value|
      resp_hash[key.name] = value
    }
    return resp_hash

  end



  def self.delete_task(key, host, email, zimbra_task_id)
    timestamp = ZimbraUserApi.get_timestamp
    preauth = ZimbraUserApi.calculate_preauth(key, email.to_s, timestamp)
    token = ZimbraUserApi.authenticate_with_preauth(host, email.to_s, preauth, timestamp)
    resp = ZimbraUserApi.deletetaskrequest(host, token.authToken, zimbra_task_id.to_s)
        
  end



  def self.create_apt(key, host, email, zimbra_apt_hash, zimbra_apt_comp_hash, location)
    timestamp = ZimbraUserApi.get_timestamp
    preauth = ZimbraUserApi.calculate_preauth(key, email.to_s, timestamp)
    token = ZimbraUserApi.authenticate_with_preauth(host, email.to_s, preauth, timestamp)
    resp = ZimbraUserApi.create_apt_request(host, token.authToken, zimbra_apt_hash,  zimbra_apt_comp_hash, location)
    resp_hash = {}
    resp.__xmlattr.each { |key, value|
      resp_hash[key.name] = value
    }
    return resp_hash

  end

  def self.update_apt(key, host, email, zimbra_apt_hash, zimbra_apt_comp_hash, location)
    timestamp = ZimbraUserApi.get_timestamp
    preauth = ZimbraUserApi.calculate_preauth(key, email.to_s, timestamp)
    token = ZimbraUserApi.authenticate_with_preauth(host, email.to_s, preauth, timestamp)
    resp = ZimbraUserApi.modify_apt_request(host, token.authToken, zimbra_apt_hash,  zimbra_apt_comp_hash, location)
    resp_hash = {}
    resp.__xmlattr.each { |key, value|
      resp_hash[key.name] = value
    }
    return resp_hash

  end

  def self.delete_apt(key, host, lawyer_email, cancel_hash, zimbra_task_id)
    timestamp = ZimbraUserApi.get_timestamp
    preauth = ZimbraUserApi.calculate_preauth(key, lawyer_email.to_s, timestamp)
    token = ZimbraUserApi.authenticate_with_preauth(host, lawyer_email.to_s, preauth, timestamp)
    resp = ZimbraUserApi.delete_apt_request(host, token.authToken, cancel_hash, zimbra_task_id.to_s)

  end

  def self.get_prefs_request(key, host, lawyer_email, lawyer_name)
    timestamp = ZimbraUserApi.get_timestamp
    preauth = ZimbraUserApi.calculate_preauth(key, lawyer_email.to_s, timestamp)
    token = ZimbraUserApi.authenticate_with_preauth(host, lawyer_email.to_s, preauth, timestamp)
    resp = ZimbraUserApi.getprefsrequest( host, token.authToken, lawyer_name.to_s)
    return resp["pref"].reject{|x| !x.include?"/"}
  end


  def self.create_exception_apt(key, host, email, zimbra_apt_hash, zimbra_apt_comp_hash, location)
    timestamp = ZimbraUserApi.get_timestamp
    preauth = ZimbraUserApi.calculate_preauth(key, email.to_s, timestamp)
    token = ZimbraUserApi.authenticate_with_preauth(host, email.to_s, preauth, timestamp)
    resp = ZimbraUserApi.create_exception_apt_request(host, token.authToken, zimbra_apt_hash,  zimbra_apt_comp_hash, location)
    resp_hash = {}
    resp.__xmlattr.each { |key, value|
      resp_hash[key.name] = value
    }
    return resp_hash
  end

end