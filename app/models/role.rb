class Role < ActiveRecord::Base
  has_many :user_roles
  has_many :users, :through => :user_roles
  belongs_to :company
  named_scope :all_wfm ,:conditions => {:for_wfm => true} #used in admin view to show only the roles created from the view and not backend.
  has_and_belongs_to_many :categories

  validates_presence_of :name, :message => "Role can't be blank"

  #It return role object for manager role.
  named_scope :getmanagerrole,lambda{{:joins=>:users,:conditions=>["name = ?","manager"],:limit => 1}}

  attr_accessor :category_list
  after_save :update_categories


  private

  #Assign categories to role
  def update_categories
    categories.delete_all
    self.categories << Category.find(category_list.keys) rescue []
  end 
  

end

# == Schema Information
#
# Table name: roles
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  for_wfm    :boolean         default(FALSE)
#

