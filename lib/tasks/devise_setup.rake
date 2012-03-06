namespace :devise_setup do
  task :set_default_password=>:environment do
    usr=User.all
    usr.each do |u|     
      u.update_attributes(:password=>"livia2010")    
    end
  end
end
