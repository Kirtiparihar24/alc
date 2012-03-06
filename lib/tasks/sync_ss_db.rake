require "uri"
require "net/http"
namespace :sync_ss_db do
  task :create_helpdesk_companies=> :environment do
    livia_companies = Company.all

    helpdesk_companies = Company.find_by_sql("SELECT * FROM helpdesk.company_clients")
    client_type=Company.find_by_sql("SELECT * FROM helpdesk.company_client_types where name='Gold'")
    livia_company_in_helpdesk=Company.find_by_sql("select id from helpdesk.companies where name='LIVIA India Pvt. Ltd'")
    helpdesk_company_names = helpdesk_companies.map(&:name)

    for livia_company in livia_companies

      if helpdesk_company_names.include? livia_company.name
        helpdesk_company_id = helpdesk_companies.select {|hc| hc.name.eql?(livia_company.name)}[0].id
        company_app = Company.find_by_sql("select * from single_signon.company_apps where product_id= (select id from helpdesk.products where key='#{APP_URLS[:livia_portal_key]}' limit 1) and product_company_id = #{livia_company.id} and helpdesk_company_id = #{helpdesk_company_id}")
        if company_app.blank?
          Company.connection.execute("INSERT INTO single_signon.company_apps(product_id, product_company_id,helpdesk_company_id) VALUES ( (select id from helpdesk.products where key='#{APP_URLS[:livia_portal_key]}' limit 1), #{livia_company.id},#{helpdesk_company_id});")
        end
      else
        Company.connection.execute("INSERT INTO helpdesk.company_clients (name,company_id,company_client_type_id,description,created_at,updated_at)
                                 VALUES ('#{livia_company.name}',#{livia_company_in_helpdesk[0]['id']},#{client_type[0]['id']},'created from livia portal','#{livia_company.created_at}','#{livia_company.updated_at}');")
                 
        new_company_id = Company.find_by_sql("select * from helpdesk.company_clients where name = '#{livia_company.name}'")[0].id
        Company.connection.execute("INSERT INTO single_signon.company_apps(product_id, product_company_id,helpdesk_company_id) VALUES ( (select id from helpdesk.products where key='#{APP_URLS[:livia_portal_key]}' limit 1), #{livia_company.id},#{new_company_id});")
      end
    end
  end

  task :update_employees=> :environment do
    livia_users = User.all
    livia_clients = []
    livia_users.each do |usr|
      livia_clients << usr if usr.employee
    end
    livia_clients.compact!
    helpdesk_users = User.find_by_sql("select * from helpdesk.users")
    helpdesk_role_id = Role.find_by_sql("select id from helpdesk.roles where name='Client User'")[0].id
    helpdesk_users_login = helpdesk_users.map(&:login)
    livia_clients.each do |client|
      company_client_id = Company.find_by_sql("select * from single_signon.company_apps where product_company_id=#{client.company.id} and product_id=  (select id from helpdesk.products where key=#{APP_URLS[:livia_portal_key]} limit 1)")[0].helpdesk_company_id
      unless helpdesk_users_login.include?(client.username)

#        User.connection.execute("INSERT INTO helpdesk.users (email,encrypted_password,password_salt,company_id,role_id,login,name,created_at,updated_at)
#                                 VALUES ('#{client.email}','#{client.encrypted_password}','#{client.password_salt}',1,
#                                 #{helpdesk_role_id},'#{client.username}','#{client.first_name}','#{client.created_at}','#{client.updated_at}');")

        url = URI.parse(APP_URLS[:helpdesk_url] + "/users/clepsotda")
        if url.scheme == 'https'
          uri = URI.parse(APP_URLS[:helpdesk_url] + "/login")
          https = Net::HTTP.new(uri.host, uri.port)
          https.use_ssl =true
          res = https.get(uri.path)
          c=res.response['set-cookie'].split('; ')[0]
          USERAGENT = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.1) Gecko/20060111 Firefox/1.5.0.1'
          headers = {
                     'Cookie' => c,
                     'Referer' => APP_URLS[:helpdesk_url] + "/login",
                     'Content-Type' => 'application/x-www-form-urlencoded',
                     'User-Agent' => USERAGENT
                    }

          data ="email=#{client.email}&password=helpdesk_2010&password_confirmation=helpdesk_2010&role_id=#{helpdesk_role_id}&login=#{client.username}&first_name='#{client.first_name.gsub(/'/,"''")}'&last_name='#{client.last_name.gsub(/'/,"''")}'"
          resp, data = https.post2(url.path, data, headers)
        else
          args={:email=>client.email,:password_confirmation=>"helpdesk_2010",:password=>"helpdesk_2010",:role_id=>helpdesk_role_id,:login=>client.username,:first_name=>client.first_name, :last_name=>client.last_name.gsub(/'/,"''")}
          Net::HTTP.post_form(url,args)
        end
       
        new_user_id = User.find_by_sql("select * from helpdesk.users where login = '#{client.username}'")[0].id
        

        User.connection.execute("INSERT INTO helpdesk.company_client_users (company_client_id,user_id,dob,created_at,updated_at)
                                 VALUES (#{company_client_id},#{new_user_id},'#{client.employee.birthdate || Time.now}','#{client.created_at}','#{client.updated_at}');")

        User.connection.execute("INSERT INTO single_signon.user_apps(product_id, product_user_id,helpdesk_user_id) VALUES ( (select id from helpdesk.products where key='#{APP_URLS[:livia_portal_key]}' limit 1), #{client.id},#{new_user_id});")
      else
        helpdesk_user_id = helpdesk_users.select {|user| user.login.eql?(client.username)}[0].id
        user_app = User.find_by_sql("select * from single_signon.user_apps where product_user_id = #{client.id} and product_id= (select id from helpdesk.products where key='#{APP_URLS[:livia_portal_key]}' limit 1) and helpdesk_user_id = #{helpdesk_user_id}")
        if user_app.blank?
          User.connection.execute("INSERT INTO single_signon.user_apps(product_id,product_user_id,helpdesk_user_id) VALUES ( (select id from helpdesk.products where key='#{APP_URLS[:livia_portal_key]}' limit 1), #{client.id},#{helpdesk_user_id});")
        end

        company_client_user = Company.find_by_sql("select * from helpdesk.company_client_users where user_id = #{helpdesk_user_id}")
        if company_client_user.blank?
          User.connection.execute("INSERT INTO helpdesk.company_client_users (company_client_id,user_id,dob,created_at,updated_at)
                                 VALUES (#{company_client_id},#{helpdesk_user_id},'#{client.employee.birthdate || Time.now}','#{client.created_at}','#{client.updated_at}');")
        end
      end
    end
  end


   task :update_livians=> :environment do
       # STEP 1: find all livians users in livia portal
        livia_users = User.all
        livia_service_providers = []
        livia_users.each do |usr|
          livia_service_providers << usr if usr.service_provider
        end
        livia_service_providers.compact!
        p '---------------------------------Step 1 done----------------------------'
        p livia_service_providers.count 
       # STEP 2: find all livian in helpdesk
    helpdesk_users = User.find_by_sql("select * from helpdesk.users")
    helpdesk_role_id = Role.find_by_sql("select id from helpdesk.roles where name='Livian'")[0].id
    helpdesk_users_login = helpdesk_users.map(&:login)
    company_id= Company.find_by_sql("select id from helpdesk.companies where name ilike '%LIVIA India Pvt. Ltd%'")[0].id
    p "---------------------------------Step 2 done--------------------------------"
     livia_service_providers.each do |service_provider|
              unless helpdesk_users_login.include?(service_provider.username)
                 # STEP 4:  create a user in helpdesk app if noit already present
                    url = URI.parse(APP_URLS[:helpdesk_url]+"/users/clepsotda")
                            if url.scheme == 'https'
                              uri = URI.parse(APP_URLS[:helpdesk_url] + "/login")
                              https = Net::HTTP.new(uri.host, uri.port)
                              https.use_ssl =true
                              res = https.get(uri.path)
                              c=res.response['set-cookie'].split('; ')[0]
                              USERAGENT = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.1) Gecko/20060111 Firefox/1.5.0.1'
                              headers = {
                                         'Cookie' => c,
                                         'Referer' => APP_URLS[:helpdesk_url] + "/login",
                                         'Content-Type' => 'application/x-www-form-urlencoded',
                                         'User-Agent' => USERAGENT
                                        }
                             data ="email=#{service_provider.email}&password=helpdesk_2010&password_confirmation=helpdesk_2010&role_id=#{helpdesk_role_id}&login=#{service_provider.username}&first_name=#{service_provider.first_name}&last_name=#{service_provider.first_name}&company_id=#{company_id}"
                             resp, data = https.post2(url.path, data, headers)
                            else
                               args={:email=>service_provider.email,:password_confirmation=>"helpdesk_2010",:password=>"helpdesk_2010",:role_id=>helpdesk_role_id,:login=>service_provider.username,:first_name=>service_provider.first_name,:last_name=>service_provider.last_name.gsub(/'/,"''"),:company_id=>company_id}
                                Net::HTTP.post_form(url,args)

                            end
                            new_user_id = User.find_by_sql("select * from helpdesk.users where login = '#{service_provider.username}'")[0].id
                            User.connection.execute("INSERT INTO helpdesk.employees (company_id,user_id,dob,created_at,updated_at)
                                 VALUES (#{company_id},#{new_user_id},'#{service_provider.service_provider.birthdate || Time.now}','#{service_provider.created_at}','#{service_provider.updated_at}');") if User.find_by_sql("select * from helpdesk.employees where user_id =#{new_user_id}").blank?

                            User.connection.execute("INSERT INTO single_signon.user_apps(product_id, product_user_id,helpdesk_user_id) VALUES ( (select id from helpdesk.products where key='#{APP_URLS[:livia_portal_key]}' limit 1), #{service_provider.id},#{new_user_id});")

                else
                 # STEP 3: if livian in livia portal are there in helpdesk then map it in user apps
                 helpdesk_user_id = helpdesk_users.select {|user| user.login.eql?(service_provider.username)}[0].id
                 user_app = User.find_by_sql("select * from single_signon.user_apps where product_id =  (select id from helpdesk.products where key='#{APP_URLS[:livia_portal_key]}' limit 1) and product_user_id = #{service_provider.id} and helpdesk_user_id = #{helpdesk_user_id}")
                  if user_app.blank?
                    User.connection.execute("INSERT INTO single_signon.user_apps(product_id, product_user_id,helpdesk_user_id) VALUES ( (select id from helpdesk.products where key='#{APP_URLS[:livia_portal_key]}' limit 1), #{service_provider.id},#{helpdesk_user_id});")
                  end
       end

       

      
    end
       p "---------------------------------the end--------------------------------"
   end


end