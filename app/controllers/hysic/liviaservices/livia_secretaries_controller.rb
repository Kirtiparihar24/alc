class Physical::Liviaservices::LiviaSecretariesController < ApplicationController
  before_filter :authenticate_user!
  skip_before_filter :check_if_changed_password  # added by kalpit patel 09/05/11
  
  layout 'admin'

  def index
    create_sessions(current_user.role.name,current_user) if session[:sp_session].nil?
    update_session
    if APP_URLS[:use_helpdesk] && session[:helpdesk]
      logout_from_helpdesk(ENV["HOST_NAME"] + '/physical/liviaservices/livia_secretaries')
    else
      if !is_secretary? && !is_team_manager
        raise CanCan::AccessDenied.new("Access Denied.")
      end
      if session[:service_session]
        @svc_sesion = current_service_session
        @svc_sesion.session_end = Time.zone.now
        @svc_sesion.save!
        session[:service_session] = nil
        session[:verified_lawyer_id] = nil
        session[:verified_secretary_id] = nil
        flash[:notice]= t(:flash_logged_out_lawyer)
      end
      if !params[:service_provider_id].nil? and !params[:employee_id].nil?
        check_lawyer
      elsif !params[:employee_id].nil?
        assign_lawyer
      else
        redirect_to wfm_notes_path
      end
    end
  end

  def search_lawyer
    unless current_user.service_provider.service_provider_employee_mappings.length == 0
      q = "%#{params[:q]}%"
      @searched_lawyers = current_user.service_provider.service_provider_employee_mappings      
      @ret=[]
      @searched_lawyers.each do|assign|
        law = assign.user.employee
        if law.full_name.upcase.index(params[:q].upcase) != nil
          @ret << assign
        end
      end
      unless q.blank?
        @searched_lawyers = @ret
      end
    end
    render :partial=> 'searched_lawyers_autocomplete'
  end

  def get_next_task
    # Get service provider
    sp = current_user.service_provider
    @task = sp.get_next_task
    if @task
      @task.assigned_to_user_id = sp.user.id
      @task.save!
      flash[:notice] = t(:flash_new_task_from_queue)
    else
      flash[:warning] = t(:warning_task_not_found)
    end
    redirect_to(:action => 'index', :dont_hide_task => true)
  end

  def check_lawyer
    assignment = Physical::Liviaservices::ServiceProviderEmployeeMappings.find(:first, :joins => "INNER JOIN employees ON service_provider_employee_mappings.employee_user_id=employees.user_id",:conditions => ["service_provider_employee_mappings.service_provider_id=? and employees.id=?",params[:service_provider_id],params[:employee_id]])
    sp_session = current_service_provider_session
    service_session = Physical::Liviaservices::ServiceSession.create(:assignment =>assignment,
      :sp_session => sp_session,
      :session_start => Time.now ,
      :company_id => current_user.company_id)
    session[:service_session] = service_session.id
    assignment_user = assignment.user
    lawyer = assignment_user
    lawyer.verified_lawyer
    session[:verified_lawyer_id] = assignment_user.id
    current_user.verified_lawyer_id_by_secretary = assignment_user.id
    redirect_to new_communication_path(:call_id=>params[:call_id])
  end

  # assiging lawyer to livian from central pool when lawyer is verified
  def assign_lawyer
    sp_session = current_service_provider_session
    employee = Employee.find(params[:employee_id],:include=>[:user=>[:service_provider_employee_mappings]])
    service_session = Physical::Liviaservices::ServiceSession.create(:employee_user_id =>employee.user.id,
      :sp_session => sp_session,
      :session_start => Time.now ,
      :company_id => current_user.company_id)
    session[:service_session] = service_session.id
    assignment_user = employee.user
    lawyer = assignment_user
    lawyer.verified_lawyer
    session[:verified_lawyer_id] = assignment_user.id
    current_user.verified_lawyer_id_by_secretary = assignment_user.id
    sp_id= employee.user.nil? ? "" : employee.user.service_provider_employee_mappings.blank? ? "" : employee.user.service_provider_employee_mappings.first.service_provider_id
    redirect_to new_communication_path(:service_provider_id=>sp_id,:call_id=>params[:call_id])
  end
  
  # displaying lawyer list to livian from central pool when lawyer is not verified
  def show_lawyer_list
    authorize!(:show_lawyer_list,current_user) unless current_user.role?:secretary
    #session[:verified_secretary_id1] = params[:service_provider_id]
    if params[:search].nil?
      @employees = Employee.paginate :page => params[:page], :order => 'employees.created_at DESC', :per_page=>20, :include=>[:user=>[:role,:service_provider_employee_mappings]]
    else
      @employees = Employee.get_employees(params)
    end
  end

  def set_service_provider_id_by_telephony   
    session[:verified_secretary_id] = params[:service_provider_id]
    current_user.service_provider_id_by_telephony = session[:verified_secretary_id]
    actual_root = new_communication_url
    actual_root.gsub!('http', 'https') if actual_root.include?('http:') && !actual_root.include?('localhost')
    if request.xhr?
      render :update do |page|
        page.redirect_to actual_root
      end
    else
      redirect_to actual_root
    end
  end

end