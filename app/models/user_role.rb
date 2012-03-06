# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

class UserRole < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
  acts_as_paranoid

  after_commit   :update_MsSQL_server_data if RAILS_ENV == 'development'

   # Updates MsSQL server database used for telephonic integration
  def update_MsSQL_server_data
    begin
      ActiveRecord::Base.establish_connection(:sqlserver)
      database = ActiveRecord::Base.connection
      res =  database.execute("SELECT * FROM Role where ID=#{self.id}")

      if res != 0
        column_value_pairs = ''
        column_value_pairs += (database.quote_column_name('UserID') + ' = ' + database.quote(self.user_id) + ",")
        column_value_pairs += (database.quote_column_name('RoleID') + ' = ' + database.quote(self.role_id))

        database.execute("UPDATE Role SET #{column_value_pairs} WHERE ID = #{self.id}")
      else

        column_names=['ID','UserID','RoleID'].map { |name| database.quote_column_name(name) }.join(",")

        values = [self.id,self.user_id,self.role_id].map { |value| database.quote(value) }.join(",")
        database.execute("INSERT INTO %s(%s) VALUES (%s);" % [:Role, column_names, values])

      end

    rescue
    end
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.establish_connection(RAILS_ENV)
  end

  def self.assign_user_role(role_id)
    all(:include => [:employee, :service_provider], :conditions => ["user_roles.role_id = ?", role_id])
  end

end

# == Schema Information
#
# Table name: user_roles
#
#  id         :integer         not null, primary key
#  user_id    :integer         not null
#  role_id    :integer         not null
#  created_at :datetime
#  updated_at :datetime
#  deleted_at :datetime
#

