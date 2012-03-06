class Category < ActiveRecord::Base
  has_many :work_types, :dependent => :destroy
  has_and_belongs_to_many :roles
  validates_presence_of :name
  validates_uniqueness_of :name

  def self.find_with_complexity(has_complexity)
    all(:conditions => ["has_complexity = ?", has_complexity])
  end
  
end

# == Schema Information
#
# Table name: categories
#
#  id             :integer         not null, primary key
#  name           :string(255)
#  description    :text
#  created_at     :datetime
#  updated_at     :datetime
#  has_complexity :boolean         default(FALSE)
#

