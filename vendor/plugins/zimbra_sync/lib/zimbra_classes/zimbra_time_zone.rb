module ZimbraTimeZone

  def self.update_time_zone(key, host, email, zimbra_time_zone)
    timestamp = ZimbraUserApi.get_timestamp
    preauth = ZimbraUserApi.calculate_preauth(key, email.to_s, timestamp)
    token = ZimbraUserApi.authenticate_with_preauth(host, email.to_s, preauth, timestamp)
    resp = ZimbraUserApi.modifyprefsrequest(host, token.authToken, zimbra_time_zone)
    resp_hash = {}
    resp.__xmlattr.each { |key, value|
      resp_hash[key.name] = value
    }
    return resp_hash
  end
  
end