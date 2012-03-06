module TneInvoicesHelper
  def list_activity_types(company)
    company.company_activity_types.collect{|activity| [activity.alvalue,activity.id] }
  end

  def list_of_expense_activity_type(company)
    company.expense_types.collect{|activity| [activity.alvalue,activity.id] }
  end
end
