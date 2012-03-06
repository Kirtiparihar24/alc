# A matter has risk linked to it, in case it is a non-litigation type matter.
# This controller handled the linking of issues, comments, and documents to the
# matter risk.
# This controller preloads a matter, and is nested under that matter.
# So a matter id should be present to access any action of this controller.

class MatterRisksController < ApplicationController
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
      params.merge!(:col => 'matter_risks.name', :dir => 'up')
    end
    authorize!(:index,@user) unless @user.has_access?(:Risks)
    @matter_peoples=@matter.matter_peoples.find(:all,:conditions=>"people_type='client'")
    sort_column_order
    order = @ord.nil? ? 'matter_risks.name ASC': @ord
    @matter_risks = @matter.matter_risks.paginate(:order => order ,:page=>params[:page],:per_page=>params[:per_page])
    @pagenumber=148
    add_breadcrumb t(:text_risks), matter_matter_risks_path(@matter)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @matter_risks }
    end
  end

  def new
    authorize!(:new,@user) unless @user.has_access?(:Risks)
    @matter_risk = @matter.matter_risks.new
    @pagenumber = 149
    get_instances
    respond_to do |format|
      format.html {} unless request.xhr?
      format.js {render :partial => "modal_new"}
      format.xml  { render :xml => @matter_risk }
    end
  end

  def edit
    authorize!(:edit,@user) unless @user.has_access?(:Risks)
    @matter_peoples=@matter.matter_peoples.find(:all,:conditions=>"people_type='client'")
    @matter_risk = @matter.matter_risks.find(params[:id])
    get_instances
    
    @pagenumber=149
    respond_to do |format|
      format.html {}
      format.js {render :layout => false}      
      format.xml  { render :xml => @matter_risk }
    end
  end

  def create
    authorize!(:create,@user) unless @user.has_access?(:Risks)
    data = params    
    @matter_risk = @matter.matter_risks.new(data[:matter_risk].merge!({:created_by_user_id => current_user.id, :company_id => get_company_id}))
    get_instances
    @pagenumber = 149
    respond_to do |format|
      if @matter_risk.save
        flash[:notice] ="#{t(:text_matter_risk)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        format.html {
          redirect_if(data[:button_pressed].eql?("save"), edit_matter_matter_risk_path(@matter, @matter_risk))
          redirect_if(data[:button_pressed].eql?("save_exit"), matter_matter_risks_path(@matter))
        }
        format.js {
          render :update do|page|
            page << "tb_remove()"
            page.call("parent.location.reload")
          end
        }
        format.xml  { render :xml => @matter_risk, :status => :created, :location => @matter_risk }
      else
        format.html {render :action => :new}
        format.xml  { render :xml => @matter_risk.errors, :status => :unprocessable_entity }
        format.js {
          render :update do|page|
            errors = "<ul>" + @matter_risk.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
            page << "show_error_msg('modal_new_risk_errors','#{errors}','message_error_div');"
            page << "jQuery('#loader').hide();"
            page << "jQuery('#save_risk').val('Save');"
            page << "jQuery('#save_risk').attr('disabled','');"
          end
        }
      end
    end
  end
  
  def update
    authorize!(:update,@user) unless @user.has_access?(:Risks)
    data = params   
    @matter_risk = @matter.matter_risks.find(data[:id])
    get_instances    
    data[:matter_risk][:matter_issue_ids] ||= []
    data[:matter_risk][:matter_task_ids] ||= []
    data[:matter_risk][:matter_fact_ids] ||= []
    data[:matter_risk][:matter_research_ids] ||= []
    respond_to do |format|
      if @matter_risk.update_attributes(data[:matter_risk].merge!({:updated_by_user_id => current_user.id}))
        flash[:notice] = "#{t(:text_matter_risk)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        format.js { redirect_to(matter_matter_risks_path(@matter)) }
        format.html {
          redirect_if(data[:button_pressed].eql?("save"), edit_matter_matter_risk_path(@matter, @matter_risk))
          redirect_if(data[:button_pressed].eql?("save_exit"), matter_matter_risks_path(@matter))
        }
        format.xml  { head :ok }
      else
        format.html { render :action=>:edit,:id =>@matter_risk.id,:matter_id=>@matter.id }
        format.xml  { render :xml => @matter_risk.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @matter_risk = @matter.matter_risks.find(params[:id])
    @matter_risk.updated_by_user_id = current_user.id
    @matter_risk.delete
    flash[:notice] = "Matter risk was deleted successfully."
    respond_to do |format|
      format.html { redirect_to(matter_matter_risks_path(@matter)) }
      format.xml  { head :ok }
    end
  end

  def comment_form
    @comment_user_id = current_user.id
    @comment_commentable_id = params[:id]
    @comment_commentable_type = 'MatterRisk'
    @comment_title = 'Comment'
    @matter_id = params[:matter_id]
    respond_to do |format|
      format.html { render :partial => "matters/comment_form" }
    end
  end

  def show_risk_matter_issues
    @risk_matter_tasks = []
    @risk_matter_issues = []
    @risk_matter_facts = []
    @risk_matter_researches = []
    if params[:format_type]=="activities"
      @risk_matter_tasks = @matter.matter_risks.find(params[:id]).matter_tasks
    end
    if params[:format_type]=="issues"
      @risk_matter_issues = @matter.matter_risks.find(params[:id]).matter_issues
    end
    if params[:format_type]=="facts"
      @risk_matter_facts =@matter.matter_risks.find(params[:id]).matter_facts
    end
    if params[:format_type]=="researches"
      @risk_matter_researches = @matter.matter_risks.find(params[:id]).matter_researches
    end    
    respond_to do |format|
      format.js { render :partial => "common/linked_matter_all", :locals => { :matter_tasks =>@risk_matter_tasks,:matter_issues => @risk_matter_issues, :matter_facts => @risk_matter_facts, :matter_researches => @risk_matter_researches, :format_type => params[:format_type] } }
      format.html { render :partial => "common/linked_matter_all", :locals => { :matter_tasks =>@risk_matter_tasks,:matter_issues => @risk_matter_issues, :matter_facts => @risk_matter_facts, :matter_researches => @risk_matter_researches, :format_type => params[:format_type] } }
    end
  end

  def get_tasks_facts_researches
    @matter_risk = @matter.matter_risks.find(params[:id])
    @col = @matter.send(params[:col_type])
    @col_ids = @matter_risk.send(params[:col_type_ids])
    @label = params[:label]
  end

  def assign_tasks_facts_researches
    @matter_risk = @matter.matter_risks.find(params[:id])
    unless params[:matter_risk]
      eval("@matter_risk.#{params[:dynamic_ids]}=nil")
      @matter_risk.save false
    else
      @matter_risk.update_attributes(params[:matter_risk])
    end
    redirect_to matter_matter_risks_path(@matter)
  end
  
  def get_instances
    @matter_issues = @matter.matter_issues
    @matter_tasks = @matter.matter_tasks
    @matter_facts = @matter.matter_facts
    @matter_researches = @matter.matter_researches
    @other_matter_risks = @matter.matter_risks - [@matter_risk]
    @riskarray = @matter_risk.matter_issues.all(:select => :id).collect{|a| a.id}
    @taskarray = @matter_risk.matter_tasks.all(:select => :id).collect{|a| a.id}
    @factarray = @matter_risk.matter_facts.all(:select => :id).collect{|a| a.id}
    @researcharray = @matter_risk.matter_researches.all(:select => :id).collect{|a| a.id}
    @notes = @matter_risk.comments
    @lawyer_documents = @matter_risk.document_homes.all(:conditions => ["sub_type IS NULL and wip_doc IS NULL AND ((access_rights = 1 and owner_user_id = #{get_employee_user_id}) OR access_rights != 1)"])
    @riskarray.size > 0 ? @matter_issues_not_checked = @matter_issues.all(:conditions => ['id NOT IN (?)', @riskarray]): @matter_issues_not_checked = @matter_issues
    @riskarray.size > 0 ? @matter_issues_checked = @matter_issues.all(:conditions => ['id IN (?)', @riskarray]): @matter_issues_checked = []
    @taskarray.size > 0 ? @matter_tasks_not_checked = @matter_tasks.all(:conditions => ['id NOT IN (?)', @taskarray]): @matter_tasks_not_checked = @matter_tasks
    @taskarray.size > 0 ? @matter_tasks_checked = @matter_tasks.all(:conditions => ['id IN (?)', @taskarray]): @matter_tasks_checked = []
    @factarray.size > 0 ? @matter_facts_not_checked = @matter_facts.all(:conditions => ['id NOT IN (?)', @factarray]): @matter_facts_not_checked = @matter_facts
    @factarray.size > 0 ? @matter_facts_checked = @matter_facts.all(:conditions => ['id IN (?)', @factarray]): @matter_facts_checked = []
    @researcharray.size > 0 ? @matter_researches_not_checked = @matter_researches.all(:conditions => ['id NOT IN (?)', @researcharray]) : @matter_researches_not_checked = @matter_researches
    @researcharray.size > 0 ? @matter_researches_checked = @matter_researches.all(:conditions => ['id IN (?)', @researcharray]) : @matter_researches_checked = []
   end

end
