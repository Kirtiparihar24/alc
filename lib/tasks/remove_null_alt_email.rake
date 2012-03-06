# Author Anil
# For removing 'NULL' entries for alt_email
desc "For removing 'NULL' entries for alt_email"
task :remove_null_alt_email => :environment do
  User.update_all("alt_email = NULL","alt_email = 'NULL'")
end
