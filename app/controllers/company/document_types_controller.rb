class Company::DocumentTypesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :filter_contacts
  before_filter :get_company
  before_filter :get_document_type, :only =>[:edit,:update]
  before_filter "url_check('opportunity_stage_types')",:only=>:index

  layout "admin"

  def index
  end

  def new
    @document_type = @company.document_types.new
    render :layout=>false
  end

  def create
    document_types = @company.document_types
    document_typescount = document_types.count
    if document_typescount > 0
      params[:document_type][:sequence] = document_typescount+1
    end
    @document_type = DocumentType.add_document_type(@company,params)
    if @document_type.errors.empty?
      document_types << @document_type
    end
    render :update do |page|
      unless !@document_type.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice',"Document Type was successfully created")
        page<<"window.location.href='#{manage_company_utilities_path('document_types',:linkage=>"documents")}';"
      else
        page.call('show_msg','nameerror',@document_type.errors.on(:alvalue))
      end
    end
  end

  def edit
    render :layout=>false
  end

  def update
    respond_to do |format|
      format.js {
        render :update do |page|
          if @document_type.update_attributes(params[:document_type].merge(:lvalue=>params[:document_type][:alvalue]))
            active_deactive = find_model_class_data('document_types')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'document_types', :header=>"Document Type", :modelclass=> 'document_types',:linkage=>"documents"})
            page<< 'tb_remove();'
            page.call('common_flash_message_name_notice',"Document Type was successfully updated")
            page<<"window.location.href='#{manage_company_utilities_path('document_types',:linkage=>"documents")}';"
          else
            page.call('show_msg','nameerror',@document_type.errors.on(:alvalue))
          end
        end
      }
    end
  end
  
  def get_document_type
    @document_type = DocumentType.find(params[:id])
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @document_type = @company.document_types.find_only_deleted(params[:id])
    unless @document_type.blank?
      @document_type.update_attribute(:deleted_at, nil)      
      set_sequence_for_lookups(@company.document_types)
    end
    respond_to do |format|
      flash[:notice] = "Document Type '#{@document_type.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('document_types',:linkage=>"documents")) }
      format.xml  { head :ok }
    end
  end
  
end