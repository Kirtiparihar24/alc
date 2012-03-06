namespace :change_title_column_size do
  task :name_type => :environment do
    Contact.connection.execute("ALTER TABLE contacts ALTER COLUMN title TYPE varchar(200)")
  end

  task :company_name => :environment do
    Contact.connection.execute("ALTER TABLE contacts ALTER COLUMN company_name TYPE varchar(200)")
  end
end