class WorkSubtype < ActiveRecord::Base
  belongs_to :work_type
  has_many :work_subtype_complexities, :dependent => :destroy, :order => 'complexity_level'
  has_many :user_work_subtypes, :dependent => :destroy
  has_many :user_tasks
  validates_presence_of :name, :message =>"can not be blank !"
  validates_presence_of :work_type_id, :message =>"can not be blank !"
   attr_accessor :stt, :tat, :complexity_level
  #validate :validate_stt_tat_complexity

  after_update :save_work_subtype_complexities
  after_destroy :update_related_tasks

  def new_work_subtype_complexity_attributes=(work_subtype_complexity_attributes)
    work_subtype_complexity_attributes.each do |attributes|
      work_subtype_complexities.build(attributes)
    end
  end


  def existing_work_subtype_complexity_attributes=(work_subtype_complexity_attributes)
    work_subtype_complexities.reject(&:new_record?).each do |work_subtype_complexity|
      attributes = work_subtype_complexity_attributes[work_subtype_complexity.id.to_s]
      if attributes
        work_subtype_complexity.attributes = attributes
      else
        work_subtype_complexities.delete(work_subtype_complexity)
      end
    end
  end

  def save_work_subtype_complexities
    work_subtype_complexities.each do |work_subtype_complexity|
      work_subtype_complexity.save(false)
    end
  end

  def validate_stt_tat_complexity
    
    self.errors.add(:stt,"can not be blank !") if self.stt.blank?
    self.errors.add(:tat,"can not be blank !") if self.tat.blank?
    self.errors.add(:complexity_level,"can not be blank !") if self.complexity_level.blank?
  end

  def self.front_office_work_subtypes
    find_by_sql("select ws.* from work_subtypes as ws join work_types as wt on ws.work_type_id = wt.id join categories as c on wt.category_id = c.id where c.has_complexity = false")
  end

  def self.back_office_work_subtypes
    find_by_sql("select ws.* from work_subtypes as ws join work_types as wt on ws.work_type_id = wt.id join categories as c on wt.category_id = c.id where c.has_complexity = true")
  end

  def back_office_skill?
    self.work_type.category.has_complexity
  end

  private
  # If a worksubtype is removed, then its associated tasks work_subtype_id and work_subtype_complexity_id is set as nil
  def update_related_tasks
    tasks = self.user_tasks
    if tasks.present?
      UserTask.update_all({:work_subtype_id=>nil},{:id=>tasks.map(&:id)})
    end
  end
  
end

# == Schema Information
#
# Table name: work_subtypes
#
#  id           :integer         not null, primary key
#  name         :string(255)
#  description  :text
#  work_type_id :integer
#  created_at   :datetime
#  updated_at   :datetime
#

