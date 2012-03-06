namespace :account_add_column do
  task :primary_contact_id => :environment do
    accounts = Account.find :all
    accounts.each do |account|
      if account.contacts.size > 0
          account.account_contacts.each {|acnt_cnt| Account.update_all(["primary_contact_id = #{acnt_cnt.contact_id}"],{:id => account.id}) if acnt_cnt.priority == 1} unless account.account_contacts.blank?
          print "Account id: #{account.id}\t Primary contact id: #{account.primary_contact_id}\n"
      else
        account.delete
      end
    end
  end
end
