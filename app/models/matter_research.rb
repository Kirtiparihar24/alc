class MatterResearch < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :matter
  has_many  :documents, :as => :documentable, :dependent => :destroy
  has_and_belongs_to_many :matter_issues
  has_and_belongs_to_many :matter_facts
  has_and_belongs_to_many :matter_risks
  has_and_belongs_to_many :matter_tasks
  has_and_belongs_to_many :document_homes
#  validates_uniqueness_of :name, :scope => [:matter_id, :company_id ]
  belongs_to :researchable_type,:foreign_key => :research_type,:class_name=>'ResearchType'
  belongs_to :company
  acts_as_commentable
  acts_as_tree  
  #default_scope :order => 'matter_researches.created_at DESC'
  validates_presence_of :name,  :message => :name_blank

  named_scope :with_order, lambda { |order|
    { :order=>order }
  }
  cattr_reader :per_page
  @@per_page=25
  #before_save :format_name
  # Format name, capitalize initial letter of each word in the name.
  attr_reader :TYPES
  TYPES = [
    "Admin Ruling",
    "Article",
    "Background Authority",
    "Case Law",
    "Other Authority",
    "Regulation",
    "Rule",
    "Statute"
  ].sort

  # Returns sub researches.
  def sub_researches
    MatterResearch.all(:conditions => ["parent_id = ?", self.id])
  end

  # for linking sub modules (risks/ facts/ tasks/ issues) - Supriya/ Mandeep
  def link_submodule(params, submodule)
    params[:matter_research] ||= {}
    params[:matter_research][submodule] ||= []
    self.update_attributes(params[:matter_research])
  end

end

# == Schema Information
#
# Table name: matter_researches
#
#  id                   :integer         not null, primary key
#  name                 :text
#  parent_id            :integer
#  research_type        :integer
#  citation             :string(255)
#  description          :text
#  matter_id            :integer
#  created_at           :datetime
#  updated_at           :datetime
#  is_internal          :boolean
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  created_by_user_id   :integer
#  updated_by_user_id   :integer
#

