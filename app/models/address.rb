class Address < ActiveRecord::Base
  belongs_to :contact
  belongs_to :campaign_member
  belongs_to :account
  before_save :set_company_id
  liquid_methods :city, :street, :city, :state, :zipcode, :country
  acts_as_paranoid

  def set_company_id
    self.company_id=self.account.company_id if self.account
    self.company_id=self.contact.company_id if self.contact
  end
  
end
# == Schema Information
#
# Table name: addresses
#
#  id                   :integer         not null, primary key
#  street               :string(255)
#  city                 :string(255)
#  country              :string(255)
#  zipcode              :string(255)
#  state                :string(255)
#  address_type         :string(255)
#  contact_id           :integer
#  account_id           :integer
#  created_at           :datetime
#  updated_at           :datetime
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#

