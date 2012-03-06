class CampaignMember < ActiveRecord::Base
  include GeneralFunction
  
  belongs_to :company
  belongs_to :campaign, :class_name => "Campaign"
  belongs_to :contact, :class_name => "Contact"
  belongs_to :status, :class_name => "CampaignMemberStatusType", :foreign_key =>'campaign_member_status_type_id'
  belongs_to :opportunity, :class_name => "Opportunity"
  has_one    :address, :dependent => :destroy
  validates_presence_of :company_id,:employee_user_id, :created_by_user_id
  validates_presence_of :first_name,:email, :if=>:new_contact?   
  validates_format_of :email,
    :with => /^(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+))*(([A-Za-z0-9])|(\_))+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6}$/,
    :message => :email_format,
    :if => :new_contact?
  #validates_format_of :phone, :with => /^[+\/\-() 0-9]+$/,  :message => :phone_error,:if=>:new_contact?,:allow_nil => true,:allow_blank => true
  #validates_format_of :fax, :with => /^[+\/\-() 0-9]+$/,  :message => :fax_error,:if=>:new_contact?,:allow_nil => true,:allow_blank => true
  validates_format_of :mobile, :with => /\d+/,  :message => :mobile_error,:if=>:new_contact?,:allow_nil => true,:allow_blank => true
  validates_uniqueness_of :first_name, :scope=> [:last_name,:company_id,:email,:campaign_id], :if=>:new_contact?, :case_sensitive => false, :message =>:already_member
  after_save :update_campaign_for_search
  after_destroy :update_campaign_for_search
  acts_as_paranoid
  validate :first_name
  validates_length_of :first_name, :maximum => 60, :message=> "is too long it should not exceed 60 char.", :allow_nil => true, :allow_blank => true
  # used from the "personalization campaign mailer"
  liquid_methods :salutation, :first_name, :middle_name, :last_name, :nickname, :title, :informal_name ,:formal_name
  named_scope :limit_size, :limit => 2500
  #This method is used after_save and after_destroy to update the delta used in sphinx search
  named_scope :get_first_mailed_date, lambda {|campaign_id| {:conditions => ["campaign_id = ?", campaign_id], :select => :first_mailed_date}}

  # Methods for Liquid to be used in Campaign mailers ---
  def formal_name
    salutation = self.company.salutation_types.find_by_id(self.salutation_id).try(:alvalue)
    # ADD SALUTATION please
    return format_full_name(salutation || "", self.first_name,self.middle_name, self.last_name, self.nickname ,"formal")
  end

  def informal_name
    salutation = self.company.salutation_types.find_by_id(self.salutation_id).try(:alvalue)
    return format_full_name(salutation || "", self.first_name, self.middle_name, self.last_name, self.nickname ,"informal")
  end
  
  def salutation
    salutation = self.company.salutation_types.find_by_id(self.salutation_id).try(:alvalue)
    return salutation if salutation
  end
  
  # --- campaign liquid

  def update_campaign_for_search
    unless self.campaign.blank?
      self.campaign.delta = true
      self.campaign.save
    end
  end

  #This method is used before save to check whether the member is a new or an exiting contact and also to set itz respective fields
  
  #This method is used before save to check whether the member is a new or an exiting contact
  def new_contact?
    if self.contact_id == nil
      true
    else
      false
    end
  end

  #This method returns the contact details of a campaign member.This method may or may not be from an existing contact
  def get_contact
    if self.contact_id
      return self.contact
    end
  end

  def contact_email
    if self.contact_id
      self.contact.email
    else
      self.email
    end
  end

  #This method returns the status of the campaign member
  def status    
    CampaignMemberStatusType.try(:find_by_id,self.campaign_member_status_type_id)
  end

  #This method returns the date on which lastemail was sent to the campaign
  def get_last_mailed_date
    if self.reminder_date
      self.reminder_date.strftime('%m/%d/%y')
    elsif self.first_mailed_date
      self.first_mailed_date.strftime('%m/%d/%y')
    else
      nil
    end
  end

  #This method returns the full name (last_name,first_name,middle_name)
  def full_name
    "#{(self.company.salutation_types.find_by_id(self.salutation_id).try(:alvalue)) unless self.salutation_id.blank?} #{(self.last_name + ', ') unless self.last_name.blank?} #{self.first_name} #{(self.middle_name) unless self.middle_name.blank?}"
  end
end

# == Schema Information
#
# Table name: campaign_members
#
#  id                             :integer         not null, primary key
#  created_at                     :datetime
#  updated_at                     :datetime
#  campaign_id                    :integer
#  contact_id                     :integer
#  campaign_member_status_type_id :integer
#  response                       :text
#  first_mailed_date              :date
#  responded_date                 :date
#  reminder_date                  :date
#  opportunity_id                 :integer
#  first_name                     :string(255)
#  last_name                      :string(255)
#  email                          :string(255)
#  phone                          :string(255)
#  mobile                         :string(255)
#  fax                            :string(255)
#  website                        :string(255)
#  title                          :string(255)
#  nickname                       :string(255)
#  employee_user_id               :integer
#  created_by_user_id             :integer
#  company_id                     :integer         not null
#  deleted_at                     :datetime
#  permanent_deleted_at           :datetime
#  updated_by_user_id             :integer
#  bounce_code                    :string(255)
#  bounce_reason                  :text
#  response_token                 :string(255)
#  middle_name                    :string(255)
#

