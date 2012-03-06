class Physical::Liviaservices::ServiceProviderEmployeeMappings < ActiveRecord::Base
  belongs_to :service_provider
  belongs_to :user, :foreign_key =>'employee_user_id'
  has_many :skills, :class_name=>'Physical::Liviaservices::ServiceProviderSkill' ,:foreign_key =>'service_provider_id'
  # has_many side of sessions is left out intentionally for the performance reasons
  named_scope :named,  :conditions => ["status = '1'"]
  validates_uniqueness_of :service_provider_id,:scope=>[:employee_user_id]
  acts_as_paranoid #for soft delete
  after_commit :update_MsSQL_server_data if RAILS_ENV='development'


  def receiver_name
    self.user.try(:full_name)
  end

  def self.update_priority_set(record)
    split = record.split('-')
    livian_id = split.first.to_i
    employee_user_id = split[1].to_i
    priority_lvalue = split.last.to_i
    mapping = self.find_by_employee_user_id_and_service_provider_id(employee_user_id,livian_id)
    priority_lvalue = nil if priority_lvalue == 0
    mapping.update_attributes(:priority => priority_lvalue) unless mapping.nil?
  end

  # Updates MsSQL server database used for telephonic integration
  def update_MsSQL_server_data
    begin
      ActiveRecord::Base.establish_connection(:sqlserver)
      database = ActiveRecord::Base.connection
      res =  database.execute("SELECT * FROM ServiceProviderEmployeeMappings where ID=#{self.id}")

      if res != 0
        column_value_pairs = ''
        column_value_pairs += (database.quote_column_name('ServiceProvidersID') + ' = ' + database.quote(self.service_provider_id) + ",")
        column_value_pairs += (database.quote_column_name('EmployeeUserID') + ' = ' + database.quote(self.employee_user_id) + ",")
        column_value_pairs += (database.quote_column_name('Status') + ' = ' + database.quote(self.status) + ",")
        column_value_pairs += (database.quote_column_name('Priority') + ' = ' + database.quote(self.priority) + ",")
        column_value_pairs += (database.quote_column_name('DeletedAt') + ' = ' + database.quote(self.deleted_at) + ",")
        column_value_pairs += (database.quote_column_name('CreatedAt') + ' = ' + database.quote(self.created_at) + ",")
        column_value_pairs += (database.quote_column_name('UpdatedAt') + ' = ' + database.quote(self.updated_at) + ",")
        column_value_pairs += (database.quote_column_name('PermanentDeletedAt') + ' = ' + database.quote(self.permanent_deleted_at) + ",")
        column_value_pairs += (database.quote_column_name('CreatedByUserID') + ' = ' + database.quote(self.created_by_user_id) )
        database.execute("UPDATE ServiceProviderEmployeeMappings SET #{column_value_pairs} WHERE ID = #{self.id}")
      else

        column_names=['ID','ServiceProvidersID','EmployeeUserID','Status','Priority','DeletedAt','CreatedAt','UpdatedAt',
          'PermanentDeletedAt','CreatedByUserID'].map { |name| database.quote_column_name(name) }.join(",")
        dd = self.deleted_at.to_datetime unless self.deleted_at.nil?
        cd = self.created_at.to_datetime unless self.created_at.nil?
        ud = self.updated_at.to_datetime unless self.updated_at.nil?
        pd = self.permant_deleted_at.to_datetime unless self.permanent_deleted_at.nil?
        values = [self.id,self.service_provider_id,self.employee_user_id,self.status,self.priority,dd,cd,ud,
          dd,self.created_by_user_id].map { |value| database.quote(value) }.join(",")
        database.execute("INSERT INTO %s(%s) VALUES (%s);" % [:ServiceProviderEmployeeMappings, column_names, values])
      end

    rescue
    end
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.establish_connection(RAILS_ENV)
  end

end
# == Schema Information
#
# Table name: service_provider_employee_mappings
#
#  id                   :integer         not null, primary key
#  service_provider_id  :integer         not null
#  employee_user_id     :integer         not null
#  status               :integer
#  deleted_at           :datetime
#  created_at           :datetime
#  updated_at           :datetime
#  permanent_deleted_at :datetime
#  created_by_user_id   :integer
#  priority             :integer
#

