# Handles the logic for showing a matter view to the client.
include  MatterClientsHelper
class MatterClientsController < ApplicationController
  before_filter :get_matter, :only => [ :matter_task_details, :client_create_doc]
  before_filter :check_access_to_matter, :only => [ :matter_task_details, :client_create_doc]
  before_filter :authenticate_user!
  skip_before_filter :check_if_changed_password

  layout "matter_clients"
  
  def index
    update_session
    company= current_company
    @tasks=[]
    all_tasks=[]
    page = params[:page]
    open = company.matter_statuses.find_by_lvalue("Open")
    completed = company.matter_statuses.find_by_lvalue("Completed")
    @open_matters = Matter.client_accessible(page, get_contact_id,open.id)
    @completed_matters = Matter.client_accessible(page, get_contact_id, completed.id)    
    @all_matters = @open_matters +  @completed_matters    
    @open_matters.each do |open_matter|
      open_matter.client_tasks.each {|ct| @tasks << ct}
    end
    @completed_matters.each do |completed_matter |
      completed_matter.client_tasks.each {|ct| @tasks << ct}
    end
    @datetasks = @tasks.find_all {|e| e.today?}
    all_tasks = @tasks
    @tasks = @tasks.reject{|task| (task.category.eql?('appointment') and task.overdue?)}
    unless all_tasks.blank?
      get_task_and_appointment_series(all_tasks)
      @activities = @task_todo + @task_appt
      tasks = @activities.blank? ? [] : @activities.collect{|task| task[:activity]}
      @activities = @activities.paginate(:per_page => params[:per_page], :page => params[:page])
      @mattertasks = tasks.paginate(:per_page => params[:per_page], :page => params[:page])
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @document_home }
      if params[:matter_id].to_i==0
        format.js {
          render :update do |page|
            page.replace_html 'matter_tasks', :partial => "matter_task"
          end
        }
      end
    end
  end

  # Used for document upload by client.
  def client_new_doc
    data = params
    cid = current_company.id
    @return_path = data[:return_path]
    @return_path = request.headers['HTTP_REFERER'] if @return_path.blank?
    @matter = Matter.scoped_by_company_id(cid).find(params[:id])
    @document_home = DocumentHome.new
    @document = @document_home.documents.build
    @mapable_id = data[:id]
    @mapable_type = 'Matter'
    @task= MatterTask.scoped_by_company_id(cid).find(data[:task_id] ) if data[:task_id]
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @document_home }
    end
  end

  def billings
    @matter=Matter.scoped_by_company_id(get_company_id).find(params[:id])
    @billings =@matter.get_bills
    @payments=@matter.matter_retainers
    render :layout=>false
  end

  # Client uploaded a document, we save it here, no access_rights defined.
  def client_create_doc
    curr_user= current_user
    doc_home_data = params[:document_home]
    @return_path =params[:return_path]
    task = @matter.matter_tasks.find(params[:task_id]) if params[:task_id]
    if task.present?
      euid= @matter.matter_peoples.find(task.assigned_to_matter_people_id).employee_user_id
      doc_home_data[:access_rights] = 4
      doc_home_data[:matter_task_ids]=[ task.id]
      llmpid = @matter.matter_peoples.first(:conditions => ["employee_user_id = ?", @matter.employee_user_id]).id
      doc_home_data[:matter_people_ids] = [task.assigned_to_matter_people_id,llmpid].uniq
    else
      euid= @matter.employee_user_id
      doc_home_data[:access_rights] = 1
      doc_home_data[:user_ids]= [euid]
    end
    doc_home_data[:owner_user_id] = @matter.employee_user_id
    doc_home_data[:contact_ids]=[@matter.contact_id]
    doc_home_data[:mapable_type]='Matter'
    doc_home_data[:mapable_id]=@matter.id
    document=params[:document_home][:document_attributes]
    if document[:privilege]=='Privilege'
      document[:privilege] = current_company.matter_privileges.find_by_lvalue('Atty-client')
    else
      document[:privilege] = current_company.matter_privileges.find_by_lvalue('Not privileged')
    end 
    document[:author] = curr_user.full_name
    @matter_peoples = @matter.matter_peoples.all(:conditions => "people_type = 'client'")
    params[:document_home].merge!({
        :created_by_user_id => curr_user.id, :employee_user_id => @matter.employee_user_id,
        :company_id => @matter.company_id,
        :upload_stage => 2
      })
    @document_home = @matter.document_homes.new(params[:document_home])
    @document=@document_home.documents.build(document.merge(:company_id=>@matter.company_id,  :employee_user_id=> @matter.employee_user_id, :created_by_user_id=>curr_user.id, :source => @matter.company.doc_sources.find_by_lvalue('Client')))
    respond_to do |format|
      if @document_home.save        
        user=@matter.user
        LiviaMailConfig::email_settings(current_user.company)
        mail = Mail.new()
        mail.from =  ENV["HOST_NAME"].include?('liviaservices') ? "noreply@liviaservices.com" : "support.test@liviatech.com"
        mail.subject = "Document uploaded by client #{current_user.full_name}"
       
        mail_body = <<EOT
