namespace :copy_users_email_to_single_signon_id do
  task :copy => :environment do
    users=User.find(:all,:with_deleted=>true)
    for user in users
      user.single_signon_id = user.email
      user.save
    end
    p "Emails copied to single_signon_id successfully!"
  end
end