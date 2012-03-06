class Physical::Liviaservices::SkillType < Lookup

  def <=>(o)
    self.prompt <=> o.prompt
  end
end
 

# == Schema Information
#
# Table name: lookups
#
#  id                   :integer         not null, primary key
#  type                 :string(255)
#  lvalue               :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#

