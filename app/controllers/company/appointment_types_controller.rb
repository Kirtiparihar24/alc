class Company::AppointmentTypesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('appointment_types')",:only=>:index
  layout "admin"

  def index
    @appointment_types = @company.appointment_types
  end

  def new
    @appointment_type = @company.appointment_types.new
    render :layout => false
  end

  def create
    appointment_types = @company.appointment_types
    appointment_typescount = appointment_types.count
    if appointment_typescount > 0
      params[:appointment_type][:sequence] = appointment_typescount+1
    end
    @appointment_type = AppointmentType.new(params[:appointment_type].merge(:lvalue=>params[:appointment_type][:alvalue]))
    if @appointment_type.valid? && @appointment_type.errors.empty?
      appointment_types << @appointment_type      
    end
    render :update do |page|
      unless !@appointment_type.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice',"Appointment Type was successfully created")

        page<<"window.location.href='#{manage_company_utilities_path('appointment_types',:linkage=>"matter_tasks")}';"
      else
        page.call('show_msg','nameerror',@appointment_type.errors.on(:alvalue))
      end
    end
  end

  def edit
    @appointment_type = Company::AppointmentType.find(params[:id])
    render :layout=>false
  end

  def update
    @appointment_type = AppointmentType.find(params[:id])
    @appointment_type.attributes = params[:appointment_type].merge(:lvalue=>params[:appointment_type][:alvalue])
    if @appointment_type.valid? && @appointment_type.errors.empty?
      @appointment_type.save
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@appointment_type.errors.empty?           
            active_deactive = find_model_class_data('appointment_types')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'appointment_types', :header=>"Appointment Type", :modelclass=> 'appointment_types'})
            page<< 'tb_remove();'            
            page<<"window.location.href='#{manage_company_utilities_path('appointment_types',:linkage=>"matter_tasks")}';"
            page.call('common_flash_message_name_notice',"Appointment Type was successfully updated")
          else
            page.call('show_msg','nameerror',@appointment_type.errors.on(:alvalue))
          end
        end
      }
    end
  end

  def show
    @appointment_type = @company.appointment_types.find_only_deleted(params[:id])
    unless @appointment_type.blank?
      @appointment_type.update_attribute(:deleted_at, nil)
      set_sequence_for_lookups(@company.appointment_types)
    end
    respond_to do |format|
      flash[:notice] = "Appointment Type '#{@appointment_type.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('appointment_types',:linkage=>"matter_tasks")) }
      format.xml  { head :ok }
    end
  end

  def destroy
    appointment_types = @company.appointment_types.find(params[:id])
    matter_task_length = appointment_types.matter_tasks.length
    message = false
    if matter_task_length > 0
      message = false
    else
      message = true if appointment_types.destroy
      set_sequence_for_lookups(@company.appointment_types)
    end
    respond_to do |format|
      if message
        flash[:notice] = "Appointment Type '#{appointment_types.lvalue}' is successfully deactivated."
      else
        flash[:error] = "Appointment Type '#{appointment_types.lvalue}' can not be deactivated, #{matter_task_length} matter-task entries linked."
      end
      format.html { redirect_to(manage_company_utilities_path('appointment_types')) }
      format.xml  { head :ok }
    end
  end

end
