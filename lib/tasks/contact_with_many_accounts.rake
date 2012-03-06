namespace :contacts_with_many_accounts do
  task :delete => :enivronment do
    contacts = Contact.find(:all)
    contacts.delete_if{|c| c.accounts.size > 1 }
  end
end