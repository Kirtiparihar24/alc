class Company::TaskTypesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('task_types')",:only=>:index

  layout "admin"
  
  def index
    @task_types = @company.task_types
  end

  def new
    @task_type = @company.task_types.new
    render :layout => false
  end

  def create
    task_types = @company.task_types
    task_typescount = task_types.count
    if task_typescount > 0
      params[:task_type][:sequence] = task_typescount+1
    end
    @task_type = TaskType.new(params[:task_type].merge(:lvalue=>params[:task_type][:alvalue]))
    if @task_type.valid? && @task_type.errors.empty?
      task_types << @task_type      
    end
    render :update do |page|
      unless !@task_type.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice',"Task Type was successfully created")

        page<<"window.location.href='#{manage_company_utilities_path('task_types',:linkage =>"matter_tasks")}';"
      else
        page.call('show_msg','nameerror',@task_type.errors.on(:alvalue))
      end
    end
  end

  def edit
    @task_type = Company::TaskType.find(params[:id])
    render :layout=>false
  end

  def update
    @task_type = TaskType.find(params[:id])
    @task_type.attributes = params[:task_type].merge(:lvalue=>params[:task_type][:alvalue])
    if @task_type.valid? && @task_type.errors.empty?
      @task_type.save
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@task_type.errors.empty?           
            active_deactive = find_model_class_data('task_types')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'task_types', :header=>"Task Type", :modelclass=> 'task_types'})
            page<< 'tb_remove();'            
            page<<"window.location.href='#{manage_company_utilities_path('task_types',:linkage =>"matter_tasks")}';"
            page.call('common_flash_message_name_notice',"Task Type was successfully updated")
          else
            page.call('show_msg','nameerror',@task_type.errors.on(:alvalue))
          end
        end
      }
    end
  end
    
  def show
    @task_type = @company.task_types.find_only_deleted(params[:id])
    unless @task_type.blank?
      @task_type.update_attribute(:deleted_at, nil)
      set_sequence_for_lookups(@company.task_types)
    end
    respond_to do |format|
      flash[:notice] = "Task Type '#{@task_type.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('task_types',:linkage =>"matter_tasks")) }
      format.xml  { head :ok }
    end
  end

  def destroy
    task_type = @company.task_types.find(params[:id])
    matter_task_length = task_type.matter_tasks.length
    message = false
    if matter_task_length > 0
      message = false
    else
      message = true if task_type.destroy
      set_sequence_for_lookups(@company.task_types)
    end
    respond_to do |format|
      if message
        flash[:notice] = "Task Type '#{task_type.lvalue}' is successfully deactivated."
      else
        flash[:error] = "Task Type '#{task_type.lvalue}' can not be deactivated, #{matter_task_length} matter-task entries linked."
      end
      format.html { redirect_to(manage_company_utilities_path('task_types')) }
      format.xml  { head :ok }
    end
  end
  
end
