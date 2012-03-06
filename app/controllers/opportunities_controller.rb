class OpportunitiesController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource :except => [:edit]
  verify :method => :post , :only => [:create] , :redirect_to => {:action => :index}
  verify :method => :put , :only => [:update] , :redirect_to => {:action => :index}
  before_filter :current_service_session_exists
  before_filter :get_base_data

  layout 'full_screen', :except =>[:sort_opportunities_columns]
  
  before_filter :get_service_session , :only => ['new','index']
  before_filter :get_report_favourites ,:only => [:index,:new,:edit,:comments,:change_status]
  rescue_from ActionController::UnknownAction, :with => :no_action_handled_opportunities
  rescue_from ActiveRecord::RecordNotFound, :with => :show_action_error_handled_opportunities
  add_breadcrumb I18n.t(:text_opportunities) , :opportunities_path
  helper_method :remember_past_path,:remember_past_edit_path

  # This method is used to display the list of opportunities with various stages.
  def index
    if params[:search_item].blank?
      params.merge!(:col => 'opportunities.name', :dir => 'up', :search_item => 'true')
    end
    params[:search] ||= {} #Added to reduce the conditions in feature 9718 for dropdown in filter search -- Kushal.Dongre
    cuser = get_employee_user
    data=params
    set_params_filter
    @letter_selected = data[:letter]
    @pagenumber=124
    @icon = params[:dir].eql?("up") ? 'sort_asc':'sort_desc'
    sort_column_order

    data[:order] = @ord.nil?? 'opportunities.name ASC':@ord
    if cuser.employee.my_opportunities == true
      @mode_type = (params[:mode_type]= 'MY')
      flash[:notice]="You are configured to view details only of My Opportunities"
    elsif(params[:mode_type] == nil)
      @mode_type= 'MY'
      params.merge!(:mode_type=>'MY')
    else
      @mode_type= params[:mode_type]
    end
    closed_won = @company.opportunity_stage_types.find_by_lvalue('Closed/Won')
    closed_lost = @company.opportunity_stage_types.find_by_lvalue('Closed/Lost')
    closed_array = [closed_won.try(:id),closed_lost.try(:id) ]
    @opp_stage = data[:opp_stage] ? data[:opp_stage] : ""    
    opp_stages = @company.opportunity_stage_types.collect{|stage|[stage.try(:alvalue), stage.try(:id)]} 
    @oppstage = @company.opportunity_stage_types.collect{|stage|[stage.try(:alvalue), stage.try(:id)]} 
    @opp_stages = Opportunity.count_stage_wise_opportunity(@company, @opp_stage, data[:mode_type],@emp_user_id, opp_stages)
    @perpage = params[:per_page].present? ? params[:per_page] : 25 # added for changing pagination limit - do not remove -- Supriya
    if cuser.employee.my_opportunities == true
      @opportunities = (@company.opportunities.find_my_opportunity(data, @emp_user_id, closed_array, @perpage))
    else
      @opportunities = (data[:mode_type].eql?("ALL") || data[:mode_type].nil?) ? @company.opportunities.find_all_opportunity(data, closed_array, @perpage, @company.id) : @company.opportunities.find_my_opportunity(data, @emp_user_id, closed_array, @perpage, @company.id)
    end
    respond_to do |format|
      format.html{
        render :partial => 'opportunity',:layout => false if params[:load_popup]
      }
      format.js {
        render :update do |page|
          page.replace 'searched_opportunities', :partial => 'opportunity'
        end
      }
    end
  end

  # This is just a stub for a builtin Ruby method and used to create a new object of opportunity.
  # The New objects can be instantiated as either empty (pass no construction parameter) or pre-set with
  # attributes but not yet saved (pass a hash with key names matching the associated table column names).
  def new
    get_available_campaigns
    @contact_stage = get_contact_stages(@company.contact_stages.array_to_hash('lvalue'),['Prospect','Client'])
    @opportunity = Opportunity.new
    @users = User.except(@current_user).all
    @pagenumber = 33
    @employees = User.find_user_not_admin_not_client(@company.id)
    @contact = Contact.new
    #sorted_contacts
    add_breadcrumb "#{t(:text_new)} #{t(:text_opportunities)}", new_opportunity_path
  end

  # This method is used to create new opportunity with contact. The contact can be new or existing one.
  def create
    data=params
    @pagenumber=33
    data[:opportunity][:employee_user_id]=data[:contact][:employee_user_id]=@emp_user_id
    data[:opportunity][:created_by_user_id]= data[:contact][:created_by_user_id]= @current_user.id
    data[:opportunity][:company_id] = data[:contact][:company_id]=@company.id
    data[:opportunity][:current_user_name]= data[:contact][:current_user_name]=@current_user.full_name
    data[:opportunity][:employee_user_id], data[:contact][:via]=@emp_user_id,"Opportunity"
    data[:opportunity][:status_updated_on]=Time.zone.now
    data[:opportunity][:follow_up] = Time.zone.parse("#{data[:opportunity][:follow_up]}T#{data[:opportunity][:follow_up_time]}").getutc unless data[:opportunity][:follow_up].blank?
    @employees = User.find_user_not_admin_not_client(@company.id)
    get_available_campaigns if current_company.company_sources.find_by_id(@opportunity.source).try(:alvalue) == 'Campaign'
    @opportunity = Opportunity.new(data[:opportunity])
    @contact_stage = get_contact_stages(@company.contact_stages.array_to_hash('lvalue'),['Prospect','Client'])
    @comment = Comment.new
    @opportunity = @company.opportunities.new(data[:opportunity])
    if  @opportunity.save_with_contact(data)
      flash[:notice] = "#{t(:text_opportunity)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
      redirect_if(data[:button_pressed].eql?("save"), edit_opportunity_path(@opportunity))
      redirect_if(data[:button_pressed].eql?("save_exit"), opportunities_path)
    else
      @contact= @opportunity.contact || Contact.new
      render 'new'
    end
  end

  # This method is used to modify the existing opportunity.
  def edit
    data=params
    session[:search]=params[:search]
    @opportunity = nil
    @opportunity = @company.opportunities.find_with_deleted(data[:id])
    session[:stage_id] = @opportunity.stage
    @pagenumber=34
    # Added to send the Closed/Won stage as strig to javascript function to
    # show the matter checkbox in change status screen
    @closed_won_stage = current_company.opportunity_stage_types.find_all_by_lvalue('Closed/Won').map{|stg| [stg.id]}.join(",")

    get_available_campaigns if current_company.company_sources.find_by_id(@opportunity.source).try(:alvalue) == 'Campaign'
    
    if @opportunity.deleted_at.blank?
      @document_homes= @opportunity.document_homes
      @notes = @opportunity.comments
      @sources =@company.company_sources
      @users = User.except(@current_user).all
      @comment= Comment.new
      @employees = User.find_user_not_admin_not_client(@company.id)
      @contact=@opportunity.contact
      add_breadcrumb "#{t(:text_edit)} #{t(:text_opportunity)}", edit_opportunity_path(@opportunity)
    else
      flash[:error] = "#{t(:flash_opportunity_has_been_deactivated)}"
      redirect_to :action => "index"
    end
  rescue ActiveRecord::RecordNotFound
    @previous ||= $1.to_i
    redirect_to url_for(:action => 'index')
  end

  # This method is used to update the object of opportunity which is modified but not saved yet.
  def update
    Opportunity.transaction do
      data=params
      @opportunity = @opporunitystatus = @company.opportunities.find(data[:id])
      @document_homes= @opportunity.document_homes
      @notes = @opportunity.comments
      @comment = Comment.new
      @sources =@company.company_sources
      @opportunity.contact_id=data[:contact_id]
      @contact=@opportunity.contact
      @employees = User.find_user_not_admin_not_client(@company.id)
      if data[:comment] && !data[:comment][:comment].blank? && !data[:comment][:comment].nil?
        comment =@opportunity.comments.create(:title=> 'Note',:created_by_user_id=> @current_user.id,:comment => data[:comment][:comment], :company_id=> @company.id )
      end
      @opportunity.write_attribute('reason',data[:opportunity][:reason])
      data[:opportunity][:follow_up]=nil if data[:opportunity][:follow_up_done]
      data[:opportunity].merge!(:updated_by_user_id=>@current_user.id)
      data[:opportunity][:follow_up] = Time.zone.parse("#{data[:opportunity][:follow_up]}T#{data[:opportunity][:follow_up_time]}").getutc unless data[:opportunity][:follow_up].blank?
      if  @opportunity.update_attributes(data[:opportunity])
        if  @opporunitystatus.stage != data[:opportunity][:stage]
          #checking for opp is closed
          @opportunity.closed_on = Time.zone.now if [5,6].include?(data[:opportunity][:stage].to_i)
          unless data[:opportunity][:reason].blank?
          else
            @opportunity.errors.add(t(:flash_status_change_reason))
          end
        end
        if @opportunity.stage == current_company.opportunity_stage_types.find_by_lvalue('Closed/Won').id && data[:opp_matter] && data[:opp_matter][:true].to_i == 1
          redirect_to new_matter_path(:opportunity_id => @opportunity.id)
        else
          flash[:notice] = "#{t(:text_opportunity)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
          redirect_if(data[:save], remember_past_edit_path(@opportunity))
          redirect_if(data[:save_exit], remember_past_path)
          session[:stage_id] = nil
          session[:search]= nil if data[:save_exit]
        end        
        get_available_campaigns if current_company.company_sources.find_by_id(@opportunity.source).try(:alvalue) == 'Campaign'
     
      else
        @users = User.except(@current_user).all # Need it to redraw [Edit Account] form.
        render :action=> 'edit'
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:js, :xml)
  end

  # This method is used to render the view of new contact when the opportunity is create or update.
  def populatecontactfields
    @contact     = Contact.new()
    @contact_stage= get_contact_stages(@company.contact_stages.array_to_hash('lvalue'),['Prospect','Client'])

    @lead_status=false
    render :partial=>'/common/newcontact'
  end

  # This method is used to render the view of existing contact when the opportunity is create or update.
  def populatecombo
    sorted_contacts
    render :partial=>'/common/existingcontact',:object=>@account_contacts
  end

  # This method is used to instantiated the object to change the status of opportunity.
  def change_status
    data=params
    session[:search]=params[:search]
    @opportunitytemp =@opportunity= nil
    begin
      @opportunitytemp = @opportunity = @company.opportunities.find(data[:id])
    rescue
      @opportunitytemp = @opportunity = @company.opportunities.find_with_deleted(data[:id])
    end
    @stage= current_company.opportunity_stage_types.collect{|e| [e.alvalue,e.id] }.find_all {|a| a[1] != @opportunity.stage }
    # Added to send the Closed/Won stage as strig to javascript function to
    # show the matter checkbox in change status screen
    @closed_won_stage = current_company.opportunity_stage_types.find_all_by_lvalue('Closed/Won').map{|stg| [stg.id]}.join(",")
    render :layout =>false
  end

  # This method is used to update the modified status of opportunity.
  def save_status
    @opportunity=@company.opportunities.find_with_deleted(params[:id])
    @opportunitytemp  =@opportunity.clone
    @stage=current_company.opportunity_stage_types.collect{|e| [e.alvalue,e.id] if  e.id != @opportunity.stage }.compact
    @opportunity.status_updated_on= Time.zone.now
    params[:opportunity][:updated_by_user_id]=  @emp_user_id
    if @opportunity.update_attributes(params[:opportunity])
      flash[:notice] = "#{t(:text_opportunity) } "+  @opportunity.name.try(:capitalize) + " #{t(:flash_was_successful)} " "#{t(:text_updated)}"
      if @opportunity.stage == current_company.opportunity_stage_types.find_by_lvalue('Closed/Won').id && params[:opp_matter] && params[:opp_matter][:true].to_i == 1
        render :update do |page|
          page << "tb_remove();"
          page.redirect_to new_matter_path(:opportunity_id => @opportunity.id)
        end
      else
        respond_to do |format|
          format.js{
            render :update do |page|
              page << "show_error_msg('nameerror','#{@opportunity.errors.full_messages}','one_field_error_div');"
              page << "jQuery('#loader').hide();"
              page << "tb_remove();"
              page << "window.location.reload();"

            end
          }
        end
      end
    else      
      respond_to do |format|
        format.js{
          render :update do |page|
            page << "show_error_msg('nameerror','#{@opportunity.errors.full_messages}','one_field_error_div');"
            page << "jQuery('#loader').hide();"

          end
        }
      end
    end
  end

  def save_status_old
    data = params
    @opportunitytemp = @opportunitystatus = @company.opportunities.find(data[:opportunity][:id])
    @opportunity = @company.opportunities.find(data[:opportunity][:id])
    @stage = current_company.opportunity_stage_types.collect{|e| [e.alvalue,e.id]}- [@opportunity.stage]
    if @opportunity.update_attributes(:stage=> data[:opportunity][:stage],:status_updated_on => Time.zone.now, :reason => data[:notes][:comment])
      if @opportunity.stage == current_company.opportunity_stage_types.find_by_lvalue('Closed/Won').id && data[:opp_matter] && data[:opp_matter][:true].to_i == 1
        flash[:notice] = "#{t(:text_opportunity)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        redirect_to new_opportunity_path(:opportunity_id => @opportunity.id)
      else
        redirect_to opportunities_path
        return
      end
    else
      render :controller=>'opportunities', :action => 'change_status'
    end
  end

  def manage_followup
    @opportunity = current_company.opportunities.find(params[:id])
    if request.post?
      respond_to do |format|
        unless @opportunity.nil?
          if params[:opportunity][:follow_up_done] == "1"
            if @opportunity.update_attributes(:follow_up => nil)
              flash[:notice] = "#{t(:text_opportunity)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
              format.js{
                render :update do |page|
                  page << "tb_remove();"
                  page << "window.location.reload();"
                end
              }
            end
          else
            params[:opportunity][:follow_up] = params[:opportunity][:follow_up_date]
            params[:opportunity][:follow_up] = Time.zone.parse("#{params[:opportunity][:follow_up]}T#{params[:opportunity][:follow_up_time]}").getutc
            if @opportunity.update_attributes(:follow_up => params[:opportunity][:follow_up])
              flash[:notice] = "#{t(:text_opportunity)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
              format.js{
                render :update do |page|
                  page << "tb_remove();"
                  page << "window.location.reload();"
                end
              }
            else
              format.js{
                render :update do |page|
                  page << "show_error_msg('nameerror','Followup date cannot be less than created date.','message_error_div');"
                end
              }
            end
          end
        else
          format.js{
            render :update do |page|
              page << "show_error_msg('nameerror','Followup date cannot be less than created date.','message_error_div');"
            end
          }
        end
      end
    else
      render :layout =>false
    end
  end

  def change_closing_date
    @opportunity = current_company.opportunities.find(params[:id])
    if request.post?
      unless @opportunity.nil?
        respond_to do |format|
          if @opportunity.update_attributes(params[:opportunity])
            flash[:notice] = "#{t(:text_opportunity)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
            format.js{
              render :update do |page|
                page << "tb_remove();"
                page << "window.location.reload();"
              end
            }
          else
            format.js{
              render :update do |page|
                page << "show_error_msg('closing_date_error','Target Closing date cannot be less than created date.','message_error_div');"
                page << "jQuery('#loader').hide();"
              end
            }
          end
        end
      end
      return
    else
      render :layout =>false
    end
  end

  # This method is used to deactivate the opportunity.
  # if opportunity is deactivated then set opportunity stage as "closed/lost".
  def deactivate_opportunity
    msg= "#{t(:text_opportunity)} " "#{t(:flash_was_successful)} "
    Opportunity.transaction do
      @opportunity = @company.opportunities.find(params[:id])
      @opportunity.comments << Comment.new(:title=> 'Opportunity deleted',
        :created_by_user_id=> @current_user.id,
        :comment =>"Opportunity deleted",
        :company_id=> @company.id )
      #      @opportunity.update_attribute('follow_up', nil)
      @opportunity.destroy
      if @opportunity
        msg+="Deleted."
      end
      flash[:notice] = msg
      redirect_to :back
    end
  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:html, :js, :xml)
  end

  def destroy
    Opportunity.transaction do
      @opportunity = @company.opportunities.find(params[:id])
      @opportunity.destroy!
    end
    flash[:notice] = "#{t(:text_opportunity)} " "#{t(:flash_was_successful)} " "Deleted."
    respond_to do |format|
      format.html{
        redirect_to :back
      }
      format.js{
        render :update do |page|
          page << "tb_remove()"
          page << "window.location.reload()"
        end
      }
      format.xml  { head :ok }
    end
  end

  def get_company_source_name
    #lvalue = current_company.company_sources.find(params[:source]).lvalue
    get_available_campaigns
    render :update do |page|
      page << "jQuery('#campaign_combo').show();"
      page.replace_html"campaign_combo1" , :partial => "campaigns"
    end
  end

  # This method is used to search a opportunity.
  def search
    data = params
    @opportunities = get_opportunities(:query => data[:query], :page => 1)
    @perpage = params[:per_page].present? ? params[:per_page] : 25 # added for changing pagination limit - do not remove -- Supriya
    @opportunities = @opportunities.paginate :page => data[:page], :per_page => @perpage
    respond_to do |format|
      format.js   { render :action => :index }
      format.xml  { render :xml => @opportunities.to_xml }
    end
  end

  # As the name suggested this method is used to display selected opportunity on the view.
  def display_selected_opportunity
    params[:search] ||= {} #to set params[:search] if params is nil Bug 9871
    data=params
    @mode_type = params[:mode_type] #passed from the application.js to set the mode type in view
    @opportunities=[]
    unless data[:q].blank?
      if get_employee_user.employee.my_opportunities == true
        @opportunities = @company.opportunities.search "*" + data[:q] + "*", :with =>{"assigned_to_employee_user_id = ?",@current_user.id}, :limit => 10000
      else
        @opportunities = @company.opportunities.search "*" + data[:q] + "*", :limit => 10000
      end
      @perpage = params[:per_page].present? ? params[:per_page] : 25 # added for changing pagination limit - do not remove -- Supriya
      @opportunities = @opportunities.paginate :page => data[:page], :per_page => @perpage
    else
      if @mode_type == "MY"
        @opportunities = @company.opportunities.find_my_opportunity(data,@current_user.id,25,@company_id)
      else
        @opportunities = @company.opportunities.find_all_opportunity(data,25,@company_id)
      end
    end
    render :partial => 'opportunity'
  end

  # As the name suggested this method is used to search opportunity on index view.
  def search_opportunity
    data=params
    @search_result =[]
    unless data[:q].blank?
      if get_employee_user.employee.my_opportunities == true
        @search_result = @company.opportunities.search "*" + data[:q] + "*", :with =>{"assigned_to_employee_user_id = ?",@current_user.id}, :limit => 10000
      else
        @search_result = @company.opportunities.search "*" + data[:q] + "*", :limit => 10000
      end
    else      
      if get_employee_user.employee.my_opportunities == true
        @search_result = @company.opportunities.find(:all, :conditions => ["assigned_to_employee_user_id= ?",@current_user.id])
      else
        @search_result = @company.opportunities.find(:all)
      end
    end
    render :partial=> 'opportunity_auto_complete', :object => @search_result
  end

  # This method is used to gets the manage opportunity page sorted when my and all radio button is clicked
  # This method is used to populate all the available campaigns, when user select source of opportunity as a campaign.
  def get_available_campaigns
    @campaigns = []
    @campaigns = @company.campaigns.select { |e| e.mail_sent  }
  end

  # def uplad_document and def upload methods are now moved to document_homes controller with feature #7991. - Rahul Patil 9th Aug 2011
  def common_opportunity_search
    closed_won= current_company.opportunity_stage_types.find_by_lvalue('Closed/Won')
    closed_lost= current_company.opportunity_stage_types.find_by_lvalue('Closed/Lost')
    closed_array=[closed_won.id,closed_lost.id]
    all_array = current_company.opportunity_stage_types.all(:conditions => ["id NOT IN (?)", closed_array]).collect(&:id)
    unless params[:q].blank?
      if get_employee_user.employee.my_opportunities == true
        @matching_opportunities = @company.opportunities.search "*" + params[:q] + "*", :with => {:assigned_to_employee_user_id => @current_user.id, :stage => all_array}
      else
        @matching_opportunities = @company.opportunities.search "*" + params[:q] + "*", :with => {:stage => all_array}
      end
    else
      if get_employee_user.employee.my_opportunities == true
        @matching_opportunities = @company.opportunities.all(:order => 'name ASC', :conditions => ["assigned_to_employee_user_id = ? AND stage NOT IN (?)", @current_user.id, closed_array])
      else
        @matching_opportunities = @company.opportunities.all(:order => 'name ASC', :conditions => ["stage NOT IN (?)", closed_array])
      end
    end
    render :partial=> 'common_opportunity_search', :object => @matching_opportunities
  end

  def clear_follow_up_date
    @opportunity = @company.opportunities.find(params[:id])
    @opportunity.update_attribute(:follow_up,nil)
    render :update do |page|
      page << "jQuery('#upcoming_loader').hide();"
      page << "window.location.reload()"
    end
  end

  def sort_opportunities_columns
    params[:dir] = params[:dir] ==  'down' ? 'up' : 'down'
    sort = params[:dir].eql?("up")? "asc" : "desc"
    @ord = "#{params[:col]+ ' ' + sort}"
    params[:order] = @ord.nil?? 'opportunities.name ASC' : @ord    
    @opportunities = @company.opportunities.find_all_opportunity(params,25)
    @load_popup = true
    render :partial => 'opportunity'
  end

  private

  # This is internal method which is used to get perticular or all opportunities.
  def get_opportunities(status,ord=nil)
    ord.blank? ? ord='created_at desc' : ord
    case status
    when "MY_CONT"
      @mode_type = "MY_CONT"
      @opportunities = @company.opportunities.all(
        :conditions => ["assigned_to_employee_user_id = ?", @current_user.id],
        :order => ord )
    else
      @mode_type = "All_CONT"
      @opportunities = @company.opportunities.all(:order => ord)
    end
  end

  def get_report_favourites
    @opps_fav = CompanyReport.all(:conditions => ["company_id = ? AND employee_user_id = ? AND report_type = ?", @company.id, @emp_user_id, 'Opportunity'])
  end

  def get_base_data
    @company = @company || current_company
    @emp_user_id=  @emp_user_id || get_employee_user_id
    @current_user = @current_user || current_user
  end

  def no_action_handled_opportunities
    redirect_to :action => "index"
  end

  def show_action_error_handled_opportunities
    if params[:action] == "show"
      redirect_to :action => "edit"
    end
  end

end
