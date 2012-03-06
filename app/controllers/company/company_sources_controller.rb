class Company::CompanySourcesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('company_sources)",:only=>:index

  layout "admin"
   
  def index
    @sources = @company.company_sources
  end
  
  def new
    @source = @company.company_sources.new
    render :layout=>false
  end

  def create
    company_sources = @company.company_sources
    company_sourcescount = company_sources.count
    if company_sourcescount > 0
      params[:source][:sequence] = company_sourcescount+1
    end
    @source = CompanySource.new(params[:source].merge(:lvalue=>params[:source][:alvalue]))
    @source.valid?
    if  @source.errors.empty?
      company_sources << @source     
    end
    render :update do |page|
      unless !@source.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice', "Source was successfully created")
        page<<"window.location.href='#{manage_company_utilities_path('company_sources',:linkage=>"contacts-opportunities")}';"
      else
        page.call('show_msg','nameerror',@source.errors.on(:alvalue))
      end
    end
  end

  def edit
    @source = CompanySource.find(params[:id])
    render :layout=>false
  end
  
  def update
    @source = CompanySource.find(params[:id])
    @source.attributes = params[:source].merge(:lvalue=>params[:source][:alvalue])

    @source.valid?
    if @source.errors.empty?
      @source.save
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@source.errors.empty?
            active_deactive = find_model_class_data('company_sources')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'company_sources', :header=>"Source", :modelclass=> 'company_sources',:linkage=>"contacts-opportunities"})
            page<< 'tb_remove();'
            page<<"window.location.href='#{manage_company_utilities_path('company_sources',:linkage=>"contacts-opportunities")}';"
            page.call('common_flash_message_name_notice', "Source was successfully updated")
          else
            page.call('show_msg','nameerror',@source.errors.on(:alvalue))
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @source = @company.company_sources.find_only_deleted(params[:id])
    unless @source.blank?
      @source.update_attribute(:deleted_at, nil)      
      set_sequence_for_lookups(@company.company_sources)
    end
    respond_to do |format|
      flash[:notice] = "Source '#{@source.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('company_sources',:linkage=>"contacts-opportunities")) }
      format.xml  { head :ok }
    end
  end

end
