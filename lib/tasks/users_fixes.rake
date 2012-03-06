namespace :users do
  task :update_if_db_copied=>:environment do
    #print "!!!!!!Warning!!!!!!!!!!!! Do not run this task other than test.liviatech server!!!!!!!!!!!!!!!!!!!!!!!!!.\nDo you wish to continue?(Y)"
    print "Enter\n 1. For Test \n 2. For Gold \n 3. For Demo \n 4. For Stage \n 5. For Newui \n"
    ans = $stdin.gets.to_s.chomp.upcase
    #if ans=="Y"
    case(ans)
    when '1': domain = '.tm.'
    when '2': domain = '.gm.'
    when '3': domain = '.dm.'
    when '4': domain = '.stgm.'
    when '5': domain = '.ui.'
    else
      print "Good Bye.. Hee Hee :D\n"
    end
  
    @users=User.find(:all,:conditions=>['username in (?)',['careyd','charlest','johnc','michaelh']])
    @users.each do |u|
      u.update_attribute(:email,u.username+'@tnc'+domain+'liviatech.com')
    end

    @users=User.find(:all,:conditions=>['username in (?)',['coryh','dennisg','davidw','jeant','susanw']])
    @users.each do |u|
      u.update_attribute(:email,u.username+'@wnt'+domain+'liviatech.com')
    end

    @users=User.find(:all,:conditions=>['username in (?)',['peters','edwardp','rosed','solomanj']])
    @users.each do |u|
      u.update_attribute(:email,u.username+'@kns'+domain+'liviatech.com')
    end

    @companies = Company.find(:all, :conditions => ['zimbra_admin_account_email is not null'])
    unless @companies.nil?
      @companies.each do |c|
        c.zimbra_admin_account_email = c.zimbra_admin_account_email.split('.')[0]
        c.update_attribute(:zimbra_admin_account_email, c.zimbra_admin_account_email+domain+'liviatech.com')
      end
    end
  
    print "Users and companies updated Successfully\n"
  end

  task :fix_user_setting_for_upcoming_tasks => :environment do
    
  end

end