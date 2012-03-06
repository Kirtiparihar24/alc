require 'rubygems'
require 'active_record'
require 'dbi'
require 'digest/sha1'
ActiveRecord::Base.establish_connection(
    :adapter  => "postgresql",
    :host  => '184.106.143.213',
    :username => "livia",
    :password => "livia",
    :database => "cas_production"
  )
  database = ActiveRecord::Base.connection
  users = []
  res=ActiveRecord::Base.connection.execute("select * from users")
  res.each do |row|
    users << row
  end  
  for user in users
    encrypted_password = Digest::SHA256.hexdigest("#{user['password_salt']}::#{'L!vi@2010'}")
    column_value_pair=database.quote_column_name('encrypted_password') + ' = ' + database.quote(encrypted_password)
    database.execute("UPDATE users SET #{column_value_pair} WHERE ID = #{user['id'].to_i}")
  end
  ActiveRecord::Base.remove_connection 
  p "cas server users updated successfully!!!"
  
