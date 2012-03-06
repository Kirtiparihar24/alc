
module ZimbraUtils

  def self.get_key(domain)
    zc = ZimbraConfig.find(:domain=>domain).first
    key = zc ? zc.domain_key : nil
  end

  def self.get_url(domain)
    zc = ZimbraConfig.find(:domain=>domain).first
    url = zc ? zc.url : nil

    url
  end

  def self.get_domain(email_id)
    domain = email_id.split('@')[1]
    domain
  end

  def self.get_key_url_domain_token(email_id)
    domain = ZimbraUtils.get_domain(email_id)
    host = ZimbraUtils.get_url(domain)
    key = ZimbraUtils.get_key(domain)
    timestamp = ZimbraUserApi.get_timestamp
    preauth = ZimbraUserApi.calculate_preauth(key, email_id, timestamp)
    token = ZimbraUserApi.authenticate_with_preauth(host, email_id, preauth, timestamp)
    [key,host,domain,token]
  end

  def self.get_authtoken(email_id)
    domain = ZimbraUtils.get_domain(email_id)
    host = ZimbraUtils.get_url(domain)
    key = ZimbraUtils.get_key(domain)

    timestamp = ZimbraUserApi.get_timestamp
    preauth = ZimbraUserApi.calculate_preauth(key, email_id, timestamp)
    token = ZimbraUserApi.authenticate_with_preauth(host, email_id, preauth, timestamp)
  end

end
