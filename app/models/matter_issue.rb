class MatterIssue < ActiveRecord::Base

  include GeneralFunction
  belongs_to :matter
  belongs_to :matter_people ,:foreign_key => :assigned_to_matter_people_id
  #default_scope :order => 'matter_issues.created_at DESC'
  has_many  :documents, :as => :documentable, :dependent => :destroy
  has_and_belongs_to_many :matter_facts
  has_and_belongs_to_many :matter_tasks
  has_and_belongs_to_many :matter_researches
  has_and_belongs_to_many :matter_risks
  has_and_belongs_to_many :document_homes
  acts_as_tree
  acts_as_paranoid
  acts_as_commentable
  before_save :set_active,:responsible_person_changed
  after_save :send_mail_to_associates
  validates_presence_of :name,:message=>:name_blank
  validates_presence_of :assigned_to_matter_people_id,:message=>:assigned_to_blank
  validates_presence_of :target_resolution_date,:message=>:target_resolution_blank
  #  validates_presence_of :resolution, :message=>:name_blank, :if => Proc.new { |matter_issue| matter_issue.resolved }
  validate :check_resolved_at ,:message=> 'date cananot be blank'
#  validates_uniqueness_of :name, :scope => [:matter_id, :company_id ]
  named_scope :with_order, lambda { |order|
    { :order=>order }
  }
  validate :target_resolution_date_cant_be_less_than_matter_inception
  validate :validate_resolved_at_date
  cattr_reader :per_page
  @@per_page=25
  #self.per_page=35
  # Set active to true, used as before_save call back.
  def set_active
    self.active = true if self.active.nil?
  end

  def target_resolution_date_cant_be_less_than_matter_inception
    self.errors.add(:target_resolution_date,:target_resolution_date) if self.target_resolution_date && self.matter[:matter_date] &&  self.target_resolution_date.to_date < self.matter[:matter_date].to_date
  end

  def validate_resolved_at_date
    #self.errors.add(:resolved_at,:resolved_at_target) if self.resolved && self.resolved_at && self.target_resolution_date && self.resolved_at.to_date > self.target_resolution_date.to_date
    #self.errors.add(:resolved_at,:resolved_at_inception) if self.resolved && self.resolved_at && self.matter[:matter_date] && self.resolved_at.to_date < self.matter[:matter_date].to_date
    #self.errors.add(:resolved_at,"sania") if self.resolved && self.resolved_at && self.created_at && self.resolved_at.to_date < self.created_at.to_date

    #    if a new issue is being created---
    if self.created_at.nil?
      self.created_at=Time.now
    end


    if self.resolved && self.resolved_at && self.target_resolution_date && self.resolved_at.to_date > self.target_resolution_date.to_date
      self.errors.add(:resolved_at,:resolved_at_target)
    

      #    if self.resolved && self.resolved_at && self.matter[:matter_date] && self.resolved_at.to_date < self.matter[:matter_date].to_date
      #      self.errors.add(:resolved_at,:resolved_at_inception)
      #    end

    elsif self.resolved && self.resolved_at && self.created_at && self.resolved_at.to_date < self.created_at.to_date
      self.errors.add(:resolved_at,:resolved_at_issue)
    end
  end

  # Check resolved at field, it is mandatory if resolved is true.
  # Used as a validator.
  def check_resolved_at
    self.errors.add('Resolved at', 'can\'t be blank') if (self.resolved && self.resolved_at.blank?)
  end
  
  def self.accessible_matter_tasks(allowed_ids)
    self.scoped_by_user_id(allowed_ids).all
  end



  # Return resolved, with yes/no and date of resolution.
  def get_resolved(date)
    y = self.resolved ? "Yes" : "No"
    (date && self.resolved) ? "#{y} (#{date})" : "#{y}"
  end

  # Returns name of matter people whom this issue is assigned.
  def assigned_to_name
    unless self.assigned_to_matter_people_id.nil?
      MatterPeople.find_with_deleted(self.assigned_to_matter_people_id).get_name
    end
  end

  # Returns list of sub issues.
  def sub_issues
    MatterIssue.all(:conditions => ["parent_id = ?", self.id])
  end

  # Returns all active issues.
  def self.all_active
    MatterIssue.all(:conditions => {:active => true})
  end
  
  # Returns counts of disputed and undisputed facts linked to this issue.
  def matter_status_count
    undisputed=self.matter_facts.collect{|mf| mf.status_id if mf.status_id == CompanyLookup.find_by_lvalue_and_company_id('Undisputed', mf.company_id).id}.compact.size
    disputed=self.matter_facts.collect{|mf| mf.status_id if mf.status_id == CompanyLookup.find_by_lvalue_and_company_id('Disputed By Opposition', mf.company_id).id}.compact.size

    [undisputed,disputed]
  end

  #Send Mail to Matter_issue Associates
  def send_mail_to_associates
    unless self.matter_people.blank?
      user = self.matter_people.assignee
      if(@is_changed && user && User.current_user!=user)
        send_notification_to_responsible(user,self,User.current_user)
        @is_changed = false

        true
      end
    end
  end

  private

  def responsible_person_changed
    @is_changed = self.changed.include?("assigned_to_matter_people_id")
    true
  end
end

# == Schema Information
#
# Table name: matter_issues
#
#  id                           :integer         not null, primary key
#  name                         :text
#  parent_id                    :integer
#  is_primary                   :boolean
#  is_key_issue                 :boolean
#  description                  :text
#  target_resolution_date       :date
#  assigned_to_matter_people_id :integer
#  matter_id                    :integer
#  created_at                   :datetime
#  updated_at                   :datetime
#  resolved                     :boolean
#  resolution                   :text
#  active                       :boolean
#  client_issue                 :boolean
#  resolved_at                  :date
#  company_id                   :integer         not null
#  deleted_at                   :datetime
#  permanent_deleted_at         :datetime
#  created_by_user_id           :integer
#  updated_by_user_id           :integer
#

