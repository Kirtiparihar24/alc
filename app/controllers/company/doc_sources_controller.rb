class Company::DocSourcesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('doc_sources')",:only=>:index

  layout "admin"

  def index
  end
  
  def new
    @doc_source = @company.doc_sources.new
    render :layout=>false
  end

  def create
    doc_sources = @company.doc_sources
    doc_sourcescount = doc_sources.count
    if doc_sourcescount > 0
      params[:doc_source][:sequence] = doc_sourcescount+1
    end
    @doc_source = DocSource.new(params[:doc_source].merge(:lvalue=>params[:doc_source][:alvalue]))
    @doc_source.valid?
    if  @doc_source.errors.empty?
      @company.doc_sources << @doc_source      
    end
    render :update do |page|
      unless !@doc_source.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice', "Document Source was successfully created")
        page<<"window.location.href='#{manage_company_utilities_path('doc_sources',:linkage=>"documents-matter_facts")}';"
      else
        page.call('show_msg','nameerror',@doc_source.errors.on(:alvalue))
      end
    end
  end

  def edit
    @doc_source = DocSource.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @doc_source = DocSource.find(params[:id])
    @doc_source.attributes = params[:doc_source].merge(:lvalue=>params[:doc_source][:alvalue])
    @doc_source.valid?
    if @doc_source.errors.empty?
      @doc_source.save
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@doc_source.errors.empty?
            page<< 'tb_remove();'
            active_deactive = find_model_class_data('doc_sources')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'doc_sources', :header=>"Document Source", :modelclass=> 'doc_sources',:linkage=>"documents-matter_facts"})
            page.call('common_flash_message_name_notice', "Document Source was successfully updated")
            page<<"window.location.href='#{manage_company_utilities_path('doc_sources',:linkage=>"documents-matter_facts")}';"
          else
            page.call('show_msg','nameerror',@doc_source.errors.on(:alvalue))
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @doc_source = @company.doc_sources.find_only_deleted(params[:id])
    unless @doc_source.blank?
      @doc_source.update_attribute(:deleted_at, nil)      
      set_sequence_for_lookups(@company.doc_sources)
    end
    respond_to do |format|
      flash[:notice] = "Document Source '#{@doc_source.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('doc_sources',:linkage=>"documents-matter_facts")) }
      format.xml  { head :ok }
    end
  end
  
end
