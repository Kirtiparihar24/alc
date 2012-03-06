namespace :password_update do
  
  desc "This will update all the user password with new password"
  task :change_passwords => :environment do
    User.all.each do |user|
      user.update_attributes(:password => 'C@mp@!gn20!!',:password_confirmation => 'C@mp@!gn20!!')
    end
  end
  
end