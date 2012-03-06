namespace :account_contact do
  task :delete_association => :environment do
    account_contact = AccountContact.find_with_deleted(:all)
    account_contact.each do |acnt_cnt|
      account = Account.find_with_deleted(acnt_cnt.account_id)
      contact = Contact.find_with_deleted(acnt_cnt.contact_id)
      if account.deleted_at and !contact.deleted_at
        acnt_cnt.delete
        print "#{acnt_cnt.id} - ac_id\t #{contact.id}-- c.id\t #{account.id}\t \n"
      end
    end
  end
end