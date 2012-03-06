# To change this template, choose Tools | Templates
# and open the template in the editor.

module ZimbraContact

  def self.create(key, host, email, zimbra_contact, location)
        timestamp = ZimbraUserApi.get_timestamp
        preauth = ZimbraUserApi.calculate_preauth(key, email, timestamp)

        token = ZimbraUserApi.authenticate_with_preauth(host, email, preauth, timestamp)
        resp = ZimbraUserApi.createcontactrequest(host, token.authToken, zimbra_contact, location)
        resp_hash = {}
        resp.cn.__xmlattr.each { |key, value|
          resp_hash[key.name] = value
        }
        return resp_hash
  end

  def self.update(key, host, email, zimbra_contact)
        timestamp = ZimbraUserApi.get_timestamp
        preauth = ZimbraUserApi.calculate_preauth(key, email, timestamp)

        token = ZimbraUserApi.authenticate_with_preauth(host, email, preauth, timestamp)
        resp = ZimbraUserApi.modifycontactrequest(host, token.authToken, zimbra_contact)
        resp_hash = {}
        #resp.cn.__xmlattr.each { |key, value|
        #  resp_hash[key.name] = value
        #}
        return resp_hash
  end

  def self.delete(key, host, email, zimbra_contact_id)
        timestamp = ZimbraUserApi.get_timestamp
        preauth = ZimbraUserApi.calculate_preauth(key, email, timestamp)

        token = ZimbraUserApi.authenticate_with_preauth(host, email, preauth, timestamp)
        resp = ZimbraUserApi.deletecontactrequest(host, token.authToken, zimbra_contact_id)
  end
  
end
