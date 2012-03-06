class Company::DocumentCategoriesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('document_categories')",:only=>:index

  layout "admin"
  
  def index
  end
  
  def new
    @doc_category = @company.document_categories.new
    render :layout=>false
  end

  def create
    document_categories = @company.document_categories
    document_categoriescount = document_categories.count
    if document_categoriescount > 0
      params[:doc_category][:sequence] = document_categoriescount+1
    end
    lvalue = params[:doc_category][:lvalue].blank? ? params[:doc_category][:alvalue] : params[:doc_category][:lvalue]
    @doc_category = DocumentCategory.new(params[:doc_category].merge(:lvalue=>lvalue))
    @doc_category.valid?
    if  @doc_category.errors.empty?      
      @company.document_categories << @doc_category
      create_documentsubcategory_for_company(@company,params[:doc_category][:lvalue])
    end
    render :update do |page|
      unless !@doc_category.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice', "Document Category was successfully created")
        page<<"window.location.href='#{manage_company_utilities_path('document_categories',:linkage=>'documents-links')}';"
      else
        page.call('show_msg','nameerror',@doc_category.errors.on(:alvalue))
      end
    end
  end

  def edit
    @doc_category = DocumentCategory.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @doc_category = DocumentCategory.find(params[:id])
    lvalue = params[:doc_category][:lvalue].blank? ? params[:doc_category][:alvalue] : params[:doc_category][:lvalue]
    @doc_category.attributes = params[:doc_category].merge(:lvalue=>lvalue)
    @doc_category.valid?
    if @doc_category.errors.empty?
      @doc_category.save
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@doc_category.errors.empty?
            active_deactive = find_model_class_data('document_categories')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'document_categories', :header=>"Document Category", :modelclass=> 'document_categories',:linkage=>'documents-links'})
            page<< 'tb_remove();'
            page.call('common_flash_message_name_notice', "Document Category was successfully updated")
            page<<"window.location.href='#{manage_company_utilities_path('document_categories',:linkage=>'documents-links')}';"
          else
            page.call('show_msg','nameerror',@doc_category.errors.on(:alvalue))
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @doc_category = @company.document_categories.find_only_deleted(params[:id])
    unless @doc_category.blank?
      @doc_category.update_attribute(:deleted_at, nil)      
      set_sequence_for_lookups(@company.document_categories)
    end
    respond_to do |format|
      flash[:notice] = "Document Category '#{@doc_category.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('document_categories',:linkage=>'documents-links')) }
      format.xml  { head :ok }
    end
  end

  # This action is specially used for de-activating the record.
  # Supriya Surve - 24th May 2011 - 08:17
  def destroy
    doc_category = @company.document_categories.find(params[:id])
    docs_length = doc_category.documents.length
    links_length = Link.find(:all, :conditions => ["company_id = #{@company.id} and category_id = #{params[:id]}"]).length
    docslength = docs_length > 0
    linkslength = links_length > 0
    if docslength || linkslength
      message = false
      msg=", #{docs_length} documents linked" if docslength && !linkslength
      msg=", #{links_length} links linked" if linkslength && !docslength
      msg=", #{docs_length} documents and #{links_length} links linked" if linkslength && docslength
    else
      message = true
      doc_category.destroy
      set_sequence_for_lookups(@company.document_categories)
    end
    respond_to do |format|
      if message
        flash[:notice] = "Document Category '#{doc_category.lvalue}' is successfully deactivated."
      else
        flash[:error] = "Document Category '#{doc_category.lvalue}' can not be deactivated#{msg}."
      end
      format.html { redirect_to(manage_company_utilities_path('document_categories')) }
      format.xml  { head :ok }
    end
  end
  
end