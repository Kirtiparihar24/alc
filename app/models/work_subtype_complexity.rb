class WorkSubtypeComplexity < ActiveRecord::Base
  belongs_to :work_subtype
  has_many :user_work_subtypes, :dependent => :destroy
  has_many :user_tasks
  accepts_nested_attributes_for :user_work_subtypes, :allow_destroy => true
  after_destroy :update_related_tasks
  #validates_presence_of :stt, :message =>"can not be blank !"
  #validates_presence_of :tat, :message =>"can not be blank !"
  #validates_presence_of :complexity_level, :message =>"can not be blank !"
  #validate :validate_stt_tat_complexity
  private

  # If a worksubtype complexity is removed, then its associated tasks work_subtype_complexity_id is set as nil
  def update_related_tasks
    tasks = self.user_tasks
    if tasks.present?
      UserTask.update_all({:work_subtype_complexity_id => nil}, {:id => tasks.map(&:id)})
    end
  end
end

# == Schema Information
#
# Table name: work_subtype_complexities
#
#  id               :integer         not null, primary key
#  work_subtype_id  :integer
#  complexity_level :integer
#  stt              :integer
#  tat              :integer
#  created_at       :datetime
#  updated_at       :datetime
#

