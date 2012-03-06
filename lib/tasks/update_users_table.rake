task :update_if_db_copied=>:environment do
  #print "!!!!!!Warning!!!!!!!!!!!! Do not run this task other than test.liviatech server!!!!!!!!!!!!!!!!!!!!!!!!!.\nDo you wish to continue?(Y)"
  print "Enter\n 1. For Test \n 2. For Gold \n 3. For Demo \n 4. For Stage \n 5. For Sales \n 6. For Pre-production \n 7. For Local \n"
  ans = $stdin.gets.to_s.chomp.upcase
  #if ans=="Y"
  case(ans)
  when '1': domain = '.tmail.'
  when '2': domain = '.gm.'
  when '3': domain = '.dmail.'
  when '4': domain = '.stgm.'
  when '5': domain = '.sm.'
  when '6': Company.update_all(:zimbra_admin_account_email => nil)
            @company = Company.find_by_name("Pre-Prodcution Inc")
            @company.update_attributes(:zimbra_admin_account_email => "admin_preproduction@mail.com")  
  when '7': @users=User.find(:all,:conditions=>['username in (?)',['careyd@tnc.com','charlest@tnc.com','johnc@tnc.com','michaelh@tnc.com']])
    @users.each do |u|
      u.update_attribute(:email,u.username.split('@')[0]+'@tnc.tm.liviatech.com')
      Employee.update_all({:email => u.email},{:user_id => u.id})
    end

    @users=User.find(:all,:conditions=>['username in (?)',['coryh@wnt.com','dennisg@wnt.com','davidw@wnt.com','jeant@wnt.com','susanw@wnt.com']])
    @users.each do |u|
      u.update_attribute(:email,u.username.split('@')[0]+'@wnt.tm.liviatech.com')
      Employee.update_all({:email => u.email},{:user_id => u.id})
    end

    @users=User.find(:all,:conditions=>['username in (?)',['peters@kns.com','edwardp@kns.com','rosed@kns.com','solomanj@kns.com']])
    @users.each do |u|
      u.update_attribute(:email,u.username.split('@')[0]+'@kns.tm.liviatech.com')
      Employee.update_all({:email => u.email},{:user_id => u.id})
    end

    @users=User.find(:all,:conditions=>['username in (?)',['1lawyer1@lawfirm1.com','1lawyer2@lawfirm1.com','1lawyer3@lawfirm1.com']])
    @users.each do |u|
      u.update_attribute(:email,u.username.split('@')[0]+'@lawfirm1.tm.liviatech.com')
      Employee.update_all({:email => u.email},{:user_id => u.id})
    end

    @users=User.find(:all,:conditions=>['username in (?)',['2lawyer1@lawfirm2.com','2lawyer2@lawfirm2.com','2lawyer3@lawfirm2.com']])
    @users.each do |u|
      u.update_attribute(:email,u.username.split('@')[0]+'@lawfirm2.tm.liviatech.com')
      Employee.update_all({:email => u.email},{:user_id => u.id})
    end

    @users=User.find(:all,:conditions=>['username in (?)',['3lawyer1@lawfirm3.com','3lawyer2@lawfirm3.com','3lawyer3@lawfirm3.com']])
    @users.each do |u|
      u.update_attribute(:email,u.username.split('@')[0]+'@lawfirm3.tm.liviatech.com')
      Employee.update_all({:email => u.email},{:user_id => u.id})
    end

    @companies = Company.find(:all, :conditions =>["zimbra_admin_account_email != ''"])
    unless @companies.blank?
      @companies.each do |c|
        c.zimbra_admin_account_email = c.zimbra_admin_account_email.split('.')[0]
        c.update_attribute(:zimbra_admin_account_email, c.zimbra_admin_account_email+'.tm.liviatech.com')
      end
    end
    print "Users and companies updated Successfully\n"
  end

  unless domain.blank?
    @users=User.find(:all,:conditions=>['username in (?)',['careyd@tnc.com','charlest@tnc.com','johnc@tnc.com','michaelh@tnc.com']])
    @users.each do |u|
      u.update_attribute(:email,u.username.split('@')[0]+'@tnc'+domain+'liviatech.com')
      Employee.update_all({:email => u.email},{:user_id => u.id})
    end

    @users=User.find(:all,:conditions=>['username in (?)',['coryh@wnt.com','dennisg@wnt.com','davidw@wnt.com','jeant@wnt.com','susanw@wnt.com']])
    @users.each do |u|
      u.update_attribute(:email,u.username.split('@')[0]+'@wnt'+domain+'liviatech.com')
      Employee.update_all({:email => u.email},{:user_id => u.id})
    end

    @users=User.find(:all,:conditions=>['username in (?)',['peters@kns.com','edwardp@kns.com','rosed@kns.com','solomanj@kns.com']])
    @users.each do |u|
      u.update_attribute(:email,u.username.split('@')[0]+'@kns'+domain+'liviatech.com')
      Employee.update_all({:email => u.email},{:user_id => u.id})
    end

    @users=User.find(:all,:conditions=>['username in (?)',['1lawyer1@lawfirm1.com','1lawyer2@lawfirm1.com','1lawyer3@lawfirm1.com']])
    @users.each do |u|
      u.update_attribute(:email,u.username.split('@')[0]+'@lawfirm1'+domain+'liviatech.com')
      Employee.update_all({:email => u.email},{:user_id => u.id})
    end

    @users=User.find(:all,:conditions=>['username in (?)',['2lawyer1@lawfirm2.com','2lawyer2@lawfirm2.com','2lawyer3@lawfirm2.com']])
    @users.each do |u|
      u.update_attribute(:email,u.username.split('@')[0]+'@lawfirm2'+domain+'liviatech.com')
      Employee.update_all({:email => u.email},{:user_id => u.id})
    end

    @users=User.find(:all,:conditions=>['username in (?)',['3lawyer1@lawfirm3.com','3lawyer2@lawfirm3.com','3lawyer3@lawfirm3.com']])
    @users.each do |u|
      u.update_attribute(:email,u.username.split('@')[0]+'@lawfirm3'+domain+'liviatech.com')
      Employee.update_all({:email => u.email},{:user_id => u.id})
    end

    @companies = Company.find(:all, :conditions => ["zimbra_admin_account_email != ''"])
    unless @companies.blank?
      @companies.each do |c|
        c.zimbra_admin_account_email = c.zimbra_admin_account_email.split('.')[0]
        c.update_attribute(:zimbra_admin_account_email, c.zimbra_admin_account_email+domain+'liviatech.com')
      end
    end
    print "Users and companies updated Successfully\n"
  end  
end
