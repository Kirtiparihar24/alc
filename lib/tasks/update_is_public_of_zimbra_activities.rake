namespace :update_is_public_of_zimbra_activities do

  desc "Update the is_public column of the zimbra activities (Personal Activities)"
  task :update_is_public => :environment do
    ZimbraActivity.update_all(:is_public => false,:mark_as=>"PRI")
  end
end