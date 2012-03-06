class Physical::Liviaservices::VerificationController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :assignment
  
  def assignment
    @assignment = Physical::Liviaservices::ServiceProviderEmployeeMappings.find_by_employee_user_id(params[:id], :include=>[:user=>:employee])
  end

  def index    
    @sp_session = current_service_provider_session
    @receiver = @assignment.user.employee
    @id = params[:id]
    render :layout=> false
  end

  def verify_lawyer    
    sp_session = current_service_provider_session
    service_session = Physical::Liviaservices::ServiceSession.create(:assignment =>@assignment,
      :sp_session => sp_session,
      :session_start => Time.zone.now ,
      :company_id => current_user.company_id)
    session[:service_session] = service_session.id
    assignment_user = @assignment.user
    lawyer = assignment_user
    lawyer.verified_lawyer
    session[:verified_lawyer_id] = assignment_user.id
    current_user.verified_lawyer_id_by_secretary = assignment_user.id
    # Temporary Fix for https
    actual_root = root_url
    unless actual_root.include?('localhost')
      actual_root.gsub!('http', 'https') if actual_root.include?('http:')
    end    
    redirect_to actual_root + "communications/new"    
  end

end