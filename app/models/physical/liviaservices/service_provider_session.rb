class Physical::Liviaservices::ServiceProviderSession < ActiveRecord::Base

  belongs_to :service_provider, :class_name => "ServiceProvider", :foreign_key => "provider_id"

end

# == Schema Information
#
# Table name: service_provider_sessions
#
#  id                   :integer         not null, primary key
#  created_at           :datetime        not null
#  updated_at           :datetime
#  service_provider_id  :integer
#  session_start        :datetime
#  session_end          :datetime
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#

