# Issues related to a matter are handled here, the risks/facts and tasks are
# linked to a matter issue. The comment, document is handled here.
# This controller preloads a matter, and is nested under that matter.
# So a matter id should be present to access any action of this controller.

class MatterIssuesController < ApplicationController

  layout 'left_with_tabs',:except => [:get_tasks_risks_facts,:get_issue_resolve]
  
  verify :method => :post , :only => [:create] , :redirect_to => {:action => :index}
  verify :method => :put , :only => [:update] , :redirect_to => {:action => :index}
  before_filter :authenticate_user!  
  before_filter :get_matter
  before_filter :check_for_matter_acces, :only=>[:index]
  before_filter :check_access_to_matter
  before_filter :get_user, :only => [:index,:edit,:new,:update,:create]
  add_breadcrumb I18n.t(:text_matters), :matters_path

  def index
    if params[:col].blank? && params[:dir].blank?
      params.merge!(:col => 'matter_issues.name', :dir => 'up', :search_item => 'true')
    end
    authorize!(:index,@user) unless @user.has_access?(:Issues)
    @matter_peoples = @matter.matter_peoples.find(:all,:conditions=>"people_type='client'")
    sort_column_order
    params[:order] = @ord.nil? ? 'matter_issues.name ASC': @ord
    @matter_issues = @matter.matter_issues.paginate(:conditions=> {:active => true},:order=>params[:order],:page=>params[:page],:per_page=>params[:per_page])
    @pagenumber = 143
    add_breadcrumb t(:text_issues), matter_matter_issues_path(@matter)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @matter_issues }
    end
  end

  def new
    authorize!(:new,@user) unless @user.has_access?(:Issues)
    @matter_issue = @matter.matter_issues.new
    get_instances
    @pagenumber=52
    @assignees = MatterPeople.current_lawteam_members(@matter.id)
    respond_to do |format|
      format.html {}
      format.js {render :partial => "modal_new"}
      format.xml  { render :xml => @matter_issue }
    end
  end

  def modal_new
    @matter_issue = @matter.matter_issues.new
    @other_matter_issues = @matter.matter_issues
    @matter_risks = @matter.matter_risks
    @matter_facts = @matter.matter_facts
    @matter_tasks = @matter.matter_tasks
    @matter_researches = @matter.matter_researches
    @assignees = MatterPeople.current_lawteam_members(@matter.id) #@matter.matter_peoples.find(:all,:conditions=> ["people_type='client'"])
    render :partial => "modal_new"
  end

  def update_issue_resolve
    @matter_issue = @matter.matter_issues.find(params[:id])    
    render :update do|page|
      if @matter_issue.update_attributes(params[:matter_issue])
        page.call("parent.tb_remove")
        page.call("window.location.reload")
      else
        errors = "<ul>" + @matter_issue.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
        page << "show_error_msg('modal_resolve_issue_errors','#{errors}','message_error_div');"
      end
    end    
  end

  def get_issue_resolve
    @matter_issue = @matter.matter_issues.find(params[:id])
  end

  def get_tasks_risks_facts
    @matter_issue = @matter.matter_issues.find(params[:id])
    @col = @matter.send(params[:col_type])  
    @col_ids = @matter_issue.send(params[:col_type_ids])  
    @label = params[:label]    
  end

  def assign_tasks_risks_facts
    @matter_issue = @matter.matter_issues.find(params[:id])
    unless params[:matter_issue]
      setter_method = "#{params[:dynamic_ids]}="
      @matter_issue.send(setter_method.to_sym, nil)
      @matter_issue.save false
    else
      @matter_issue.update_attributes(params[:matter_issue])
    end
    redirect_to matter_matter_issues_path(@matter)
  end

  def edit
    authorize!(:edit,@user) unless @user.has_access?(:Issues)
    @matter_peoples = @matter.matter_peoples.find(:all,:conditions=>"people_type='client'")
    @matter_issue = @matter.matter_issues.find(params[:id])
    get_instances
    @pagenumber=52
    respond_to do |format|      
      format.html{}
      format.xml  { render :xml => @matter_issue }
      format.js {render :layout => false}
    end
  end

  def create
    authorize!(:create,@user) unless @user.has_access?(:Issues)
    matter_issue_data =params[:matter_issue]
    matter_issue_data.merge!({
        :created_by_user_id => current_user.id,
        :company_id => get_company_id
      })
    @pagenumber=52  
    @matter_issue =@matter.matter_issues.new(matter_issue_data)
    get_instances
    respond_to do |format|
      if @matter_issue.save
        session[:matter_issue_id]=@matter_issue.id        
        flash[:notice] = "#{t(:text_matter_issue)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        format.html {
          redirect_if(params[:button_pressed].eql?("save"), edit_matter_matter_issue_path(@matter, @matter_issue))
          redirect_if(params[:button_pressed].eql?("save_exit"), matter_matter_issues_path(@matter))
        }
        format.js {
          render :update do|page|
            page << "tb_remove()"
            page.call("parent.location.reload")
          end
        }
        format.xml  { render :xml => @matter_issue, :status => :created, :location => @matter_issue }
      else
        format.html {
          render :action => :new
        }
        format.js {
          render :update do|page|
            format_ajax_errors(@matter_issue, page, "modal_new_issue_errors")
            page << "jQuery('#save_issue').val('Save');"
            page << "jQuery('#save_issue').attr('disabled','');"
            page << "jQuery('#loader').hide();"
          end
        }
        format.xml  { render :xml => @matter_issue.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    authorize!(:update,@user) unless @user.has_access?(:Issues)
    matter_issue_data = params[:matter_issue]
    matter_issue_data.merge!({
        :updated_by_user_id => current_user.id
      })
    matter_issue_data[:matter_risk_ids] ||= []
    @matter_issue = @matter.matter_issues.find(params[:id])
    get_instances
    unless @matter_issue.parent_id.nil?
      @other_matter_issues -= [@matter_issue.parent]
    end
    matter_issue_data[:matter_task_ids] ||= []
    matter_issue_data[:matter_fact_ids] ||= [] 
    matter_issue_data[:matter_research_ids] ||= []
    respond_to do |format|
      if @matter_issue.update_attributes(matter_issue_data)
        flash[:notice] = "#{t(:text_matter_issue)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        format.js {
          redirect_if(params[:button_pressed].eql?("save"), edit_matter_matter_issue_path(@matter, @matter_issue))
          redirect_if(params[:button_pressed].eql?("save_exit"), matter_matter_issues_path(@matter))
        }
        format.html {
          redirect_if(params[:button_pressed].eql?("save"), edit_matter_matter_issue_path(@matter, @matter_issue))
          redirect_if(params[:button_pressed].eql?("save_exit"), matter_matter_issues_path(@matter))
        }
        format.xml  { head :ok }
      else
        format.html { render :action=>:edit,:id =>@matter_issue.id,:matter_id=>@matter.id }
        format.xml  { render :xml => @matter_issue.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @matter_issue = @matter.matter_issues.find(params[:id])    
    @matter_issue.delete
    respond_to do |format|
      format.html { redirect_to(matter_matter_issues_url(@matter)) }
      format.xml  { head :ok }
    end
  end

  def comment_form
    @comment_user_id = current_user.id
    @comment_commentable_id = params[:id]
    @comment_commentable_type = 'MatterIssue'
    @comment_title = 'Comment'
    @matter_id = params[:matter_id]
    render :partial => "matters/comment_form"
  end

  def show_issue_matter_risks
    @issue_matter_risks = @matter.matter_issues.find(params[:id]).matter_risks
    respond_to do |format|
      format.js {render :partial => "common/linked_matter_risks", :locals => { :matter_risks => @issue_matter_risks }}
      format.html {render :partial => "common/linked_matter_risks", :locals => { :matter_risks => @issue_matter_risks }}
    end
  end

  def show_issue_matter_tasks
    @issue_matter_tasks = @matter.matter_issues.find(params[:id]).matter_tasks
    respond_to do |format|
      format.js {render :partial => "common/linked_matter_tasks", :locals => { :matter_tasks => @issue_matter_tasks }}
      format.html {render :partial => "common/linked_matter_tasks", :locals => { :matter_tasks => @issue_matter_tasks }}
    end
  end

  def show_issue_matter_facts
    issue = @matter.matter_issues.find(params[:id])
    @issue_matter_facts = issue.matter_facts
    respond_to do |format|
      format.js {render :partial => "common/linked_matter_facts", :locals => { :matter_facts => @issue_matter_facts }}
      format.html {render :partial => "common/linked_matter_facts", :locals => { :matter_facts => @issue_matter_facts }}
    end
  end

  def show_issue_matter_researches
    @issue_matter_researches = @matter.matter_issues.find(params[:id]).matter_researches
    respond_to do |format|
      format.js {render :partial => "common/linked_matter_researches", :locals => { :matter_researches => @issue_matter_researches }}
      format.html {render :partial => "common/linked_matter_researches", :locals => { :matter_researches => @issue_matter_researches }}
    end
  end
  
  def get_instances
    @other_matter_issues = @matter.matter_issues - [@matter_issue]    
    @assignees = MatterPeople.current_lawteam_members(@matter.id) 
    array = @matter_issue.matter_risks.all(:select => :id)
    @issuearray = array.collect{|a| a.id}
    @notes = @matter_issue.comments
    # For checkbox linkage.    
    @matter_tasks = @matter.matter_tasks
    @matter_facts = @matter.matter_facts
    @matter_risks = @matter.matter_risks
    @matter_researches = @matter.matter_researches
    @lawyer_documents = @matter_issue.document_homes.all(:conditions => ["sub_type IS NULL AND wip_doc IS NULL AND ((access_rights = 1 AND owner_user_id = #{get_employee_user_id}) OR access_rights != 1)"])    
    @task_ids = @matter_issue.matter_tasks.collect { |e| e.id }
    @fact_ids = @matter_issue.matter_facts.collect { |e| e.id }
    @risk_ids = @matter_issue.matter_risks.collect { |e| e.id }
    @research_ids = @matter_issue.matter_researches.collect { |e| e.id }
    @task_ids.size > 0 ? @matter_tasks_not_checked = @matter_tasks.all(:conditions => ['id NOT IN (?)', @task_ids]) : @matter_tasks_not_checked = @matter_tasks
    @task_ids.size > 0 ? @matter_tasks_checked=@matter_tasks.all(:conditions => ['id IN (?)', @task_ids]) : @matter_tasks_checked = []
    @fact_ids.size > 0 ? @matter_facts_not_checked= @matter_facts.all(:conditions => ['id NOT IN (?)', @fact_ids]) : @matter_facts_not_checked = @matter_facts
    @fact_ids.size > 0 ? @matter_facts_checked=@matter_facts.all(:conditions => ['id IN (?)', @fact_ids]) : @matter_facts_checked = []
    @risk_ids.size > 0 ? @matter_risks_not_checked= @matter_risks.all(:conditions => ['id NOT IN (?)', @risk_ids]) : @matter_risks_not_checked = @matter_risks
    @risk_ids.size > 0 ? @matter_risks_checked=@matter_risks.all(:conditions => ['id IN (?)', @risk_ids]) : @matter_risks_checked = []
    @research_ids.size > 0 ? @matter_researches_not_checked = @matter_researches.all(:conditions => ['id NOT IN (?)',@research_ids]) : @matter_researches_not_checked = @matter_researches
    @research_ids.size > 0 ? @matter_researches_checked = @matter_researches.all(:conditions => ['id IN (?)', @research_ids]) : @matter_researches_checked = []
  end
  
end
