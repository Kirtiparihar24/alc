class Physical::Liviaservices::ServiceProviderSkill < ActiveRecord::Base
  belongs_to :skill, :class_name => "Physical::Liviaservices::SkillType", :foreign_key => "skill_type_id"
  belongs_to :provider, :class_name => "ServiceProvider", :foreign_key => "service_provider_id"
  acts_as_paranoid

  validates_uniqueness_of :skill_type_id, :scope => :service_provider_id

  def skill_name
    self.skill.name
  end
  def to_label
    self.skill.prompt
  end
end

# == Schema Information
#
# Table name: service_provider_skills
#
#  id                   :integer         not null, primary key
#  created_at           :datetime        not null
#  updated_at           :datetime
#  skill_type_id        :integer
#  service_provider_id  :integer         not null
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#

