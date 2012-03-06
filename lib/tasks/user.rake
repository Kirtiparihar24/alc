namespace :user do
  desc "Enter Pacific Time (US & Canada) time zone  in user.time_zone colum where it's empty."
  task :update_time_zone =>:environment do   
    User.skip_callback(:create_user_settings) do     
     User.update_all ['time_zone = ?', "Pacific Time (US & Canada)"], ["time_zone IS NULL or time_zone = ?",'']  
    end    
  end
end