Dear #{user.full_name},
Following document has been uploaded by your Client:

Document Name:  #{@document_home.latest_doc.name}
Matter Name:  #{@matter.name}
Uploaded By: #{current_user.full_name}

Regards,

LIVIA Admin
EOT
        
        mail.body = mail_body
        mail.to = user.email
        mail.deliver
        # End of mail sent
        flash[:notice] = "#{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        format.html { redirect_to(params[:return_path]) }
        format.xml  { render :xml => @document_home, :status => :created,
          :location => @document_home }
      else
        format.html { render :action => "client_new_doc" }
        format.xml  { render :xml => @document_home.errors, :status => :unprocessable_entity }
      end
 
    end
  end

  # Below code will show the detail of the matter.
  def matter_details
    #Below code get matter related task.
    @matter=Matter.scoped_by_company_id(get_company_id).find(params[:id])
    matter_task = @matter.client_tasks
    unless matter_task.blank?
      get_task_and_appointment_series(matter_task)
      @activities = @task_todo + @task_appt
      tasks = @activities.blank? ? [] : @activities.collect{|task| task[:activity]}
      @activities = @activities.paginate(:per_page => params[:per_page], :page => params[:page]) unless @activities.blank?
      @mattertasks = tasks.paginate(:per_page => params[:per_page], :page => params[:page])
    end
    #Below code get matter related documents
    @matter_document = @matter.document_homes_from_client
    @toe = DocumentHome.find_toe_document_home_for_matter('Matter', @matter.id)    
    @matter_document = @matter_document.find_all {|e| e.access_rights.nil? or access_right_client(e.id, @matter.contact_id)}
    @matter_document = @matter_document.collect {|e| e.latest_doc}    
    @payments=@matter.matter_retainers
    @billings =@matter.get_bills
    respond_to do |format|
      format.html
      format.xml  { render :xml => @document_home }
    end
  end

  # Below code will show task details depending on status: Open,Overdue,Upcoming,Closed.
  def matter_task_details
    tasks=[]
    page = params[:page]
    open = current_company.matter_statuses.find_by_lvalue("Open")
    completed = current_company.matter_statuses.find_by_lvalue("Completed")
    @open_matters = Matter.client_accessible(page, get_contact_id,open.id)
    @completed_matters = Matter.client_accessible(page, get_contact_id,completed.id)
    case params[:task_type]
    when 'All'
      @open_matters.each do|matter|
        matter.client_tasks.each {|ct| @matter_task<<ct}
      end
      @completed_matters.each do|completed_matter|
        completed_matter.client_tasks.each {|ct| @matter_task<<ct}
      end
    when 'open'
      @matter_task  = @matter.client_tasks_open
    when 'overdue'
      @matter_task  = @matter.client_tasks_overdue
    when 'upcoming'
      @matter_task  = @matter.client_tasks_upcoming
    when 'closed'
      @matter_task  = @matter.client_tasks_closed
    end
    get_task_and_appointment_series(@matter_task) unless @matter_task.blank?
    @activities = @task_todo + @task_appt
    tasks = @activities.blank? ? [] : @activities.collect{|task| task[:activity]}
    @activities = @activities.paginate(:per_page => params[:per_page], :page => params[:page]) unless @activities.blank?
    @mattertasks = tasks.paginate(:per_page => params[:per_page], :page => params[:page])
    respond_to do |format|
      format.html { render :partial=>'matter_task' }
    end
  end

  def client_comments
    @task = MatterTask.find(params[:task_id])
    @comment = Comment.new
    @comments = Comment.scoped_by_commentable_type('MatterTask').scoped_by_commentable_id(@task.id).all(:order => "created_at DESC", :conditions => "title = 'MatterTask Client'")
    @return_path = params[:return_path] || 'index'
    respond_to do |format|
      format.html
      format.xml  { render :xml => @document_home }
    end
  end

  def get_tasks_by_date
    @datetasks=[]
    page = params[:page]
    open = current_company.matter_statuses.find_by_lvalue("Open")
    completed = current_company.matter_statuses.find_by_lvalue("Completed")
    open_matters = Matter.client_accessible(page, get_contact_id,open.id)
    completed_matters = Matter.client_accessible(page, get_contact_id,completed.id)
    open_matters.each do |matter|
      matter.client_tasks.each {|ct| @datetasks << ct}
    end
    completed_matters.each do | completed_matter|
      completed_matter.client_tasks.each {|ct| @datetasks << ct}
    end
    new_date = params[:new_date].to_date    
    @datetasks = @datetasks.find_all {|e| e.duedate.to_date == new_date}
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'task_type_DIV', :partial => "tasks_by_date"
        end
      }
    end
  end

  def task_details
    @matter_task=[]
    @tasks =[]
    page = params[:page]
    contact_id = get_contact_id
    if params[:matter_id].to_i==0
      @matter_id=0
      open = current_company.matter_statuses.find_by_lvalue("Open")
      completed = current_company.matter_statuses.find_by_lvalue("Completed")
      @open_matters = Matter.client_accessible(page, contact_id,open.id)
      @completed_matters = Matter.client_accessible(page, contact_id,completed.id)
      @open_matters.each do |open_matter|
        open_matter.client_tasks.each {|ct| @tasks<<ct}
      end
      @completed_matters.each do |completed_matter|
        completed_matter.client_tasks.each {|ct| @tasks<<ct}
      end
    else
      @matter=Matter.scoped_by_company_id(get_company_id).find(params[:matter_id].to_i)
      @tasks= @matter.client_tasks      
      @matter_id=@matter.id
    end
    @tasks = @tasks.reject{|task| task.category.eql?('appointment') and task.overdue?}    
    case params[:task_type]
    when 'All'
      @matter_task  = params[:matter_id].to_i==0 ? @tasks : @matter.client_tasks
    when 'open'
      @matter_task  = @tasks.find_all{|item| item.open?}
    when 'overdue'
      @matter_task  = @tasks.find_all{|item| item.overdue? and !item.category.eql?('appointment')}
    when 'upcoming'
      @matter_task  = @tasks.find_all{|item| item.upcoming?}
    when 'closed'
      @matter_task  = @tasks.find_all{|item| item.completed and !item.category.eql?('appointment')}
    end
    unless @matter_task.blank?
      get_task_and_appointment_series(@matter_task)
      @activities = @task_todo + @task_appt
      tasks = @activities.blank? ? [] : @activities.collect{|task| task[:activity]}
      @activities = @activities.paginate(:per_page => params[:per_page], :page => params[:page])
      @mattertasks = tasks.paginate(:per_page => params[:per_page], :page => params[:page])
    end
    respond_to do |format|
      if params[:matter_id].to_i==0
        format.js {
          render :update do |page|
            page.replace_html 'matter_tasks', :partial => "matter_task"
          end
        }
      else
        format.js {
          render :update do |page|
            page.replace_html 'matter_tasks', :partial => "matter_task", :locals => {:matter => @matter, :matter_task => @matter_task}
          end
        }
      end
    end
  end


  def download_all_client_matter_docs
    @matter=Matter.scoped_by_company_id(get_company_id).find(params[:id])
    @matter_task = @matter.client_tasks
    #Below code get matter related documents
    @matter_documents = @matter.document_homes_from_client 
    @matter_documents = @matter_documents.find_all {|e| e.access_rights.nil? or access_right_client(e.id, @matter.contact_id)}
    @matter_documents = @matter_documents.collect {|e| e.latest_doc}

    #Below method create_zip is responsible for creating zip file.
    #create_zip method yield the block passing Zip::ZipFile object
    LiviaZipFile.create_zip do|zf|
      i = 0
      @matter_documents.each do |matter_document|
        asset = Document.scoped_by_company_id(get_company_id).find(matter_document.id)
        i += 1        
        begin
          zf.add(i.to_s + '_' + asset.data_file_name ,asset.data.path)
        rescue Exception =>e
        end
      end
    end
    send_data(File.open(RAILS_ROOT + "/livia_docs.zip", "rb+").read, :type =>
        'application/zip', :disposition => 'inline', :filename =>"livia_docs.zip")
    File.delete RAILS_ROOT + "/livia_docs.zip" # This is required
  end

  private
  # Get current matter.
  def get_matter
    @matter=Matter.scoped_by_company_id(get_company_id).find(params[:matter_id])
  end

  # Returns whether the client has the access to the document.
  def access_right_client(document_home_id, contact_id)
    ac = DocumentAccessControl.all(:conditions => {
        :document_home_id => document_home_id,
        :contact_id => contact_id
      })
    if ac.empty?      
      return false
    end    
    return true
  end
  
end
