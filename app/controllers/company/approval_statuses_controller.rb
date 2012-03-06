class Company::ApprovalStatusesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('approval_statuses')",:only=>:index
  layout "admin"
  
  def index

  end
  
  def new
    @approval_status = @company.approval_statuses.new
    render :layout=>false
  end

  def create
    approval_status = @company.approval_statuses
    approval_statuscount = approval_status.count
    if approval_statuscount > 0
      params[:approval_status][:sequence] = approval_statuscount+1
    end
    lvalue = params[:approval_status][:lvalue].blank? ? params[:approval_status][:alvalue] : params[:approval_status][:lvalue]
    @approval_status_type = ApprovalStatus.new(params[:approval_status].merge(:lvalue=>lvalue))
    if @approval_status_type.valid? && @approval_status_type.errors.empty?
      @company.approval_statuses << @approval_status_type
    end
    render :update do |page|
      unless !@approval_status_type.errors.empty?
        page<< 'tb_remove();'
        flash[:notice]= "Approval Status was successfully created"
        page<<"window.location.href='#{manage_company_utilities_path('approval_statuses')}';"
      else
        page.call('show_msg','nameerror',@approval_status_type.errors.on(:alvalue))
      end
    end
  end

  def edit
    @approval_status_type = ApprovalStatus.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @approval_status_type = ApprovalStatus.find(params[:id])
    lvalue = params[:approval_status][:lvalue].blank? ? params[:approval_status][:alvalue] : params[:approval_status][:lvalue]
    @approval_status_type.attributes = params[:approval_status].merge(:lvalue =>lvalue)
    if @approval_status_type.valid? && @approval_status_type.errors.empty?
      @approval_status_type.save
    end

    respond_to do |format|
      format.js {
        render :update do |page|
        unless !@approval_status_type.errors.empty?
          active_deactive = find_model_class_data('approval_statuses')
          page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'approval_statuses', :header=>"Approval", :modelclass=> 'approval_statuses'})
          page<< 'tb_remove();'
          page<<"window.location.href='#{manage_company_utilities_path('approval_statuses')}';"
          flash[:notice] = "Approval Status was successfully updated"
        else
            page.call('show_msg','nameerror',@approval_status_type.errors.on(:alvalue))
          end
        end
      }
    end
  end

  def show
    @approval_status_type = @company.approval_statuses.find_only_deleted(params[:id])
    unless @approval_status_type.blank?
      @approval_status_type.update_attribute(:deleted_at, nil)
      set_sequence_for_lookups(@company.approval_statuses)
    end
    respond_to do |format|
      flash[:notice] = "Approval Status '#{@approval_status_type.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('approval_statuses')) }
      format.xml  { head :ok }
    end
  end
end
