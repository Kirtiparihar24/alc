class CampaignMail < ActiveRecord::Base
  has_many :document_homes, :as => :mapable
  belongs_to :campaign, :class_name => "Campaign"
end

# == Schema Information
#
# Table name: campaign_mails
#
#  id                   :integer         not null, primary key
#  created_at           :datetime        not null
#  updated_at           :datetime
#  created_by_user_id   :integer
#  deleted              :boolean         default(FALSE)
#  campaign_id          :integer
#  content              :text
#  subject              :text
#  signature            :text
#  mail_type            :text
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  updated_by_user_id   :integer
#

