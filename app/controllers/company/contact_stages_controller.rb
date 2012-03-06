class Company::ContactStagesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('contact_stages')",:only=>:index

  layout "admin"
  
  def index    
  end
  
  def new
    @contact_stage = @company.contact_stages.new
    render :layout=>false
  end

  def create
    contact_stages = @company.contact_stages
    contact_stagescount = contact_stages.count
    if contact_stagescount > 0
      params[:contact_stage][:sequence] = contact_stagescount+1
    end
    lvalue = params[:contact_stage][:lvalue].blank? ? params[:contact_stage][:alvalue] : params[:contact_stage][:lvalue]
    @contact_stage = ContactStage.new(params[:contact_stage].merge(:lvalue=>lvalue))
    if @contact_stage.valid? && @contact_stage.errors.empty?
      contact_stages << @contact_stage     
    end
    render :update do |page|
      unless !@contact_stage.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice',"Contact Stage was successfully created")
        page<<"window.location.href='#{manage_company_utilities_path('contact_stages',:linkage=>"contacts")}';"
      else
        page.call('show_msg','nameerror',@contact_stage.errors.on(:alvalue))
      end
    end
  end

  def edit
    @contact_stage = ContactStage.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @contact_stage = ContactStage.find(params[:id])
    lvalue = params[:contact_stage][:lvalue].blank? ? params[:contact_stage][:alvalue] : params[:contact_stage][:lvalue]
    @contact_stage.attributes = params[:contact_stage].merge(:lvalue =>lvalue)
    if @contact_stage.valid? && @contact_stage.errors.empty?
      @contact_stage.save
    end    
    respond_to do |format|
      format.js {
        render :update do |page|
        unless !@contact_stage.errors.empty?
          active_deactive = find_model_class_data('contact_stages')
          page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'contact_stages', :header=>"Stage", :modelclass=> 'contact_stages',:linkage=>"contacts"})
          page<< 'tb_remove();'
          page<<"window.location.href='#{manage_company_utilities_path('contact_stages',:linkage=>"contacts")}';"
          page.call('common_flash_message_name_notice',"Contact Stage was successfully updated")
        else
            page.call('show_msg','nameerror',@contact_stage.errors.on(:alvalue))
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @contact_stage = @company.contact_stages.find_only_deleted(params[:id])
    unless @contact_stage.blank?
      @contact_stage.update_attribute(:deleted_at, nil)      
      set_sequence_for_lookups(@company.contact_stages)
    end    
    respond_to do |format|      
      flash[:notice] = "Contact Stage '#{@contact_stage.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('contact_stages',:linkage=>"contacts")) }
      format.xml  { head :ok }      
    end
  end
  
 end
