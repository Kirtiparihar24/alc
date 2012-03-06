class CompanyActivityType < CompanyLookup
  belongs_to :company
  validates_presence_of :alvalue ,:message=> "company activity type can't be blank"
  has_many :time_entries,:class_name => 'Physical::Timeandexpenses::TimeEntry',:foreign_key => 'activity_type'
  has_many :matter_tasks,  :foreign_key=>:category_type_id
  has_many :employee_activity_rates ,:foreign_key=> :activity_type_id

end