include RepositoriesHelper
class RepositoriesController < ApplicationController
  before_filter :authenticate_user!, :except=>[:do_the_multi_upload]
  before_filter :current_service_session_exists, :except=>[:do_the_multi_upload]
  layout 'application',:except => [:new, :edit,:add_tags,:index, :do_the_multi_upload]
  
  add_breadcrumb "Repository", :repositories_path,:except=>[:index]
  authorize_resource :class => :repository, :except=>[:do_the_multi_upload]
  before_filter :get_base_data, :except=>[:do_the_multi_upload]
  skip_before_filter :verify_authenticity_token

  def mass_upload
    Resque.enqueue(UploadRepository, get_employee_user_id)
    flash[:notice] = "Repository documents are being uploaded from FTP in the background."
    redirect_to repositories_path
  end

  def index
    set_sort_parameters
    session[:category] = params[:category_type] || "All"
    params[:per_page] ||= 25
    @pagenumber=7
    @parent_id= params[:parent_id]
    @folder= @company.folders.find(params[:parent_id]) if params[:parent_id]
    get_folders
    @file_ext = DocumentHome.get_extensions(@company.id,'Company')   
    @recycle_bin = params[:recycle_bin]=="true" ? true : false
    if @recycle_bin
      get_deleted_folders
      add_breadcrumb "<a href='/repositories'>Repository</a>", :repositories_path
      add_breadcrumb "Recycle Bin",repositories_path(:recycle_bin=>true)
    else
      add_breadcrumb "Repository", :repositories_path
    end
    @categories= @company.document_types.all(:select => 'id,alvalue')
    if params[:display_search] || request.xhr?
      render :partial => "repository",:locals =>{:categories=>@categories,:documenthomes=>@documenthomes}
    else
      render :layout => 'application'
    end
  end

  def new
    @msg={:file=>false, :link=>true}
    @document_home=@current_employee_user.document_homes.new(:folder_id=>params[:folder_id])
    @document =@document_home.documents.build
    @link=Link.new
    @categories=  @company.document_types
    render :layout => false
  end
  
  def create
    flag=true
    emp_user_id  =  get_employee_user_id
    data = params[:document_home]
    data[:mapable_type]='Company'
    data[:mapable_id]=@company.id
    data[:company_id] = @company.id
    @categories= @company.document_types
    if params[:upload]=='file'
      data[:access_rights] = 2
      @msg={:file=>true, :link=>false}
      document = params[:document_home][:document_attributes]
      if document
        document[:name]= params[:document_home][:name]
        document[:description]= params[:document_home][:description]
        @document_home = DocumentHome.new(data.merge!(
            :created_by_user_id => @current_user.id, :upload_stage => 1,
            :employee_user_id=>emp_user_id,
            :owner_user_id=>emp_user_id
          )
        )
        @document_home.folder_id = params[:folder_id]
        @document=@document_home.documents.build(document.merge(:company_id=>@company.id,  :employee_user_id=> emp_user_id, :created_by_user_id=>emp_user_id,:doc_type_id=>data[:category_id]))
        @document_home.tag_list= params[:document_home][:tag_array].split(',')
        if @document_home.save
          flash[:notice] = "#{t(:text_document)} #{t(:flash_was_successful)} #{t(:text_created)}"
          flag= false
        end
      end
    elsif params[:upload]=='link'
      @msg={:file=>false, :link=>true}
      @document_home =Link.new(data.merge!(:created_by_user_id => @current_user.id,:created_by_employee_user_id=>emp_user_id))
      @document_home.folder_id = params[:folder_id]
      @document_home.tag_list= params[:document_home][:tag_array].split(',')
      if  @document_home.save!
        flash[:notice] = "Url #{t(:flash_was_successful)} #{t(:text_created)}"
        flag= false
      end
    end
    if flag
      msg = ""
      if @document_home
        for document in @document_home.documents
          msg += document.errors.full_messages.to_sentence
        end
        flash[:error] = msg
      else
        if params[:document_home][:document_attributes].nil?
          msg += "Please select document to upload.<br>"
        end
        if params[:name].nil?
          msg += "Name can't be blank.<br>"
        end
        flash[:error] = msg
      end
    end
    responds_to_parent do
      render :update do |page|
        unless  flag
          page.call("tb_remove")
          page.redirect_to folder_list_repositories_path(:id=>@document_home.folder_id)
          page.replace_html 'altnotice', "<div id='notice' class='message_sucess_div'style='padding-bottom:15px'><span class='icon_message_sucess fl'></span>#{flash[:notice]} </div>"
          page.show 'altnotice'
          page.call("common_flash_message")
          page << "jQuery('#loader').hide();"
          flash[:notice] = nil
        else
          page.hide 'loader1'
          page << "enableAllSubmitButtons('button');"
          page<<"jQuery('#save_rep').val('Upload')"
          page.replace_html 'modal_new_document_error', "<div class='message_error_div'>#{ (flash[:error]).to_s} </div>"
          page.show 'modal_new_document_error'
          page.call("common_error_flash_message")
          page << "jQuery('#loader').hide();"
          flash[:error] = nil
        end
      end
    end
  end

  def edit
    @msg = {:file => params[:type] == 'DocumentHome' ? true : false, :link => params[:type] == 'Link' ? true : false }
    @type = params[:type]
    @categories = @company.document_types
    @document_home = @type == 'DocumentHome'? @company.repository_documents.find(params[:id]) : @company.links.find(params[:id])
  end

  def update
    @type=params[:upload]
    @msg= {:file=> @type=='DocumentHome'? true:false,:link=> @type=='Link'? true:false }
    @categories=  @company.document_types
    @document_home = @type == 'DocumentHome' ? @company.repository_documents.find(params[:id]) : @company.links.find(params[:id])
    @document_home.tag_list = params[:document_home][:tag_array].split(',')
    if @type == 'DocumentHome'
      if  @document_home.update_with_document(params[:document_home] )
        flash[:notice] = 'Document was successfully updated'
      end
    else
      if @document_home.update_attributes(params[:document_home])
        flash[:notice] = 'Link was successfully updated'
      else
        flash[:error] = 'Link was not removed'
      end
    end
    responds_to_parent do
      render :update do |page|
        if @document_home.errors.blank?
          page.call("tb_remove")
          page.call("parent.location.reload")
        else
          page.hide 'loader1'
          page<<"jQuery('#save_rep').disabled=false"
          page<<"jQuery('#save_rep').val('Upload')"
          format_ajax_errors(@document_home, page, "modal_new_document_errors")
          page.call("common_error_flash_message")
          flash[:error] = nil
        end
      end
    end

  end

  def remove_link
    @per_page = params[:per_page].blank? ? 25 : params[:per_page].to_i
    @link= @company.links.find(params[:id])
    @link.delete if @link
    if request.xhr?
      @folders, @files ,@related_to= DocumentHome.tree_node(params[:selected_node], @company, @current_employee_user, @emp_user_id, is_secretary_or_team_manager?, false, @per_page, params)
      render :partial => "document_managers/documents_list", :layout => false
    else
      flash[:notice]= 'Link Deleted Successfully.'
      render_back
    end
  end

  def restore_link
    @per_page = params[:per_page].blank? ? 25 : params[:per_page].to_i
    @link= @company.links.find_only_deleted(params[:id])
    @link.deleted_at=nil
    @link.save(false)
    if request.xhr?
      @folders, @files ,@related_to= DocumentHome.tree_node(params[:selected_node], @company, @current_employee_user, @emp_user_id, is_secretary_or_team_manager?, false, @per_page, params)
      render :partial => "document_managers/documents_list", :layout => false
    end
  end

  def search_document
    name = params[:name].strip
    tag = params[:document_tags].strip
    desc = params[:document_description].strip
    creator = params[:creator].strip
    extension = params[:extension].strip
    include_tag = params[:include_tag]
    date = params[:date]
    date_type = params[:date_type].strip
    date_from = params[:date_from]
    date_to = params[:date_to]
    @categories=  @company.document_types
    @sub_categories = @company.document_sub_categories.find_all_by_category_id(@categories[0].id)
    condition_part = {:document_mapable_type => 'Company'}
    link_condition_part = {:link_mapable_type => 'Company'}
    unless name.blank?
      condition_part.merge!({:document_name => name}) 
      link_condition_part.merge!({:link_name => name})
    end
    unless tag.blank?
      condition_part.merge!({:doc_tag_name => tag})
      link_condition_part.merge!({:tag_name => tag})
    end
    unless desc.blank?
      condition_part.merge!({:document_description => desc})
      link_condition_part.merge!({:link_description => desc})
    end
    unless creator.blank?
      condition_part.merge!({:document_creator_name => creator})
      link_condition_part.merge!({:link_creator_name => creator})
    end
    condition_part.merge!({:document_extension_type => extension}) unless extension.blank?
    date_part = {}
    link_date_part = {}
    if date == '2'
      date_part.merge!({:document_created_date => 1.weeks.ago.to_i..Time.zone.now.to_i})
      link_date_part.merge!({:link_created_date => 1.weeks.ago.to_i..Time.zone.now.to_i})
    end
    if date == '3'
      date_part.merge!({:document_created_date => 1.month.ago.to_i..Time.zone.now.to_i})
      link_date_part.merge!({:link_created_date => 1.month.ago.to_i..Time.zone.now.to_i})
    end
    if date == '4'
      date_part.merge!({:document_created_date => 1.year.ago.to_i..Time.zone.now.to_i})
      link_date_part.merge!({:link_created_date => 1.year.ago.to_i..Time.zone.now.to_i})
    end
    if date == '5'
      date_part.merge!(get_date_on_specified_range(date_type, date_from, date_to))
      link_date_part.merge!(get_date_on_specified_range("Link " + date_type, date_from, date_to))
    end
    with_part = date_part.merge!({:document_mapable_id =>@company.id})
    link_with_part = link_date_part   
    total = 0
    @perpage = (params[:per_page] || 25).to_i
    if condition_part.length == 1 &&  with_part.length == 1  # Means defult search without any filter
      offset = calculate_offset(0, @perpage, params[:page])
      @documenthomes = @company.repository_documents.all(:select => '*, (users.first_name users.last_name) AS assigned_by1 ', :include => 'user', :limit => set_limit(offset, @perpage), :offset => round_to_zero(offset)) 
      if @documenthomes.size < @perpage
        total_document_homes = @perpage*(params[:page].to_i-1)+@documenthomes.size
        offset =  calculate_offset(total_document_homes,@perpage,params[:page])
        temp = @company.links.all(:offset => round_to_zero(offset), :limit => set_limit(offset, @perpage))
        @documenthomes += temp
      end
      total += @company.repository_documents.count
      total += @company.links.count
    else
      offset = calculate_offset(0, @perpage, params[:page])
      documents = Document.current_company(@company.id).search :conditions => condition_part, :with => with_part, :star => true, :offset => round_to_zero(offset),:limit=>set_limit(offset,@perpage)
      documents.compact!
      @documenthomes = documents.collect{|c| c.document_home}
      if @documenthomes.size < @perpage
        total_document_homes = @perpage*(params[:page].to_i-1)+@documenthomes.size
        offset =  calculate_offset(total_document_homes,@perpage,params[:page])
        search_links = Link.current_company(@company.id).search :conditions => link_condition_part, :with => link_with_part, :star => true, :offset => round_to_zero(offset),:limit=>set_limit(offset,@perpage) if params[:extension].blank?
        @documenthomes+=  search_links if search_links
      end
      total += Document.current_company(@company.id).search(:conditions => condition_part, :limit => 10000, :with => with_part, :star => true).count
      total += Link.current_company(@company.id).search(:conditions => link_condition_part, :limit => 10000, :with => link_with_part, :star => true).count if params[:extension].blank?
    end
    @folders =[]
    @repositories = WillPaginate::Collection.new(params[:page] || 1, @perpage, total) 
    @repositories.replace(@documenthomes.to_a)
    @search_result = true # FIXME: hack!
    @categories= current_company.document_types
    render :partial => 'repository', :locals => {:documenthomes=> @documenthomes, :categories => @categories}
  end

  def search_by
    data=params
    company= current_company
    query = data[:search][:text] if data[:search]
    @categories=  @company.document_types
    if query && query.strip == ''
      @documenthomes=  company.repository_documents + company.links
    else
      if data[:search][:by].nil?
        documents = Document.current_company(company.id).search "@(document_name,document_description) *#{query}*", :match_mode=> :extended
        documents.compact!
        document_homes = documents.collect{|c| c.document_home}
        links=company.links.search "@(link_name,link_description) *#{query}*" , :match_mode=> :extended
      else
        if data[:search][:by]=='tag'
          documents = Document.current_company(company.id).search  query, :star => true
          documents.compact!
          document_homes = documents.collect{|c| c.document_home}
          links=company.links.search query, :star => true
        end

        # code for tagsss
      end
      @documenthomes = document_homes + links
      @documenthomes.compact!
    end
    @perpage = params[:per_page].present? ? params[:per_page] : 25
    @categories= company.document_types
    @documenthomes = @documenthomes.paginate(:order=>params[:order],:page => params[:page],:per_page => @perpage)
    @search_by=data[:search][:by]
    render :action=> 'index', :locals => {:documenthomes=> @documenthomes, :categories => @categories,:search_by=>data[:search][:by]}

  end

  def add_tags
    @type = params[:type]
    @document_home = params[:type] == 'DocumentHome' ?  @company.repository_documents.find(params[:id]) : @company.links.find(params[:id])
    if request.post?
      @document_home = params[:type]=='DocumentHome' ?  @company.repository_documents.find(params[:id]) : @company.links.find(params[:id])
      @document_home.tag_list= params[:document_home][:tag_array].split(',')
      if @document_home.save
        flash[:notice] = "Tags were sucessfully #{t(:text_updated)}"
      else
        flash[:error] = "Please fill all mandatory details"
      end
      redirect_to folder_list_repositories_path(:id=>@document_home.folder_id) #(:back)# repositories_path
    end
   
  end
  
  def get_sub_categories
    @sub_categories =  @company.document_sub_categories.all(:conditions => {:category_id => params[:category_id]})
  end

  def create_folder
    @folder = Folder.new()
    @parent_id= params[:parent_id]
    if request.post?
      params[:folder][:created_by_user_id]= @current_user.id
      params[:folder][:employee_user_id]= @emp_user_id
      params[:folder][:company_id]=@company.id
      params[:folder][:livian_access]= !@current_user.role?("lawyer")
      params[:folder][:parent_id]= params[:parent_id] if params[:parent_id]
      params[:folder][:name]=(params[:folder][:name]).strip
      @folder = @company.folders.new(params[:folder])
      respond_to do |format|
        if @folder.save
          flash[:notice] = "#{t(:text_folder)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
          format.js{
            render :update do |page|
              page.call("tb_remove")
              page.redirect_to folder_list_repositories_path(:id=>params[:parent_id])
            end
          }
        else
          format.js{
            render :update do |page|
              errors = "<ul>" + @folder.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
              page << "show_error_msg('one_field_error_div','#{errors}','message_error_div');"
              page << "jQuery('#loader').hide();"
            end
          }
        end
      end
    else
      render :layout=> false
    end
  end

  def folder_list
    set_sort_parameters
    @pagenumber=7
    @parent_id=params[:parent_id] || params[:id] 
    @categories= @company.document_types
    @file_ext = DocumentHome.get_extensions(@company.id,'Company')
    @sub_categories = @company.document_sub_categories.find_all_by_category_id(@categories[0].id)
    @recycle_bin = params[:recycle_bin]
    if @recycle_bin=='true'
      @folder= @company.folders.find_only_deleted(@parent_id) if @parent_id
      get_deleted_folders
    else
      if @parent_id.present?
        @folders=[]
        @parent_id = nil if @parent_id == "0"
        @folder = @company.folders.find(@parent_id) if @parent_id
        get_folders
      else
        @folder=nil
        get_folders
      end
      @recycle_bin=nil
    end
    params[:category_type]||=@category.to_i
    @categories= @company.document_types.all(:select => 'id,alvalue')
    if params[:flash]=="Cancled"
      flash[:notice] ="File(s) Upload interupted. Some of the file(s) may not be uploaded."
    elsif params[:flash].present?
      flash[:notice] ="#{params[:flash]} File(s) Uploaded Sucessfully."
    end
    
    if request.xhr?
      @flag=1
      render :partial=>'repository',:locals => {:documenthomes => @documenthomes, :folders=>@folders, :folder=>@folder, :categories=> @categories}
    end
  end
  
  def get_children
    params[:dir]= params[:dir].chomp.to_i if params[:dir]
    @recylce_bin = params[:recycle_bin]=="true" ? true : false
    unless @recylce_bin
      if params[:dir]==0
        @all_folders= @company.folders.find(:all, :conditions=>folder_sql_conditional_str('parent_id is null',params[:move_for],params[:id]))
      else
        @all_folders= @company.folders.find(:all,  :conditions=>folder_sql_conditional_str('parent_id=?',params[:move_for],params[:id],params[:dir]))
      end
    else
      if params[:dir]==0
        @all_folders= @company.folders.find_only_deleted(:all, :conditions=>folder_sql_conditional_str('parent_id is null',params[:move_for],params[:id]))
      else
        @all_folders= @company.folders.find_only_deleted(:all,  :conditions=>folder_sql_conditional_str('parent_id=?',params[:move_for],params[:id],params[:dir]))
      end
    end
    render :layout=> 'false'
  end

  def move_doc
    if params[:doc_type] == 'document'
      @doc_home = DocumentHome.scoped_by_company_id(@company).find(params[:id])
      @doc_type = "document"
    elsif params[:doc_type] == 'link'
      @doc_home = @company.links.find(params[:id])
      @doc_type = "link"
    end
    render :layout=> false
  end

  def post_move_doc
    if params[:document_home][:doc_type] == 'document'
      @doc_home = DocumentHome.scoped_by_company_id(@company).find(params[:id])
    elsif params[:document_home][:doc_type] == 'link'
      @doc_home = @company.links.find(params[:id])
    end
    err = @doc_home.folder_id.to_s == (params[:document_home][:folder_id]).to_s ? true : false
    @doc_home.folder_id = params[:document_home][:folder_id]
    respond_to do |format|
      if err
        format.js{
          render :update do |page|
            page << "show_error_msg('move_doc_error','Please select destination folder / Selected folder and existing folder are same.','message_error_div');"
          end
        }
      else
        if @doc_home.save
          flash[:notice] = "Document moved sucessfully."
        else
          flash[:notice] ="Unable to move Document."
        end
        format.js{
          render :update do |page|
            page.call("tb_remove")
            page.redirect_to folder_list_repositories_path(:id=>@doc_home.folder_id )
          end
        }
      end
    end
  end

  def move_folder
    if(params[:selected_node] =~ /workspace/)
      @folder = @current_employee_user.folders.find(params[:id])
    elsif(params[:matter_id])
      @folder = Folder.find(params[:id], :conditions =>["mapable_type ='Matter' AND mapable_id =?", params[:matter_id]])
    else
      @folder = @company.folders.find(params[:id])
    end
    if request.post?
      err  = ((@folder.id.to_s == params[:document_home_folder_id].to_s) || (@folder.parent_id.to_s == params[:document_home_folder_id].to_s)||(params[:document_home_folder_id] =="000")) ? true : false
      @folder.update_attribute(:parent_id,params[:document_home_folder_id]) unless err
      respond_to do |format|
        format.js{
          render :update do |page|
            unless err
              page.call("tb_remove")
              if !params[:selected_node].blank?
                page.redirect_to document_managers_path(:selected_node=>params[:selected_node].split('_')[0])
              elsif params[:matter_id]
                page.redirect_to folder_list_matter_document_homes_path(:id=>@folder.parent_id,:matter_id=>params[:matter_id])
              else
                page.redirect_to folder_list_repositories_path(:id=>@folder.parent_id )
              end
            else
              page << "show_error_msg('move_doc_error','Please select destination folder / Selected folder and existing folder are same.','message_error_div');"
            end
          end
        }
      end
    else
      render :layout=> false
    end
  end
  def upload_multi
    @max_upload_size = Max_Attachment_Size
    @folder = (params[:id].present? && !params[:id].eql?("0")) ? @current_company.folders.find(params[:id]) : Folder.new
    @document_home = @current_company.document_homes.new(:folder_id => params[:folder_id])
    @document = @document_home.documents.build
    @categories =  @company.document_types
    render :layout=> false
  end

  #Modified by Kalpit patel for plupload (feature 8375)
  def do_the_multi_upload
    return true if params[:stop]=="true"
    @document_home = DocumentHome.new()
    params[:document_home]= {}
    if params[:file]
      success_count = error_count=0
      params[:document_home].merge!(:access_rights=>2, :employee_user_id=>params[:employee_user_id],
        :created_by_user_id=>params[:current_user_id],:company_id=>params[:company_id],
        :mapable_id=>params[:company_id],:mapable_type=>'Company',:upload_stage=>1,:user_ids=>[params[:employee_user_id]],
        :folder_id=>params[:parent_folder_id],:owner_user_id=>params[:current_user_id])
      @current_company = Company.find(params[:company_id])
      @document_home = @current_company.document_homes.new(params[:document_home])
      filename = params[:name]
      params[:name] = filename.gsub(/[.][^.]+$/,"")
      @document=@document_home.documents.build(:company_id=>params[:company_id],  :employee_user_id=> params[:employee_user_id], :created_by_user_id=>params[:current_user_id], :data => params[:file], :name => params[:name],:doc_type_id=>params[:category_id],:sub_category_id=>params[:sub_category_id], :description=>params[:description])
      @document_home.tag_list= params[:tag_array].split(',') if params[:tag_array]
      if @document_home.save
        success_count+=1
      else
        error_count+=1
      end
    end
    render :nothing => true
  end
  
  private
  def get_base_data
    @company ||=  current_company
    @current_employee_user = @current_employee_user ||  get_employee_user
    @emp_user_id = @emp_user_id || @current_employee_user.id
  end

  private
  def one_if_zero(num)
    num > 0 ? num : 1
  end
  
  public
  def get_folders
    @category  =  session[:category] || "All"
    @category ||= "All"
    @folders = []
    @documenthomes = []
    total  = 0
    @perpage = (params[:per_page] || 25).to_i
    params[:page] ||=1
    # If we are showing data for a selected folder
    if @folder
      # Total pages count is addition of all the folders + files + links records,
      # because we are paginating across all the three.
      total += @folder.children.count
      total += @folder.files.has_category(@category).count
      total += @folder.links.has_category(@category).count
      tot_page = (total.to_f / @perpage.to_f).ceil
      params[:page] = tot_page if (tot_page != 0 && tot_page < params[:page].to_i)
      # Paginate the folders in 25 per page
      @folders = @folder.children.paginate(:per_page => @perpage, :page => params[:page], :order => @folder_sort)
      if @folders.size < @perpage
        # Paginate the files for remaining records (if there were fewer folders than 25)
        offset =  calculate_offset(@folders.total_entries,@perpage,params[:page])
        @documenthomes = Document.find_by_sql("select document_homes.*,documents.* from documents
left outer join document_homes on document_homes.id = documents.document_home_id
left outer join users on document_homes.#{@column} = users.id
where  documents.id in (select  max(docs.id)  from documents docs
inner join document_homes dh on dh.id=docs.document_home_id group by dh.id) and document_homes.folder_id = #{@folder.id} and document_homes.mapable_type ='Company' and document_homes.mapable_id ='#{@company.id}' and document_homes.company_id = '#{@company.id}' and document_homes.deleted_at is NULL  order by #{@doc_sort} LIMIT #{set_limit(offset, @perpage)} OFFSET #{round_to_zero(offset)}")
      end
      if (@folders.size + @documenthomes.size) < @perpage
	      total_document_homes = @perpage*(params[:page].to_i-1)+@documenthomes.size
	      offset =  calculate_offset(total_document_homes,@perpage,params[:page])
        # Paginate the links for remaning records (if there were fewer than 25 folders & files)
        temp = @folder.links.has_category(@category).find(:all,:include=>[:created_by],:offset=>round_to_zero(offset),:limit=>set_limit(offset,@perpage),:order=>@link_sort)
        @documenthomes += temp
      end
      # We are showing data for root folders
    else
      # Total pages count is addition of all the folders + files + links records,
      # because we are paginating across all the three.
      # all the root folders + all the file outside any folder + all the links outside any folder
      total += @company.folders.repository_root_folders.count #find(:all, :conditions=> ['parent_id is null and for_workspace=false']).count
      total += @company.repository_documents.repository_root_documents.has_category(@category).count
      total += @company.links.root_links.has_category(@category).count
      tot_page = (total.to_f / @perpage.to_f).ceil
      params[:page] = tot_page if (tot_page != 0 && tot_page < params[:page].to_i)
      # Paginate the folders in 25 per page
      @folders = @company.folders.paginate(:per_page => @perpage, :page => params[:page], :conditions=> ['parent_id is null'],:order=>@folder_sort)
      if @folders.size < @perpage
	      # Paginate the files for remaining records (if there were fewer folders than 25)
  	    offset =  calculate_offset(@folders.total_entries,@perpage,params[:page])
        @documenthomes = Document.find_by_sql("select document_homes.*,documents.* from documents
left outer join document_homes on document_homes.id = documents.document_home_id
left outer join users on document_homes.#{@column} = users.id
where  documents.id in (select  max(docs.id)  from documents docs
inner join document_homes dh on dh.id=docs.document_home_id group by dh.id) and document_homes.folder_id is NULL and document_homes.mapable_type ='Company' and document_homes.mapable_id =#{@company.id} and document_homes.company_id = #{@company.id} and document_homes.deleted_at is NULL  order by  #{@doc_sort} LIMIT #{set_limit(offset, @perpage)} OFFSET #{round_to_zero(offset)}")
      end
      if (@folders.size + @documenthomes.size) < @perpage
        # Paginate the links for remaning records (if there were fewer than 25 folders & files)
	      total_document_homes = @perpage*(params[:page].to_i-1)+@documenthomes.size
	      offset =  calculate_offset(total_document_homes,@perpage,params[:page])
        temp = @company.links.has_category(@category).all(:include => :created_by, :offset => round_to_zero(offset), :limit => set_limit(offset, @perpage), :conditions => ['folder_id IS NULL'], :order => @link_sort)
        @documenthomes +=  temp
      end
    end
    # Because the paginate is used on three different type of models (above)
    # we needed a custom paginate object to generate the view, using the will_paginate
    # helper. Here we are just creating it manually.
    @repositories = WillPaginate::Collection.new(params[:page] || 1, @perpage, total) 
    @repositories.replace(@folders.to_a + @documenthomes.to_a)
  end

  def get_deleted_folders
    if @folder
      @folders = @folder.children.find_only_deleted(:all, :order => @folder_sort)
      @documenthomes= @folder.files.find_only_deleted(:all, :include => [:documents, :user], :order => @doc_sort) + @folder.links.find_only_deleted(:all, :include => [:created_by], :order => @link_sort)
    else
      folders_ids = @company.folders.find_only_deleted(:all, :select => :id, :conditions => ['permanent_deleted_at IS NULL'], :order => @folder_sort)
      ids = folders_ids.collect{|fol| fol.id}
      @folders = @company.folders.find_only_deleted(:all, :conditions => ['permanent_deleted_at IS NULL AND (parent_id IS NULL OR parent_id NOT IN (?))', ids], :order => @folder_sort)
      if ids.size > 0
        @documenthomes = @company.repository_documents.find_only_deleted(:all, :include => [:documents,:user], :order =>  @doc_sort, :conditions => ['document_homes.permanent_deleted_at IS NULL AND (folder_id IS NULL OR folder_id NOT IN (?))', ids]) + @company.links.find_only_deleted(:all,:include =>[:created_by], :conditions => ['permanent_deleted_at IS NULL AND (folder_id IS NULL OR folder_id NOT IN (?))', ids], :order => @link_sort)
      else
        @documenthomes = @company.repository_documents.find_only_deleted(:all, :include => [:documents, :user], :order => @doc_sort, :conditions =>  ['document_homes.permanent_deleted_at IS NULL AND (folder_id IS NULL OR folder_id NOT IN (?))', ids]) + @company.links.find_only_deleted(:all,:include =>[:created_by], :conditions => ['permanent_deleted_at IS NULL'], :order => @link_sort)
      end
    end
  end
	private
	# calculate offset for pagination if
  # folder is 40 and per page is 25
  # document is 35 so in page 2 15 folders and 10 document is displayed
  # so in next page offset set to 10
  # and if further document is possible offset becomes 10+25
  def calculate_offset(total_parent_entries,per_page,page_no)
    page_no ||=1
    ((per_page.to_i*page_no.to_i)-(total_parent_entries.to_i+per_page.to_i))
  end
  # -5,25 if offset is negative i.e when displaying 20 folders and 5 documents

  def set_limit(offset,per_page)
    offset <=0 ? offset+per_page.to_i : per_page.to_i
	end

  def round_to_zero(offset)
    offset <= 0 ? 0 : offset
  end

  #This Method is used for setting parameters for column sorting :Pratik AJ 07/09/2011
  def set_sort_parameters
    @doc_sort, @folder_sort, @link_sort = ""
    @column = "employee_user_id"
    sort = params[:dir].eql?("up")? "asc" : "desc"
    params[:col] = "document_homes.updated_at" unless params[:col]
    @doc_sort = "#{params[:col]} #{sort}"
    @link_sort = "links.#{@doc_sort}" unless (params[:col] == "data_file_size" || params[:col] == "extension")
    if params[:col] == "document_homes.updated_at"
      @folder_sort = "folders.updated_at #{sort}"
      @link_sort = "links.updated_at #{sort}"#        @doc_sort += " ,users.first_name #{secondary_sort}, users.last_name #{secondary_sort}"
    elsif params[:col] == "name"
      @folder_sort = "folders.#{@doc_sort}"
    elsif params[:col] == "created_by"
      @doc_sort = "users.first_name #{sort}, users.last_name #{sort}"
      @link_sort = "users.first_name #{sort}, users.last_name #{sort}"
    end
    if params[:secondary_sort]
      secondary_sort = params[:secondary_sort_direction].eql?("up")? "asc" : "desc"
      #      @doc_sort = "#{params[:secondary_sort]} #{secondary_sort}"
      #      @link_sort = "links.#{@doc_sort}" unless (params[:secondary_sort] == "data_file_size" || params[:secondary_sort] == "extension")
      if params[:secondary_sort] == "document_homes.updated_at"
        @folder_sort += " ,folders.updated_at #{secondary_sort}"
        @link_sort += " ,links.updated_at #{secondary_sort}"
      elsif params[:secondary_sort] == "name"
        @folder_sort += " ,folders.#{@doc_sort}"
      elsif params[:secondary_sort] == "created_by"
        @doc_sort += " ,users.first_name #{secondary_sort}, users.last_name #{secondary_sort}"
        @link_sort += " ,users.first_name #{secondary_sort}, users.last_name #{secondary_sort}"
      end
    end
  end
end
