module ZimbraCalendar

  def self.import(user_email_id)
    key,host,domain,token=ZimbraUtils.get_key_url_domain_token(user_email_id)
    tmpurl="/zimbra/user/#{user_email_id}/calendar.json"
    net_url=host.gsub(/http:\/\/|https:\/\//,'')

    obj = ""

    Net::HTTP.start(net_url) do |http|

      req = Net::HTTP::Get.new(tmpurl)
      req.add_field 'Cookie', "ZM_AUTH_TOKEN=#{token.authToken}"     
      response = http.request(req)

      obj =  JSON.parse(response.body)
    end
    return obj
  end 

end
