class MatterFact < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :matter
  #default_scope :order => 'matter_facts.created_at DESC'
  has_many  :documents, :as => :documentable, :dependent => :destroy
  has_and_belongs_to_many :matter_issues
  has_and_belongs_to_many :matter_researches
  has_and_belongs_to_many :matter_risks ###Added for the Feature #7512 - Link task risk issue fact - all to all, added by shripad
  has_and_belongs_to_many :matter_tasks ###Added for the Feature #7512 - Link task risk issue fact - all to all, added by shripad
  has_and_belongs_to_many :document_homes
  belongs_to :doc_source
  belongs_to :company
  acts_as_tree
  acts_as_commentable
  validates_presence_of :name
#  validates_uniqueness_of :name, :scope => [:matter_id, :company_id ]
  named_scope :with_order, lambda { |order|
    { :include=>:doc_source,:order=>order }
  }
  
  attr_reader :STATUS
  attr_reader :MATERIAL
  STATUS = [
    "Disputed By Opposition",
    "Disputed By us",
    "Prospective",
    "Undisputed",
    "Not Sure"
  ].sort
  MATERIAL = [
    ["Yes",0],
    ["No",1],
    ["Not Sure",2]
  ]

  SOURCE = [
    "Email",
    "Fax",
    "Letter"
  ]
  
  cattr_reader :per_page
  
  @@per_page=25
  # Returns matter facts which are sub facts of the current fact.
  def sub_facts
    MatterFact.all(:conditions => ["parent_id = ?", self.id])
  end

  # for linking sub modules (risks/ researches/ tasks/ issues) - Supriya/ Mandeep
  def link_submodule(params, submodule)
    params[:matter_fact] ||= {}
    params[:matter_fact][submodule] ||= []
    self.update_attributes(params[:matter_fact])
  end

end
# == Schema Information
#
# Table name: matter_facts
#
#  id                   :integer         not null, primary key
#  name                 :text
#  parent_id            :integer
#  details              :text
#  source               :string(255)
#  material             :integer
#  matter_id            :integer
#  created_at           :datetime
#  updated_at           :datetime
#  status_id            :integer
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  created_by_user_id   :integer
#  updated_by_user_id   :integer
#  doc_source_id        :integer
#

