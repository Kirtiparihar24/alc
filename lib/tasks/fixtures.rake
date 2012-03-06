# This rake task is used to create fixture from the existing table data
# Currently we are using this to create company_lookup.yml and lookup.yml
# as per our requirement we need to modify the bellow code. -- Hitesh Rawal
namespace :db do
  namespace :fixtures do
    desc 'Create YAML test fixtures from data in an existing database.  
    Defaults to development database.  Set RAILS_ENV to override.'
    task :dump => :environment do
      # only for compnay_lookups
      #sql  = "SELECT * FROM %s where company_id = 1 order by id ASC"
      
      # for lookups
      sql  = "SELECT * FROM %s order by id ASC"
      skip_tables = ["schema_info"]
      ActiveRecord::Base.establish_connection(RAILS_ENV)
      tables=ENV['TABLES'].split(',')
      tables ||= (ActiveRecord::Base.connection.tables - skip_tables)
 
      tables.each do |table_name|
        i = 1
        File.open("#{RAILS_ROOT}/test/fixtures/#{table_name}.yml", 'w') do |file|
          data = ActiveRecord::Base.connection.select_all(sql % table_name)
          file.write data.inject({}) { |hash, record|
            #hash["#{table_name}_#{i.succ!}"] = record            
            record['id'] = i
            hash["#{table_name}_#{i}"] = record
            i = i + 1
            hash
          }.to_yaml
        end
      end
    end
  end
end