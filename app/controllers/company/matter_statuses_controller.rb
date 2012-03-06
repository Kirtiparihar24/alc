class Company::MatterStatusesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('matter_statuses')",:only=>:index

  layout "admin"
  
  def index
  end
  
  def new
    @matter_status = @company.matter_statuses.new
    render :layout=>false
  end

  def create
    matter_statuses = @company.matter_statuses
    matter_statusescount = matter_statuses.count
    if matter_statusescount > 0
      params[:matter_status][:sequence] = matter_statusescount+1
    end
    lvalue = params[:matter_status][:lvalue].blank? ? params[:matter_status][:alvalue] : params[:matter_status][:lvalue]
    @matter_status = MatterStatus.new(params[:matter_status].merge(:lvalue=>lvalue))
    @matter_status.valid?
    if  @matter_status.errors.empty?
      matter_statuses << @matter_status      
    end
    render :update do |page|
      unless !@matter_status.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice', "Status was successfully created")
        page<<"window.location.href='#{manage_company_utilities_path('matter_statuses')}';"
      else
        page.call('show_msg','nameerror',@matter_status.errors.on(:alvalue))
      end
    end
  end

  def edit
    @matter_status = MatterStatus.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @matter_status = MatterStatus.find(params[:id])
    lvalue = params[:matter_status][:lvalue].blank? ? params[:matter_status][:alvalue] : params[:matter_status][:lvalue]
    @matter_status.attributes = params[:matter_status].merge(:lvalue=>lvalue)
    @matter_status.valid?
    if @matter_status.errors.empty?
      @matter_status.save
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@matter_status.errors.empty?
            active_deactive = find_model_class_data('matter_statuses')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'matter_statuses', :header=>"Matter Status", :modelclass=> 'matter_statuses'})
            page<< 'tb_remove();'
            page.call('common_flash_message_name_notice', "Status was successfully updated")
            page<<"window.location.href='#{manage_company_utilities_path('matter_statuses')}';"
          else
            page.call('show_msg','nameerror',@matter_status.errors.on(:alvalue))
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @matter_status = @company.matter_statuses.find_only_deleted(params[:id])
    unless @matter_status.blank?
      @matter_status.update_attribute(:deleted_at, nil)      
      set_sequence_for_lookups(@company.matter_statuses)
    end
    respond_to do |format|
      flash[:notice] = "Matter Status '#{@matter_status.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('matter_statuses')) }
      format.xml  { head :ok }
    end
  end

  # This action is specially used for de-activating the record.
  # Supriya Surve - 24th May 2011 - 08:17
  def destroy
    matter_status = @company.matter_statuses.find(params[:id])
    matterslength = Matter.find(:all, :conditions => ["company_id = #{@company.id} and status_id = #{params[:id]}"]).length
    if matterslength > 0
      message = false
    else
      message = true      
      matter_status.destroy
      set_sequence_for_lookups(@company.matter_statuses)
    end
    respond_to do |format|
      if message
        flash[:notice] = "Matter Status '#{matter_status.lvalue}' is successfully deactivated."
      else
        flash[:error] = "Matter Status '#{matter_status.lvalue}' can not be deactivated, #{matterslength} Matters linked."
      end
      format.html { redirect_to(manage_company_utilities_path('matter_statuses')) }
      format.xml  { head :ok }
    end
  end

end
