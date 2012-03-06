class MatterRisk < ActiveRecord::Base
  belongs_to :matter
  belongs_to :matter_people ,:foreign_key => :assigned_to_matter_people_id
  #default_scope :order => 'matter_risks.created_at DESC'
  has_and_belongs_to_many :matter_issues
  has_and_belongs_to_many :matter_researches
  has_and_belongs_to_many :matter_tasks ###Added for the Feature #7512 - Link task risk issue fact - all to all, added by shripad
  has_and_belongs_to_many :matter_facts ###Added for the Feature #7512 - Link task risk issue fact - all to all, added by shripad
  has_and_belongs_to_many :document_homes
  acts_as_commentable
  acts_as_paranoid
  validates_presence_of :name,  :message => :name_blank

#  validates_uniqueness_of :name, :scope => [:matter_id, :company_id ]
  named_scope :with_order, lambda { |order|
    { :order=> order }
  }
  cattr_reader :per_page
  @@per_page=25
  # for linking sub modules (risks/ researches/ tasks/ issues) - Supriya/ Mandeep
  def link_submodule(params, submodule)
    params[:matter_risk] ||= {}
    params[:matter_risk][submodule] ||= []
    self.update_attributes(params[:matter_risk])
  end

end

# == Schema Information
#
# Table name: matter_risks
#
#  id                   :integer         not null, primary key
#  name                 :text
#  details              :text
#  is_material          :boolean
#  matter_id            :integer
#  created_at           :datetime
#  updated_at           :datetime
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  created_by_user_id   :integer
#  updated_by_user_id   :integer
#

