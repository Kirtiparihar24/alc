class Wfm::SecretariesController < WfmApplicationController
  before_filter :authenticate_user!, :get_default_data
  before_filter :get_alert_task_counts, :get_user_notifications

  layout 'wfm'
  
  def lawyer_list
    @employees = []
    if params[:search].present?
      @employees = Employee.get_employees(params)
    end
  end

end