task :update_phone_to_email=>:environment do

  contact = Contact.all(:order => "id")

  contact.each do | cnt |

    unless cnt.phone.nil?
       if cnt.phone.include?('@')
         if cnt.email.nil?
           p "#{cnt.id}------email nil--------#{cnt.phone}"
           cnt.update_attributes({:email => cnt.phone, :phone => nil})
         else
           p "#{cnt.id}------email not nil--------#{cnt.phone}"
           cnt.update_attribute(:phone, nil)
         end
       end
    end

  end  
  print "Contacts PhoneEmail update to Email Sucessfully\n"
end
