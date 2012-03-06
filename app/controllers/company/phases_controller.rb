class Company::PhasesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('phases')",:only=>:index

  layout "admin"

  def index
  end
  
  def new
    @phase = @company.phases.new
    render :layout=>false
  end

  def create
    phases = @company.phases
    phasescount = phases.count
    if phasescount > 0
      params[:phase][:sequence] = phasescount+1
    end
    @phase = Phase.new(params[:phase].merge(:lvalue=>params[:phase][:alvalue]))
    @phase.valid?
    if  @phase.errors.empty?
      phases << @phase      
    end
    render :update do |page|
      unless !@phase.errors.empty?        
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice', "Phase was successfully created")
        page<<"window.location.href='#{manage_company_utilities_path('phases',:linkage=>"matters-documents-matter_tasks")}';"
      else
        page.call('show_msg','nameerror',@phase.errors.on(:alvalue))
      end
    end
  end

  def edit
    @phase = Phase.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @phase = Phase.find(params[:id])
    @phase.attributes = params[:phase].merge(:lvalue=>params[:phase][:alvalue])
    @phase.valid?
    if @phase.errors.empty?
      @phase.save
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@phase.errors.empty?
            active_deactive = find_model_class_data('phases')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'phases', :header=>"Phase", :modelclass=> 'phases',:linkage=>"matters-documents-matter_tasks"})
            page<< 'tb_remove();'
            page<<"window.location.href='#{manage_company_utilities_path('phases',:linkage=>"matters-documents-matter_tasks")}';"
            page.call('common_flash_message_name_notice', "Phase was successfully updated")
          else
            page.call('show_msg','nameerror',@phase.errors.on(:alvalue))
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @phase = @company.phases.find_only_deleted(params[:id])
    unless @phase.blank?
      @phase.update_attribute(:deleted_at, nil)
      company = @phase.company
      set_sequence_for_lookups(company.phases)
    end
    respond_to do |format|
      flash[:notice] = "Phase '#{@phase.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('phases',:linkage=>"matters-documents-matter_tasks")) }
      format.xml  { head :ok }
    end
  end
  
end
