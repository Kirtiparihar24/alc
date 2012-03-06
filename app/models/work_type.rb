class WorkType < ActiveRecord::Base
  belongs_to :category
  has_many :work_subtypes, :dependent => :destroy
  #TODO Remove this amar
  #has_many :users, :through => :user_work_subtypes
  validates_presence_of :name
  validates_presence_of :category_id

  def self.livian_work_types
    all :include => :category, :conditions => ["categories.has_complexity=false"]
  end

  def self.back_office_work_types
    all :include => :category, :conditions=>["categories.has_complexity=true"]
  end
end

# == Schema Information
#
# Table name: work_types
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  description :text
#  category_id :integer
#  created_at  :datetime
#  updated_at  :datetime
#

