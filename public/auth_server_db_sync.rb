require 'rubygems'
require 'active_record'
require 'dbi'
begin
  livia_portal_users,auth_server_users,helpdesk_users,ces_users= [],[],[],[]
  #1. collecting livia portal users ----------------------------------------------
  ActiveRecord::Base.establish_connection(
    :adapter  => "postgresql",
    :host  => '184.106.143.213',
    :username => "postgres",
    :password => "",
    :database => "livia_portal_test"
  )
#  res=ActiveRecord::Base.connection.execute("select * from users")
#  res.each do |row|
#    livia_portal_users << row
#  end
#  p "::::::::::::::: livia portal users"
#  p livia_portal_users.size
  livia_portal_users_email= []
#  for lp_user in livia_portal_users
#    livia_portal_users_email << lp_user["email"]
#  end

  #2. collecting helpdesk users --------------------------------------------------

  res=ActiveRecord::Base.connection.execute("select * from helpdesk.users")
  res.each do |row|
    helpdesk_users << row
  end
  p "::::::::::::::: helpdesk users"
  p helpdesk_users

  #3. collecting users from all client applications
  client_app_users = livia_portal_users
  for h_user in helpdesk_users
   client_app_users << h_user unless livia_portal_users_email.include? h_user["email"]
  end
  p "::::::::::::::: client applications users"
  p client_app_users.size

#
#  #4. updating cas server users
#  ActiveRecord::Base.establish_connection(
#    :adapter  => "postgresql",
#    :host  => '184.106.143.213',
#    :username => "livia",
#    :password => "livia",
#    :database => "cas_production"
#  )
#
#  res=ActiveRecord::Base.connection.execute("select * from users")
#  res.each do |row|
#    auth_server_users << row
#  end
#  p "::::::::::::::: auth server users"
#  p auth_server_users.size
#  auth_server_users_email= []
#  for as_user in auth_server_users
#    auth_server_users_email << as_user["email"]
#  end
#  database = ActiveRecord::Base.connection
#  for ca_user in client_app_users
#    if auth_server_users_email.include?(ca_user["email"])
#      as_user = auth_server_users.pop {|u| u["email"]==ca_user["email"]}
#      column_value_pairs = ''
#      #column_value_pairs += (database.quote_column_name('encrypted_password') + ' = ' + database.quote(ca_user["encrypted_password"]) + ",")
#      column_value_pairs += (database.quote_column_name('single_signon_id') + ' = ' + database.quote(ca_user["single_signon_id"]))
#      database.execute("UPDATE users SET #{column_value_pairs} WHERE ID = #{as_user['id'].to_i}")
#    else
#      column_names=res.fields.select {|f| f !="id"}.map { |name| database.quote_column_name(name)}.join(",")
#
#        values = [ca_user["username"] || "",ca_user["email"],ca_user["encrypted_password"],ca_user["password_salt"],
#                  ca_user["deleted_at"],ca_user["created_at"],ca_user["updated_at"],
#                  ca_user["single_signon_id"]].map { |value| database.quote(value) }.join(",")
#        database.execute("INSERT INTO %s(%s) VALUES (%s);" % [:users, column_names, values])
#    end
#  end

rescue Exception => e
  puts "An error occurred"
  puts "Error message: #{e.message}"
ensure
  p "cas server users updated successfully!!!"
  ActiveRecord::Base.remove_connection
end
