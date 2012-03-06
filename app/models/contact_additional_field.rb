class ContactAdditionalField < ActiveRecord::Base
  belongs_to :contact
  delegate :company_id, :to => :contact
  acts_as_paranoid
  #validates_format_of :supervisors_phone_number, :with => /^[+\/\-() 0-9]+$/,  :message => :supervisors_phone_error,:allow_blank => true
  #validates_format_of :assistants_phone, :with => /^[+\/\-() 0-9]+$/,  :message => :assistants_phone_error,:allow_blank => true
  validate :same_phone_contact_additional
  #validates_format_of :business_fax, :with => /^[+\/\-() 0-9]+$/,  :message => :fax_error,:allow_nil => true,:allow_blank => true
  #validates_format_of :business_phone, :with => /^[+\/\-() 0-9]+$/,  :message => :business_phone_error,:allow_nil => true,:allow_blank => true
  #validates_format_of :businessphone2, :with => /^[+\/\-() 0-9]+$/,  :message => :businessphone2_error,:allow_nil => true,:allow_blank => true
  validate :validate_callback_date_and_first_deal_date
  validates_length_of :business_fax, :maximum=>15,:allow_nil => true
  validates_length_of :business_phone, :maximum=>15,:allow_nil => true
  validates_length_of :businessphone2, :maximum=>15,:allow_nil => true
  def same_phone_contact_additional
    if !self.business_phone.blank? and !self.businessphone2.blank?
      errors.add(:business_phone, :same_phone) if self.business_phone.eql?(self.businessphone2)
    end
    if !self.supervisors_phone_number.blank? and !self.assistants_phone.blank?
      errors.add(:business_phone, :supervisor_phone_same) if self.supervisors_phone_number.eql?(self.assistants_phone)
    end
  end

  def validate_callback_date_and_first_deal_date
    self.errors.add(:first_contact,:next_callback_date) if self.first_contact && self.next_call_back_date &&  self.next_call_back_date.to_date < self.first_contact.to_date
    self.errors.add(:date_of_first_deal,:date_of_first_deal) if self.first_contact && self.date_of_first_deal &&  self.date_of_first_deal.to_date < self.first_contact.to_date
  end

end

# == Schema Information
#
# Table name: contact_additional_fields
#
#  id                       :integer         not null, primary key
#  business_street          :string(64)
#  business_city            :string(64)
#  business_state           :string(64)
#  business_country         :string(64)
#  business_postal_code     :string(64)
#  business_fax             :string(32)
#  business_phone           :string(32)
#  businessphone2           :string(32)
#  assistants_name          :string(64)
#  assistants_phone         :string(32)
#  professional_expertise   :string(64)
#  partners_name            :string(64)
#  partners_birthday        :datetime
#  undergraduate_schools    :string(64)
#  graduate_school          :string(64)
#  year_graduated           :integer
#  graduate_degree          :string(64)
#  supervisors_title        :string(64)
#  supervisors_email        :string(64)
#  supervisors_phone_number :string(32)
#  religion                 :string(64)
#  birthday                 :datetime
#  birth_country            :string(64)
#  children                 :string(64)
#  gender                   :string(32)
#  hobby                    :string(64)
#  first_contact            :datetime
#  date_of_first_deal       :datetime
#  current_service_provider :string(64)
#  next_call_back_date      :datetime
#  referred_by              :string(64)
#  spouse_name              :string(64)
#  spouse_birthday          :datetime
#  linked_in_account        :string(64)
#  twitter_account          :string(64)
#  facebook_account         :string(64)
#  association_1            :string(64)
#  association_2            :string(64)
#  contact_id               :integer
#  company_id               :integer         not null
#  permanent_deleted_at     :datetime
#  created_by_user_id       :integer
#  updated_by_user_id       :integer
#  deleted_at               :datetime
#  created_at               :datetime
#  updated_at               :datetime
#  skype_account            :string(64)
#  business_phone1_type     :integer
#  business_phone2_type     :integer
#  others_1                 :string(255)
#  others_2                 :string(255)
#  others_3                 :string(255)
#  others_4                 :string(255)
#  others_5                 :string(255)
#  others_6                 :string(255)
#

