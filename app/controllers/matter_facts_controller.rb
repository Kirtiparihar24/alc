# This controller preloads a matter, and is nested under that matter.
# So a matter id should be present to access any action of this controller.

class MatterFactsController < ApplicationController
  layout 'left_with_tabs'
  
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
      params.merge!(:col => 'matter_facts.name', :dir => 'up')
    end
    authorize!(:index,@user) unless @user.has_access?(:Facts)
    @matter_peoples=@matter.matter_peoples.find(:all,:conditions=>"people_type='client'")
    @pagenumber = 166
    sort_column_order
    params[:order] = @ord.nil? ? 'matter_facts.name ASC' : @ord
    @matter_facts = @matter.matter_facts.paginate(:order=>params[:order],:include => :doc_source,:page=>params[:page],:per_page=>params[:per_page])
      add_breadcrumb t(:text_facts), matter_matter_facts_path(@matter)
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @matter_facts }
    end
  end

  def new
    authorize!(:new,@user) unless @user.has_access?(:Facts)
    @pagenumber=55
    @matter_fact = @matter.matter_facts.new
    get_instances
    
    respond_to do |format|
      unless params[:renderjs]
        format.html { }
      end
      format.js {render :partial => "modal_new"}
      format.xml  { render :xml => @matter_fact }
    end
  end
  
  def edit
    authorize!(:edit,@user) unless @user.has_access?(:Facts)
    @matter_peoples=@matter.matter_peoples.find(:all,:conditions=>"people_type='client'")
    @pagenumber=55
    @matter_fact = @matter.matter_facts.find(params[:id])
    get_instances
    @commentable_type = 'MatterIssue'
    @commentable = @matter_issue
    respond_to do |format|
      format.html {}
      format.js {render :layout => false}      
      format.xml  { render :xml => @matter_fact }
    end
  end

  def create
    authorize!(:create,@user) unless @user.has_access?(:Facts)
    matter_fact_data = params[:matter_fact]
    matter_fact_data.merge!({
        :created_by_user_id => current_user.id,
        :company_id => get_company_id
      })
    @matter_fact = @matter.matter_facts.new(matter_fact_data)
    get_instances
    @array = []
    respond_to do |format|
      if @matter_fact.save
        session[:matter_fact_id]=@matter_fact.id        
        format.html {
          flash[:notice] ="#{t(:text_matter_fact)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
          if params[:button_pressed].eql?("save_exit")
            redirect_to(matter_matter_facts_path(@matter))
          else
            redirect_to(edit_matter_matter_fact_path(@matter,@matter_fact))
          end        
        }
        format.js {
          render :update do|page|
            page << "tb_remove()"
          end
        }
        format.xml  { render :xml => @matter_fact, :status => :created, :location => @matter_fact }     
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @matter_fact.errors, :status => :unprocessable_entity }
        format.js {
          render :update do|page|
            errors = "<ul>" + @matter_fact.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
            page << "show_error_msg('modal_new_fact_errors','#{errors}','message_error_div');"
            page << "jQuery('#loader').hide();"
          end
        }
      end
    end
  end

  def update
    authorize!(:update,@user) unless @user.has_access?(:Facts)
    matter_fact_data = params[:matter_fact]
    matter_fact_data.merge!({
        :updated_by_user_id => current_user.id
      })
    @matter_fact = @matter.matter_facts.find(params[:id])
    get_instances
    matter_fact_data[:matter_task_ids] ||= []
    matter_fact_data[:matter_issue_ids] ||= []
    matter_fact_data[:matter_risk_ids] ||= []
    matter_fact_data[:matter_research_ids] ||= []
    respond_to do |format|
      if @matter_fact.update_attributes(matter_fact_data)        
        flash[:notice] = "#{t(:text_matter_fact)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        format.js { redirect_to(matter_matter_facts_path(@matter)) }       
        format.html {
          if params[:button_pressed].eql?("save_exit")
            redirect_to(matter_matter_facts_path(@matter))
          else
            redirect_to(edit_matter_matter_fact_path(@matter,@matter_fact)) 
          end
        }
        format.xml  { head :ok }
      else
        format.js { redirect_to(matter_matter_facts_path(@matter)) }
        format.html { render :action=>:edit,:id =>@matter_fact.id,:matter_id=>@matter.id }
        format.xml  { render :xml => @matter_fact.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @matter_fact = @matter.matter_facts.find(params[:id])
    @matter_fact.delete
    respond_to do |format|
      format.html { redirect_to(matter_matter_facts_path(@matter)) }
      format.xml  { head :ok }
    end
  end

  def comment_form
    @comment_user_id = current_user.id
    @comment_commentable_id = params[:id]
    @comment_commentable_type = 'MatterFact'
    @comment_title = 'Comment'
    @matter_id = params[:matter_id]
    respond_to do |format|
      format.html { render :partial => "matters/comment_form" }
    end
  end

  def show_fact_matter_issues
    @fact_matter_tasks = []
    @fact_matter_issues = []
    @fact_matter_risks = []
    @fact_matter_researches = []
    if params[:format_type] == "activities"
      @fact_matter_tasks = @matter.matter_facts.find(params[:id]).matter_tasks
    end
    if params[:format_type] == "issues"
      @fact_matter_issues = @matter.matter_facts.find(params[:id]).matter_issues
    end
    if params[:format_type] == "risks"
      @fact_matter_risks = @matter.matter_facts.find(params[:id]).matter_risks
    end
    if params[:format_type] == "researches"
      @fact_matter_researches = @matter.matter_facts.find(params[:id]).matter_researches
    end    
    respond_to do |format|
      format.js { render :partial => "common/linked_matter_all", :locals => { :matter_tasks =>@fact_matter_tasks,:matter_issues => @fact_matter_issues, :matter_risks => @fact_matter_risks, :matter_researches => @fact_matter_researches, :format_type => params[:format_type] }}
      format.html { render :partial => "common/linked_matter_all", :locals => { :matter_tasks =>@fact_matter_tasks,:matter_issues => @fact_matter_issues, :matter_risks => @fact_matter_risks, :matter_researches => @fact_matter_researches, :format_type => params[:format_type] }}
    end
  end

  def get_tasks_risks_researches
    @matter_fact = @matter.matter_facts.find(params[:id])
    @col = @matter.send(params[:col_type])
    @col_ids = @matter_fact.send(params[:col_type_ids])
    @label = params[:label]
  end

  def assign_tasks_risks_researches
    @matter_fact = @matter.matter_facts.find(params[:id])
    unless params[:matter_fact]
      eval("@matter_fact.#{params[:dynamic_ids]}=nil")
      @matter_fact.save false
    else
      @matter_fact.update_attributes(params[:matter_fact])
    end
    redirect_to matter_matter_facts_path(@matter)
  end

  def get_instances
    @matter_tasks = @matter.matter_tasks
    @matter_issues = @matter.matter_issues
    @matter_risks = @matter.matter_risks
    @matter_researches = @matter.matter_researches
    @other_matter_facts = @matter.matter_facts - [@matter_fact]
    @notes = @matter_fact.comments
    @lawyer_documents = @matter_fact.document_homes.all(:conditions => ["sub_type IS NULL and wip_doc IS NULL AND ((access_rights = 1 AND owner_user_id = #{get_employee_user_id}) OR access_rights != 1)"])  
    @taskarray = @matter_fact.matter_tasks.all(:select => :id).collect{|a| a.id}
    @issuearray = @matter_fact.matter_issues.all(:select => :id).collect{|a| a.id}
    @riskarray = @matter_fact.matter_risks.all(:select => :id).collect{|a| a.id}
    @researcharray = @matter_fact.matter_researches.all(:select => :id).collect{|a| a.id}
    @taskarray.size > 0 ? @matter_tasks_not_checked = @matter_tasks.all(:conditions => ['id NOT IN (?)', @taskarray]): @matter_tasks_not_checked = @matter_tasks
    @taskarray.size > 0 ? @matter_tasks_checked = @matter_tasks.all(:conditions => ['id IN (?)', @taskarray]): @matter_tasks_checked = []
    @issuearray.size > 0 ? @matter_issues_not_checked = @matter_issues.all(:conditions => ['id NOT IN (?)',@issuearray]): @matter_issues_not_checked = @matter_issues
    @issuearray.size > 0 ? @matter_issues_checked = @matter_issues.all(:conditions => ['id IN (?)', @issuearray]): @matter_issues_checked = []
    @riskarray.size > 0 ? @matter_risks_not_checked = @matter_risks.all(:conditions => ['id NOT IN (?)', @riskarray]): @matter_risks_not_checked = @matter_risks
    @riskarray.size > 0 ? @matter_risks_checked = @matter_risks.all(:conditions => ['id IN (?)', @riskarray]): @matter_risks_checked = []
    @researcharray.size > 0 ? @matter_researches_not_checked = @matter_researches.all(:conditions => ['id NOT IN (?)',@researcharray]): @matter_researches_not_checked = @matter_researches
    @researcharray.size > 0 ? @matter_researches_checked = @matter_researches.all(:conditions => ['id IN (?)', @researcharray]): @matter_researches_checked = []
  end
  
end
