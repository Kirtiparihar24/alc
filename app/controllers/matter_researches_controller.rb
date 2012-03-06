# Reseraches done for the matter are handled in this controller.
# A research is linked with tasks, issues, risks/facts, and documents.
# Comments for research are also done here.
# This controller preloads a matter, and is nested under that matter.
# So a matter id should be present to access any action of this controller.

class MatterResearchesController < ApplicationController
  verify :method => :post , :only => [:create] , :redirect_to => {:action => :index}
  verify :method => :put , :only => [:update] , :redirect_to => {:action => :index}

  layout 'left_with_tabs'

  before_filter :authenticate_user!    
  before_filter :get_matter
  before_filter :check_for_matter_acces, :only=>[:index]
  before_filter :check_access_to_matter
  before_filter :get_user, :only => [:index,:edit,:new,:update,:create]
  add_breadcrumb I18n.t(:text_matters), :matters_path

  def index
    if params[:col].blank? && params[:dir].blank?
      params.merge!(:col => 'matter_researches.name', :dir => 'up')
    end
    authorize!(:index,@user) unless @user.has_access?(:Researches)
    sort_column_order
    @matter_peoples=@matter.matter_peoples.find(:all,:conditions=>"people_type='client'")
    order = @ord.nil?? 'matter_researches.name ASC':@ord
    @matter_researches = @matter.matter_researches.paginate(:order=>order,:page=>params[:page],:include => :researchable_type,:per_page=>params[:per_page])    
    @pagenumber = 152
    add_breadcrumb t(:text_research), matter_matter_researches_path(@matter)
    respond_to do |format|
      format.html
      format.xml  { render :xml => @matter_researches }
    end
  end

  def new
    authorize!(:new,@user) unless @user.has_access?(:Researches)
    @matter_research =  @matter.matter_researches.new
    get_instances
    @pagenumber = 57
    respond_to do |format|
      format.html {
        if request.xhr?
          render :partial => "modal_new"
        end
      }
      format.js {render :partial => "modal_new"}
      format.xml  { render :xml => @matter_research }
    end
  end

  def edit
    authorize!(:edit,@user) unless @user.has_access?(:Researches)
    @matter_peoples=@matter.matter_peoples.find(:all,:conditions=>"people_type='client'")
    @matter_research =  @matter.matter_researches.find(params[:id])
    @pagenumber = 57
    @notes = @matter_research.comments    
    get_instances
    respond_to do |format|
      format.html {}
      format.js {render :layout => false}      
      format.xml  { render :xml => @matter_research }
    end
  end

  def create
    authorize!(:create,@user) unless @user.has_access?(:Researches)
    @pagenumber = 57
    @matter_research = @matter.matter_researches.new(params[:matter_research].merge!({:created_by_user_id => current_user.id, :company_id => get_company_id}))
    get_instances
    respond_to do |format|
      if @matter_research.save                
        flash[:notice] = "#{t(:text_matter_research)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        format.html {
          redirect_if(params[:button_pressed].eql?("save"), edit_matter_matter_research_path(@matter, @matter_research))
          redirect_if(params[:button_pressed].eql?("save_exit"), matter_matter_researches_path(@matter))
        }
        format.xml  { render :xml => @matter_research, :status => :created, :location => @matter_research }
        format.js {
          render :update do|page|
            page << "parent.tb_remove();"
            page.call("parent.location.reload")
          end
        }
      else
        format.html {  render :action => :new }
        format.xml  { render :xml => @matter_research.errors, :status => :unprocessable_entity }
        format.js {
          render :update do|page|
            errors = "<ul>" + @matter_research.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
            page << "show_error_msg('modal_new_research_errors','#{errors}','message_error_div');"            
            page << "jQuery('#save_research').val('Save');"
            page << "jQuery('#save_research').attr('disabled','');"
            page << "jQuery('#loader').hide();"
          end
        }
      end
    end
  end

  def update
    authorize!(:update,@user) unless @user.has_access?(:Researches)
    data = params
    data[:matter_research].merge!({
        :updated_by_user_id => current_user.id
      })
    @matter_research =  @matter.matter_researches.find(data[:id])
    get_instances
    matt_research_data = data[:matter_research]
    matt_research_data[:matter_risk_ids] ||= []
    matt_research_data[:matter_issue_ids] ||= []
    matt_research_data[:matter_fact_ids] ||= []
    matt_research_data[:matter_task_ids] ||= []
    respond_to do |format|
      if @matter_research.update_attributes(matt_research_data)
        flash[:notice] = "#{t(:text_matter_research)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        format.js { redirect_to(matter_matter_researches_path(@matter)) }
        format.html {
          redirect_if(params[:button_pressed].eql?("save"), edit_matter_matter_research_path(@matter, @matter_research))
          redirect_if(params[:button_pressed].eql?("save_exit"), matter_matter_researches_path(@matter))
        }
        format.xml  { head :ok }
      else
        format.html { render :action=>:edit,:id =>@matter_research.id,:matter_id=>@matter.id }
        format.xml  { render :xml => @matter_research.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @matter_research = @matter.matter_researches.find(params[:id])
    @matter_research.delete
    respond_to do |format|
      format.html { redirect_to(matter_matter_researches_url(@matter)) }
      format.xml  { head :ok }
    end
  end
  
  def comment_form
    @comment_user_id = current_user.id
    @comment_commentable_id = params[:id]
    @comment_commentable_type = 'MatterResearch'
    @comment_title = 'Comment'
    @matter_id = params[:matter_id]
    respond_to do |format|
      format.html { render :partial => "matters/comment_form" }
    end
  end
  
  def show_research_matter_issues
    @research_matter_issues = @matter.matter_researches.find(params[:id]).matter_issues
    respond_to do |format|
      format.js { render :partial => "common/linked_matter_issues", :locals => { :matter_issues => @research_matter_issues } }
      format.html { render :partial => "common/linked_matter_issues", :locals => { :matter_issues => @research_matter_issues } }
    end
  end

  def show_research_matter_risks
    @research_matter_risks = @matter.matter_researches.find(params[:id]).matter_risks
    respond_to do |format|
      format.js { render :partial => "common/linked_matter_risks", :locals => { :matter_risks => @research_matter_risks } }
      format.html { render :partial => "common/linked_matter_risks", :locals => { :matter_risks => @research_matter_risks } }
    end
  end

  def show_research_matter_facts
    @research_matter_facts = @matter.matter_researches.find(params[:id]).matter_facts
    respond_to do |format|
      format.js { render :partial => "common/linked_matter_facts", :locals => { :matter_facts => @research_matter_facts } }
      format.html { render :partial => "common/linked_matter_facts", :locals => { :matter_facts => @research_matter_facts } }
    end
  end

  def show_research_matter_tasks
    @research_matter_tasks = @matter.matter_researches.find(params[:id]).matter_tasks
    respond_to do |format|
      format.js { render :partial => "common/linked_matter_tasks", :locals => { :matter_tasks => @research_matter_tasks } }
      format.html { render :partial => "common/linked_matter_tasks", :locals => { :matter_tasks => @research_matter_tasks } }
    end
  end

  def get_instances
    @other_matter_researches = @matter.matter_researches - [@matter_research]
    @notes = @matter_research.comments    
    @lawyer_documents=@matter_research.document_homes.all(:conditions => ["sub_type IS NULL AND wip_doc IS NULL AND ((access_rights = 1 AND owner_user_id = #{get_employee_user_id}) OR access_rights != 1)"])
    @matter_issues = @matter.matter_issues
    @matter_facts = @matter.matter_facts
    @matter_risks = @matter.matter_risks
    @matter_tasks = @matter.matter_tasks
    @research_issue_array = @matter_research.matter_issues.all(:select => :id).collect{|a| a.id}
    @research_fact_array = @matter_research.matter_facts.all(:select => :id).collect{|a| a.id}
    @research_risk_array = @matter_research.matter_risks.all(:select => :id).collect{|a| a.id}
    @research_task_array = @matter_research.matter_tasks.all(:select => :id).collect{|a| a.id}
    @research_task_array.size > 0 ? @matter_tasks_not_checked = @matter_tasks.all(:conditions => ['id NOT IN (?)', @research_task_array]) : @matter_tasks_not_checked = @matter_tasks
    @research_task_array.size > 0 ? @matter_tasks_checked = @matter_tasks.all(:conditions => ['id IN (?)', @research_task_array]) : @matter_tasks_checked = []
    @research_issue_array.size > 0  ? @matter_issues_not_checked = @matter_issues.all(:conditions => ['id NOT IN (?)', @research_issue_array]): @matter_issues_not_checked = @matter_issues
    @research_issue_array.size > 0 ? @matter_issues_checked = @matter_issues.all(:conditions => ['id IN (?)', @research_issue_array]): @matter_issues_checked = []
    @research_fact_array.size > 0 ? @matter_facts_not_checked = @matter_facts.all(:conditions => ['id NOT IN (?)', @research_fact_array]) : @matter_facts_not_checked = @matter_facts
    @research_fact_array.size > 0 ? @matter_facts_checked = @matter_facts.all(:conditions => ['id IN (?)',  @research_fact_array]) : @matter_facts_checked=[]
    @research_risk_array.size > 0  ? @matter_risks_not_checked= @matter_risks.all(:conditions => ['id NOT IN (?)', @research_risk_array]) : @matter_risks_not_checked = @matter_risks
    @research_risk_array.size > 0 ? @matter_risks_checked = @matter_risks.all(:conditions => ['id IN (?)', @research_risk_array]) : @matter_risks_checked = []
  end

end
