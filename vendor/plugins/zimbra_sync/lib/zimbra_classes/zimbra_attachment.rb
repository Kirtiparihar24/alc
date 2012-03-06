module ZimbraAttachment

  def self.download_attachment(options)
    key,host,domain,token=ZimbraUtils.get_key_url_domain_token(options[:user_email_id])
    tmpurl="/service/home/~/?id=#{options[:msg_id]}&auth=co&part=#{options[:part_id]}" #  "~" is a shortcut to the current authenticated user
    if options[:part_id].eql?("0")
      tmpurl="/home/#{options[:user_email_id]}/message.txt?fmt=zip&filename=#{options[:file_name]}&id=#{options[:msg_id]}"
    end
    # Removeing http:// or https:// from host
    net_url=host.gsub(/http:\/\/|https:\/\//,'')
    Net::HTTP.start(net_url) {|http|
      req = Net::HTTP::Get.new(tmpurl)
      req.add_field 'Cookie', "ZM_AUTH_TOKEN=#{token.authToken}"     
      puts req.get_fields('Cookie').inspect
      response = http.request(req)
      Dir.mkdir("#{RAILS_ROOT}/zimbra_attachment") unless Dir.glob("#{RAILS_ROOT}/zimbra_attachment").present?
      Dir.mkdir("#{RAILS_ROOT}/zimbra_attachment/#{options[:user_email_id]+':'+options[:msg_id]}") unless Dir.glob("#{RAILS_ROOT}/zimbra_attachment/#{options[:user_email_id]+':'+options[:msg_id]}").present?
      if options[:part_id].eql?("0")
        file_path="#{RAILS_ROOT}/zimbra_attachment/#{options[:user_email_id]+':'+options[:msg_id]}/#{options[:file_name]}.zip"
      elsif options[:part_id].eql?("1")
        file_path="#{RAILS_ROOT}/zimbra_attachment/#{options[:user_email_id]+':'+options[:msg_id]}/#{options[:file_name]}.txt"
      else
        file_path="#{RAILS_ROOT}/zimbra_attachment/#{options[:user_email_id]+':'+options[:msg_id]}/#{options[:file_name]}"
      end
      File.open(file_path, 'w') {|f|
        if options[:part_id].eql?("1")
          response_with_headers="Date: "+ options[:msg_date]+"\n"
          response_with_headers+="From: "+ options[:from]+"\n"
          response_with_headers+="To: "+ options[:to]+"\n"
          response_with_headers+="Subject: "+ options[:subject]+"\n\n\n"
          response_with_headers+=response.body
          f.write(response_with_headers)
        else
        f.write(response.body)
        end        
      }
    }
  end

  def self.delete_attachments(folder)
    files=Dir.glob("#{RAILS_ROOT}/zimbra_attachment/#{folder}/*")
    files.each do |fn|
      File.delete(fn)
    end
    Dir.delete("#{RAILS_ROOT}/zimbra_attachment/#{folder}")
  end

end
