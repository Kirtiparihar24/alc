class Physical::Timeandexpenses::ExpenseType  < CompanyLookup
  belongs_to :company
  validates_presence_of :alvalue ,:message =>"Expense Type cannot be blank"
  has_many :time_expenses,:class_name => 'Physical::Timeandexpenses::ExpenseEntry',:foreign_key => 'expense_type'
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

