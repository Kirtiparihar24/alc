class CompanyReport < ActiveRecord::Base
  serialize :selected_options, Hash
  validates_presence_of :report_name,:message=>:report_name

  named_scope :get_report_fav, lambda {|company,emp_user_id,report_type|
    {:conditions => ["company_id = ? AND employee_user_id = ? AND report_type = ?", company,emp_user_id, report_type]}
  }

  def self.find_favorites(company_id, employee_user_id)
    all(:conditions => ["company_id = ? AND employee_user_id = ?", company_id,employee_user_id])
  end

  def self.find_favorite(id, company_id)
    find(id, :conditions => ["company_id = ?",company_id])
  end

  def self.find_reports_favorites(company_id, employee_user_id, model_name)
    all(:conditions => ["company_id = ? AND employee_user_id = ? AND report_type = ?", company_id, employee_user_id, model_name])
  end

end

# == Schema Information
#
# Table name: company_reports
#
#  id                 :integer         not null, primary key
#  report_type        :string(255)
#  report_name        :string(255)
#  controller_name    :string(255)
#  action_name        :string(255)
#  company_id         :integer
#  employee_user_id   :integer
#  get_records        :string(255)
#  date_selected      :boolean
#  date_start         :date
#  date_end           :date
#  selected_options   :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  created_by_user_id :integer
#  updated_by_user_id :integer
#

