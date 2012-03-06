class Folder < ActiveRecord::Base
  has_many :files, :class_name=>'DocumentHome', :foreign_key =>:folder_id, :dependent => :destroy
  has_many :links, :class_name=>'Link', :foreign_key =>:folder_id, :dependent => :destroy
  belongs_to :company
  belongs_to :user, :foreign_key => :employee_user_id
  belongs_to :matter
  belongs_to  :workspace, :foreign_key =>'created_by_user_id', :class_name => 'Workspace'
  belongs_to  :repository, :foreign_key =>'created_by_user_id', :class_name => 'Repository'
  default_scope :order => "name ASC" 
  acts_as_tree_with_dotted_ids :order => "name"
  validates_presence_of :name, :message =>"name_blank"
  validates_length_of :name, :within => 1..256, :message => "is too long it should not exceed 256 characters." , :unless => "name.blank?"
  validates_uniqueness_of :name, :scope => [:mapable_type, :mapable_id, :parent_id], :case_sensitive => false
  acts_as_paranoid #for soft delete
  named_scope :repository_root_folders, {:conditions => ['parent_id is null']}
end
# == Schema Information
#
# Table name: folders
#
#  id                   :integer         not null, primary key
#  name                 :string(255)
#  company_id           :integer         not null
#  parent_id            :integer
#  deleted_at           :datetime
#  created_by_user_id   :integer
#  employee_user_id     :integer
#  updated_by_user_id   :integer
#  permanent_deleted_at :datetime
#  created_at           :datetime
#  updated_at           :datetime
#  dotted_ids           :text
#  livian_access        :boolean
#  for_workspace        :boolean