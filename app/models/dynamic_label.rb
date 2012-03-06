class DynamicLabel< ActiveRecord::Base
belongs_to :company
 # TODO This model is not required following code can be put into after create company lookup

 after_create :create_i18n_for_redis
 after_update :update_redis_company

 def create_i18n_for_redis
   DynamicI18n.add_company(self.company_id,self.file_name)
   DynamicI18n.clone_master_data_for_company(self.file_name)
 end

 def update_redis_company
   DynamicI18n.add_company(self.company_id,self.file_name)
   DynamicI18n.clone_master_data_for_company(self.file_name) if DynamicI18n.find_all("#{self.file_name}.*").blank?  

 end
end

# == Schema Information
#
# Table name: dynamic_labels
#
#  id         :integer         not null, primary key
#  company_id :integer
#  file_name  :string(255)
#

