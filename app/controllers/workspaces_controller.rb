include WorkspacesHelper
class WorkspacesController < ApplicationController
  #load_and_authorize_resource
  #************Added By Pratk AJ 27-04-2011*****************
  #Before filter(s) if exempted for do_the_multi_upload method
  #As Uploadify create's problem when used in sink with session,authentication , Flash upload cookies or Flash Cookie Bug.
  #There seems to be no solution yet.
  #*********************************************************
  before_filter :authenticate_user!, :except => :do_the_multi_upload
  before_filter :current_service_session_exists, :except => :do_the_multi_upload
  before_filter :get_base_data, :except => :do_the_multi_upload
  authorize_resource :class => :workspace, :except => :do_the_multi_upload
  add_breadcrumb I18n.t(:text_workspace) , :workspaces_path,:except=>[:index]
  #verify_authenticity_token skipped for Uploadify : Pratk AJ 27-04-2011
  skip_before_filter :verify_authenticity_token

  def index
    set_sort_parameters
    @pagenumber=6
    @folder = @current_employee_user.folders.find(params[:parent_id]) if params[:parent_id]
    @file_ext = DocumentHome.get_extensions(@current_employee_user.id,'User')
    get_folders()
    @recycle_bin=params[:recycle_bin]
    if @recycle_bin
      get_deleted_folders
      add_breadcrumb "<a href='/workspaces'>Workspace</a>", :workspaces_path
      add_breadcrumb "Recycle Bin",workspaces_path(:recycle_bin=>true)
    else
      add_breadcrumb I18n.t(:text_workspace), :workspaces_path
    end
    if request.xhr?
      render :partial=> "workspace"
    end
  end
  
  def new
    @document_home=@current_employee_user.document_homes.new(:folder_id=>params[:folder_id])
    @document =@document_home.documents.build
    render :layout=> false
  end

  def create
    @pagenumber = 6
    if params[:document_home].present?
      document=params[:document_home][:document_attributes]
      params[:document_home].merge!(:access_rights=>2, :employee_user_id=>@emp_user_id,
        :created_by_user_id=>@current_user.id,:company_id=>@company.id,
        :mapable_id=>@emp_user_id,:mapable_type=>'User',:upload_stage=>1,:user_ids=>[@emp_user_id],:owner_user_id=>@emp_user_id)
      document_home = @current_employee_user.document_homes.new(params[:document_home])
      document_home.folder_id = params[:folder_id]
      document=document_home.documents.build(document.merge(:company_id=>@company.id,  :employee_user_id=> @emp_user_id, :created_by_user_id=>@current_user.id ))
      if document_home.save
        flash[:notice]= "#{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_uploaded)}"
      else
        flash[:error]='Document size should be between 1byte to 50 MB'
      end
      redirect_to document_managers_path(:selected_node => params[:selected_node])
    end
  end

  def search_document
    name = params[:name].strip
    current_employee_user = @current_employee_user
    condition_part = ({:document_mapable_type => 'User'}).merge!(((name == '' )? {} : {:document_name => name}))
    with_part = {:document_mapable_id => current_employee_user.id }
    unless condition_part.length == 1 && with_part.length == 1
      @documents = Document.current_company(@company.id).search :conditions => condition_part, :with => with_part, :star => true, :limit => 10000
      @documents.compact!
      @files=@documents.collect{|c| c.document_home}
    else
      is_sec= is_secretary_or_team_manager?
      if is_sec
        folders= current_employee_user.folders.all(:select => :id, :conditions => "livian_access=true")
      else
        folders= current_employee_user.folders.all(:select => :id)
      end
      @files = current_employee_user.document_homes.all(:conditions => ['folder_id IS NULL or folder_id IN  (?)',folders])
    end
    @folders = []
    # Following compact is not needed but we added as their are some document record who don't have document home
    @files.compact!
    @flag = 1
    render :partial => 'workspace', :locals => { :documenthomes => @documenthomes, :folders => @folders, :folder => @folder}
  end

  def create_folder
    @per_page = params[:per_page].blank? ? 25 : params[:per_page].to_i
    @folder = Folder.new
    @parent_id = params[:parent_id] #To set parent_id for new folder to be created : Pratik AJ 10-05-2011
    if request.post?
      params[:folder][:created_by_user_id]= @current_user.id
      params[:folder][:employee_user_id]= @emp_user_id
      params[:folder][:company_id]=@company.id
      params[:folder][:livian_access]= !@current_user.role?("lawyer")
      params[:folder][:parent_id]= params[:parent_id] if params[:parent_id]
      params[:folder][:name]=(params[:folder][:name]).strip
      @folder = @current_employee_user.folders.new(params[:folder])
      if request.xhr?
        @folder.save!
        @folders, @files ,@related_to= DocumentHome.tree_node(params[:selected_node], @company, @current_employee_user, @emp_user_id, is_secretary_or_team_manager?, false, @per_page, params)
        render :partial => "document_managers/documents_list", :layout => false
      end
    else
      render :layout=> false
    end
  end

  def folder_list
    set_sort_parameters
    @pagenumber = 6
    @parent_id=params[:parent_id] || params[:id]
    @file_ext= DocumentHome.get_extensions(@current_employee_user.id,'User')
    @recycle_bin = params[:recycle_bin]
    @recycle_bin = @recycle_bin=="true" ? true : false
    if @recycle_bin
      @folder = @current_employee_user.folders.find_only_deleted(@parent_id) if @parent_id
      get_deleted_folders
    else
      unless @parent_id.blank?
        @folder = @current_employee_user.folders.find(@parent_id) if (params[:id].nil? || (!params[:id].eql?("0")))
        get_folders
      else
        @folder=nil
        get_folders
      end
    end
    # Additional Parameter passes params[:flash] only for multiple upload to show proper flash message : Pratk AJ 27-04-2011
    if params[:flash]=="Cancled"
      flash[:notice] ="File(s) Upload interupted. Some of the file(s) may not be uploaded."
    elsif params[:flash]
      flash[:notice] ="#{params[:flash]} File(s) Uploaded Sucessfully."
    end
    if request.xhr?
      @flag=1
      render :partial=> 'workspace'
    end
  end

  def upload_multi
    @max_upload_size = Max_Attachment_Size 
    @folder = (params[:id].present? and !params[:id].eql?("0")) ? @current_employee_user.folders.find(params[:id]) : Folder.new()
    @document_home=DocumentHome.new
    @document= @document_home.documents.build
    render :layout=> false
  end

  # ************Added By Pratk AJ 27-04-2011*****************
  # do_the_multi_upload modified
  # To save each uploaded file seperately
  # Previously all uploaded file used to get save by iterating over loop.
  # Now do_the_multi_upload is call each time for each file to be uploaded.
  # Modified by Kalpit patel for plupload (feature 8375)

  def do_the_multi_upload
    return true if params[:stop]=="true"
    @document_home = DocumentHome.new()
    params[:document_home]= {}
    if params.has_key?(:file)
      if params[:file]
        success_count = error_count=0
        params[:document_home].merge!(:access_rights=>1, :employee_user_id=>params[:employee_user_id],
          :created_by_user_id=>params[:current_user_id],:company_id=>params[:company_id],
          :mapable_id=>params[:employee_user_id],:mapable_type=>'User',:upload_stage=>1,:user_ids=>[params[:employee_user_id]],
          :folder_id=>params[:parent_folder_id],:owner_user_id=>get_employee_user_id)
        @current_employee_user = User.find(params[:employee_user_id])
        @document_home = @current_employee_user.document_homes.new(params[:document_home])
        filename = params[:name]
        params[:name] = filename.gsub(/[.][^.]+$/,"")
        @document=@document_home.documents.build(:company_id=>params[:company_id],  :employee_user_id=> params[:employee_user_id], :created_by_user_id=>params[:current_user_id], :data => params[:file], :name => params[:name])
        if @document_home.save
          success_count+=1
        else
          error_count+=1
        end
      end
    end
    # render :nothing => true called as we are not going to render any view after the action.
    render :nothing => true
    @document_home = nil
    @document = nil
    @folder = nil
    params = nil
    GC.start
  end

  def change_livian_access
    @folder=@current_employee_user.folders.find(params[:folder_id])
    @folder.update_attribute(:livian_access,params[:access])
    @folder.children.each do |child |
      child.update_attribute(:livian_access,params[:access])
    end
    if @folder.livian_access
      render :inline=> ("<%=link_to(\"<div class='icon_lock_open vtip' title='Click to Lock'></div>\",'#',{:onclick=>'confirm_access(#{@folder.id},0);return false;', :class=>'vtip' , :title=> 'Click to Lock'},  :id => 'unlocked_image')%>").html_safe!
    else
      render :inline=> ("<%=link_to(\"<div class='icon_lock vtip' title='Click to Unlock'></div>\",'#',{:onclick=>'confirm_access(#{@folder.id},1);return false;'}, :id => 'locked_image')%>").html_safe!
    end
  end

  def get_children
    params[:dir]= params[:dir].chomp.to_i if params[:dir]
    @recylce_bin = params[:recycle_bin]=="true" ? true : false
    is_sec= is_secretary_or_team_manager?

    unless @recylce_bin
      if params[:dir] == 0
        if is_sec
          @all_folders= @current_employee_user.folders.find(:all,  :conditions=>folder_sql_conditional_str('livian_access=true AND parent_id is null',params[:move_for],params[:id]))
        else
          @all_folders= @current_employee_user.folders.find(:all, :conditions=>folder_sql_conditional_str('parent_id is null',params[:move_for],params[:id]))
        end
      else
        if is_sec
          @all_folders= @current_employee_user.folders.find(:all, :conditions=>folder_sql_conditional_str('livian_access=true AND parent_id=?',params[:move_for],params[:id],params[:dir]))
        else
          @all_folders= @current_employee_user.folders.find(:all,  :conditions=>folder_sql_conditional_str('parent_id=?',params[:move_for],params[:id],params[:dir]))
        end
      end
    else
      if params[:dir]==0
        if is_sec
          @all_folders= @current_employee_user.folders.find_only_deleted(:all,:conditions=>folder_sql_conditional_str('livian_access=true  and permanent_deleted_at is null and parent_id is null',params[:move_for],params[:id]))
        else
          @all_folders= @current_employee_user.folders.find_only_deleted(:all,:conditions=>folder_sql_conditional_str('permanent_deleted_at is null and parent_id is null',params[:move_for],params[:id]))
        end
      else
        if is_sec
          @all_folders= @current_employee_user.folders.find_only_deleted(:all, :conditions=>folder_sql_conditional_str('livian_access=true and permanent_deleted_at is null and parent_id=?',params[:move_for],params[:id],params[:dir]))
        else
          @all_folders= @current_employee_user.folders.find_only_deleted(:all,  :conditions=>folder_sql_conditional_str('permanent_deleted_at is null and parent_id=?',params[:move_for],params[:id],params[:dir]))
        end
      end
    end
    render :layout=> 'false'
  end

  def move_doc
    @doc_home = DocumentHome.scoped_by_company_id(@company).find(params[:id])
    @doc_home.folder_id = "-1"
    render :layout=> false
  end

  def post_move_doc
    doc_home = DocumentHome.scoped_by_company_id(@company).find(params[:id])
    err = doc_home.folder_id.to_s == (params[:document_home][:folder_id]).to_s ? true : false
    doc_home.folder_id = params[:document_home][:folder_id]
    respond_to do |format|
      if err
        format.js{
          render :update do |page|
            page << "show_error_msg('move_doc_error','Please select destination folder / Selected folder and existing folder are same.','message_error_div');"
          end
        }
      else
        if doc_home.save
          flash[:notice] = "Document moved sucessfully."
        else
          flash[:notice] ="Unable to move Document."
        end
        format.js{
          render :update do |page|
            page.call("tb_remove")
            #          page.call("parent.location.reload")
            page.redirect_to document_managers_path(:from=>"workspace")
          end
        }
      end
    end
  end

  def permanent_delete
    is_sec= is_secretary_or_team_manager?
    if is_sec
      @folders= @current_employee_user.folders.find_only_deleted(:all, :conditions => ['livian_access = true AND permanent_deleted_at IS NULL'])
    else
      @folders= @current_employee_user.folders.find_only_deleted(:all, :conditions => ['permanent_deleted_at IS NULL'])
    end
    @files = @current_employee_user.document_homes.find_only_deleted(:all, :conditions => ['permanent_deleted_at IS NULL'])
    @folders.each do|folder|
      folder.update_attribute(:permanent_deleted_at,Time.zone.now)
    end
    @files.each do|dochome|
      dochome.documents.find_only_deleted(:all).collect{|doc|
        doc.update_attribute(:permanent_deleted_at,Time.zone.now)
      }
      dochome.update_attribute(:permanent_deleted_at,Time.zone.now)
    end
    flash[:notice] = "Recycle bin successfully emptied."
    redirect_to workspaces_path(:recycle_bin => true)
  end

  private
  def get_folders
    is_sec= is_secretary_or_team_manager?
    if @folder
      if is_sec
        @folders = @folder.children.scoped_by_employee_user_id(@emp_user_id).all(:order => @folder_sort, :conditions => ["livian_access = ?", true])
      else
        @folders = @folder.children.all(:order => @folder_sort)
      end
      @files = @folder.files.all(:include => :documents, :order => @doc_sort)
    else
      if is_sec
        @folders= @current_employee_user.folders.all(:order => @folder_sort, :conditions => ['parent_id IS NULL AND livian_access = true'])
      else
        @folders= @current_employee_user.folders.all(:order => @folder_sort, :conditions => ['parent_id IS NULL'])
      end
      @files = @current_employee_user.document_homes.all(:include => :documents, :conditions => ['folder_id IS NULL'], :order => @doc_sort)
    end
  end

  def get_deleted_folders
    is_sec= is_secretary_or_team_manager?
    if @folder
      if is_sec
        @folders= @folder.children.scoped_by_employee_user_id(@emp_user_id).find_only_deleted(:all, :order => @folder_sort, :conditions => ["livian_access = ? and permanent_deleted_at IS NULL", true])
      else
        @folders= @folder.children.find_only_deleted(:all, :order => @folder_sort, :conditions => ["permanent_deleted_at IS NULL"])
      end
      @files = @folder.files.find_only_deleted(:all, :include => :documents, :conditions => ['document_homes.permanent_deleted_at IS NULL'], :order => @doc_sort)
    else
      if is_sec
        folders_ids= @current_employee_user.folders.find_only_deleted(:all, :order => @folder_sort, :select=> :id, :conditions => ['livian_access = true AND permanent_deleted_at IS NULL'])
        ids = folders_ids.collect{|fol| fol.id}
        @folders = @current_employee_user.folders.find_only_deleted(:all, :order => @folder_sort, :conditions => ['livian_access = true AND permanent_deleted_at IS NULL AND (parent_id IS NULL OR parent_id NOT IN (?))', ids])
      else
        folders_ids = @current_employee_user.folders.find_only_deleted(:all, :order => @folder_sort, :select => :id, :conditions => ['permanent_deleted_at IS NULL'])
        ids = folders_ids.collect{|fol| fol.id}
        @folders = @current_employee_user.folders.find_only_deleted(:all, :order => @folder_sort, :conditions => ['permanent_deleted_at IS NULL AND (parent_id IS NULL OR parent_id NOT IN (?))', ids])
      end
      if ids.size > 0
        @files = @current_employee_user.document_homes.find_only_deleted(:all, :include => :documents, :conditions => ['document_homes.permanent_deleted_at IS NULL AND (folder_id IS NULL OR folder_id NOT IN (?))', ids], :order => @doc_sort)
      else
        @files = @current_employee_user.document_homes.find_only_deleted(:all, :include => :documents, :conditions => ["document_homes.permanent_deleted_at IS NULL"], :order => @doc_sort)
      end
    end
  end

  def get_base_data
    @company=@company || current_company
    @current_employee_user = @current_employee_user ||  get_employee_user
    @emp_user_id= @emp_user_id || @current_employee_user.id
  end

  #This Method is used for setting parameters for column sorting :Pratik AJ 07/09/2011
  def set_sort_parameters
    @doc_sort,@folder_sort=""
    sort = params[:dir].eql?("up")? "asc" : "desc"
    params[:col]="created_at" unless params[:col]
    sort_field ="#{params[:col]} #{sort}"
    if params[:col]=="name" || params[:col]=="created_at"
      @doc_sort = "documents.#{sort_field}"
      @folder_sort = "folders.#{sort_field}"
    elsif params[:col]=="data_file_size"
      @doc_sort = "documents.#{sort_field}"
    else
      @doc_sort = sort_field
    end
  end
  
end
