class MatterClientTaskDetail < ActiveRecord::Base
  belongs_to :matter_task
  attr_reader :TASK_TYPES
  TASK_TYPES = [
    ["---Select Type---",""],
    ["Hearing","Hearing"],
    ["Meeting","Meeting"],
    ["Document Submission","Document Submission"],
    ["Other Task","Other Task"],
    ["Other Appointment","Other Appointment"]
  ]

  def get_from_time
    unless self.from_time.nil?
      self.from_time.strftime("%I:%M %p")
    end
  end

  def get_to_time
    unless self.to_time.nil?
      self.strftime("%I:%M %p")
    end
  end
end
