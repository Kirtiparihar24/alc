class DefaultQuestion < CompanyLookup
  belongs_to :user

  def self.get_default_questions
    all(:conditions => ['type = ?', 'DefaultQuestion'])
  end

  def validate
    self.errors.add_to_base("Question can't be blank") if self.lvalue.blank?
    self.errors.add_to_base("Answer can't be blank") if self.alvalue.blank?
  end
  
end

# == Schema Information
#
# Table name: company_lookups
#
#  id                   :integer         not null, primary key
#  type                 :string(255)
#  lvalue               :string(255)
#  company_id           :integer         default(1)
#  created_at           :datetime
#  updated_at           :datetime
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  alvalue              :string(255)
#  category_id          :integer
#  sequence             :integer         default(0)
#

