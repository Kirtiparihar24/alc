namespace :user do
  task :strip_email => :environment do
    users = User.find_with_deleted(:all)
    users.each do |user|
      update_hash={:alt_email=> "#{user.alt_email.try(:strip)}", :email=>"#{user.email.try(:strip)}"}
      user.update_attributes(update_hash)
    end
  end
end