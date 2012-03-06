class DocumentHomesController < ApplicationController
  # GET /document_homes
  include DocumentHomesHelper
  layout 'left_with_tabs', :except => ['check_out_all', 'document_access_control','change_client_access', 'change_privilege', 'new_document', :upload_interim, :wip_doc_action,:move_doc]
  before_filter :get_base_data, :except=>[:create_multiple]
  before_filter :get_matter, :except => [:create_multiple,:supercede_document,:supercede_or_replace_document,:supercede,:supercede_with_client_document,:supercede_client, :get_doc_history,:destroy,:temp_delete, :restore_document,:restore_folder,:wip_doc_action,:show,:temp_delete_folder ]
  before_filter :check_access_to_doc, :only => [:check_uncheck_doc,:edit,:supercede,:supercede_document, :update,:destroy,:temp_delete, :show_doc_risks,:show_doc_tasks,:show_doc_facts,:show_doc_researches,:show_doc_issues, :restore_document,:document_access_control,:change_client_access, :change_privilege, :upload_interim,:wip_doc_action]
  before_filter :document_not_checked_by_other, :only =>[:check_uncheck_doc, :update,:destroy,:temp_delete, :document_access_control,:change_client_access, :change_privilege,:wip_doc_action,:supercede,:supercede_document]
  before_filter :check_for_file_existence, :only =>[:show]
  before_filter :check_for_matter_acces, :only=>[:index]
  before_filter :authenticate_user!, :except=>[:create_multiple]
  before_filter :get_user, :only => [:index,:new,:show,:edit,:update,:new_document,:create]
  helper_method :remember_past_path
  skip_before_filter :verify_authenticity_token

  def index
    authorize!(:index,@user) unless @user.has_access?(:Documents)
    params[:per_page] ||= 25
    @folder = @matter.folders.find(params[:parent_id]) if params[:parent_id]
    @matter_peoples=@matter.matter_peoples.find(:all,:conditions=>"people_type='client'")
    @linked={:task=> params[:task_id], :fact=> params[:fact_id], :issue=> params[:issue_id], :risk=> params[:risk_id], :research=>params[:research_id]}
    get_folders()
    if(is_access_matter?) || MatterPeople.me(get_employee_user_id, @matter.id, get_company_id).can_view_client_docs?
      @client_documents = @matter.document_homes.uploaded_by_client 
    else
      @client_documents=  @matter.document_homes.uploaded_by_client.private_to_lawyer(get_employee_user_id)
    end
    @pagenumber=151
    add_breadcrumb t(:text_matters), matters_path
    add_breadcrumb t(:text_documents), matter_document_homes_path
    if params[:flash]
      flash[:notice] ="#{params[:flash]} File(s) Uploaded Sucessfully."
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @document_homes }
    end
  end

  def new
    authorize!(:new,@current_user.current_lawyer) unless @current_user.current_lawyer.has_access?('Document Repository')
    authorize!(:new,@user) unless @user.has_access?(:Documents)
    @max_upload_size =Max_Attachment_Size 
    @document_home = @matter.document_homes.new
    @document= @document_home.documents.build
    @linked={:task=> params[:task_id], :fact=> params[:fact_id], :issue=> params[:issue_id], :risk=> params[:risk_id]}
    @matter_peoples=MatterPeople.current_lawteam_members(@matter.id)
    # return_path is passed from matters sub modules, to get back to their
    # respective tabs from this controller after the upload is finished.
    @return_path = params[:return_path]
    @team_member = @matter.get_team_member(@emp_user_id)
    @pagenumber=39
    add_breadcrumb t(:text_matters), matters_path
    add_breadcrumb t(:text_upload_document), new_matter_document_home_path
    respond_to do |format|
      if params[:multiple]
        format.html {render 'multi_upload'}
      else
        format.html {}
      end
      format.js {render :partial => 'new_document'}
      format.xml  { render :xml => @document_home }
    end
  end

  def show   
    unless  is_client
      authorize!(:show,@user) unless @user.has_access?(:Documents)
      doc_home= @document.document_home if @document
      if params[:deleted_doc]
        doc_home = DocumentHome.find_with_deleted(@document.document_home_id)
      end
      @matter=   doc_home.mapable if doc_home.mapable_type=='Matter'
      if(is_firm_manager_previlege?(doc_home))
        send_file  @document.data.path, :type => @document.data_content_type, :length=> @document.data_file_size, :disposition => 'attachment'.freeze
      elsif  @document && doc_home.mapable_type.eql?('AdditionalDocument') ? true : @current_user.has_access?(Document::DOCUMENT_TO_PRODUCT[doc_home.mapable_type]) && document_accesible?(doc_home, @emp_user_id, @company.id, @matter )
        send_file  @document.data.path, :type => @document.data_content_type, :length=> @document.data_file_size, :disposition => 'attachment'.freeze
      elsif @document && (doc_home.mapable_type.eql?('Comment') || doc_home.mapable_type.eql?("Physical::Timeandexpenses::TimeEntry") || doc_home.mapable_type.eql?("Physical::Timeandexpenses::ExpenseEntry") )
        send_file  @document.data.path, :type => @document.data_content_type, :length=> @document.data_file_size, :disposition => 'attachment'.freeze
      else
        flash[:error]= t(:flash_access_denied)
        render_back
      end
    else
      doc_home=@document.document_home if  @document
      contact_id=Matter.scoped_by_company_id(params[:company_id]).find(doc_home.mapable_id).contact_id
      if @document && access_right_client(doc_home.id, contact_id)
        send_file @document.data.path, :type => @document.data_content_type, :length=>@document.data_file_size, :disposition => 'attachment'.freeze
      elsif @document && doc_home.sub_type && doc_home.sub_type.eql?('Termcondition')
        send_file @document.data.path, :type => @document.data_content_type, :length=>@document.data_file_size, :disposition => 'attachment'.freeze
      else
        flash[:error]= t(:flash_access_denied)
        render_back
      end
    end
  rescue
    flash[:error]= "Invalid file"
    redirect_to root_url
  end

  def edit
    authorize!(:edit, @current_user.current_lawyer) unless @current_user.current_lawyer.has_access?('Document Repository')
    authorize!(:edit,@user) unless @user.has_access?(:Documents)
    @matter_peoples=MatterPeople.current_lawteam_members(@matter.id)
    @document= @document_home.documents.build
    @team_member = @matter.get_team_member(@emp_user_id)
    @pagenumber=63
    get_linked_details
    add_breadcrumb t(:text_matters), matters_path
    add_breadcrumb t(:text_edit_document), edit_matter_document_home_path(params[:matter_id], params[:id])
    if request.xhr?
      render :layout=>false
    end
  end

  def create_multiple
    matter_people_ids = []
    if params[:document_home][:matter_people_ids]
      params[:document_home][:matter_people_ids][0].split(",").each do |id|
        matter_people_ids << id if id.to_i != 0
      end
      params[:document_home][:matter_people_ids] = matter_people_ids
    end
    success_count = error_count=0
    @matter = Matter.find(params[:matter_id].to_i)
    @company = Company.find(params[:company_id])
    @document_home = DocumentHome.new()
    params[:document_home].merge!(:upload_stage=>1,:user_ids=>[params[:employee_user_id]],:employee_user_id=>params[:employee_user_id], :owner_user_id=>params[:document_home][:owner_user_id],:company_id=>params[:company_id],:created_by_user_id=> params[:current_user_id])
    document = params[:document_home][:document_attributes]    
    @matter_peoples = @matter.matter_peoples.find(:all,:conditions=>"people_type='client'")
    @linked={:task=> params[:task_id], :fact=> params[:fact_id], :issue=> params[:issue_id], :risk=> params[:risk_id], :research=>params[:research_id]}
    set_access_rights
    #FIXME
    params[:name] = params[:name].gsub(/[.][^.]+$/,"")
    params[:document_home][:document_attributes].merge!(:name=> params[:name],:data=>params[:file])
    @document_home = @matter.document_homes.new(params[:document_home])
    @document=@document_home.documents.build(document.merge(:company_id=>params[:company_id],  :employee_user_id=> params[:employee_user_id], :created_by_user_id=>params[:current_user_id], :data => params[:file], :name => params[:name] ))
    @document_home.tag_list= params[:document_home][:tag_array].split(',') if params[:document_home][:tag_array].present?
    if @document_home.save
      success_count+=1
    else
      error_count+=1
    end
    render :nothing => true
  end

  def create
    authorize!(:create,@user) unless @user.has_access?(:Documents)
    errors = true
    document = params[:document_home][:document_attributes]
    @matter_peoples = @matter.matter_peoples.all(:conditions => "people_type='client'")
    params[:document_home].merge!({
        :created_by_user_id => @current_user.id,
        :employee_user_id=> @emp_user_id,
        :company_id => @company.id,
        :upload_stage=>1
      })
    @linked={:task=> params[:task_id], :fact=> params[:fact_id], :issue=> params[:issue_id], :risk=> params[:risk_id], :research=>params[:research_id]}
    set_access_rights
    @document_home = @matter.document_homes.new(params[:document_home])
    @document=@document_home.documents.build(document.merge(:company_id=>@company.id,  :employee_user_id=> @emp_user_id, :created_by_user_id=>@current_user.id ))
    @document_home.tag_list= params[:document_home][:tag_array].split(',')
    if @document_home.save
      errors =false
    else
      errors =true
    end
    respond_to do |format|
      unless errors
        flash[:notice] = "#{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        format.html {
          if params[:return_path]
            redirect_to params[:return_path]
          else
            if @document_home.owner_user_id!=@emp_user_id && @document_home.access_rights==1
              return_path = matter_document_homes_path(@matter)
            else
              return_path = edit_matter_document_home_path(@matter,@document_home)
            end
            redirect_to(return_path)
          end
        }
        format.js {
          render :update do|page|
            page << "tb_remove()"
          end
        }
      else
        format.html { render :action => "new" }
        format.xml { render :xml => @document_home.errors, :status => :unprocessable_entity }
      end
    end
  end

  def new_document
    authorize!(:new_document,@current_user.current_lawyer) unless @current_user.current_lawyer.has_access?('Document Repository')
    authorize!(:new_document,@user) unless @user.has_access?(:Documents)
    @document_home = @matter.document_homes.new
    @document = @document_home.documents.build
    @linked={:task=> params[:task_id], :fact=> params[:fact_id], :issue=> params[:issue_id], :risk=> params[:risk_id], :research=>params[:research_id]}
    @matter_peoples = @matter.matter_peoples.all(:conditions => "people_type='client'")
    # return_path is passed from matters sub modules, to get back to their
    # respective tabs from this controller after the upload is finished.
    @return_path = params[:return_path]
    if request.post?
      params[:document_home].merge!({
          :created_by_user_id => @current_user.id,
          :employee_user_id=> @emp_user_id,
          :company_id => @company.id,
          :upload_stage=>1
        })
      set_access_rights
      document=params[:document_home][:document_attributes]
      @document_home = @matter.document_homes.new(params[:document_home])
      @document=@document_home.documents.build(document.merge(:company_id=>@company.id,  :employee_user_id=> @emp_user_id, :created_by_user_id=>@current_user.id ))
      if @document_home.save
        flash[:notice] = "#{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
      else
        flash[:error]= 'Please fill all mandatory details for the document.'
      end
      responds_to_parent do
        render :update do |page|
          if @document_home.errors.blank?
            page.call("tb_remove")
            page.call("parent.location.reload")
            page.replace_html 'altnotice', "<div id='notice' class='message_sucess_div mt12'>#{flash[:notice]} </div>"
            page.show 'altnotice'
            page.call("common_flash_message")
            flash[:notice] = nil
          else
            page.hide 'loader1'
            format_ajax_errors(@document, page, "modal_new_document_errors")
            page << "jQuery('#upload_btn').val('Upload');"
            page << "jQuery('#upload_btn').attr('disabled', '');"
            page.call("common_error_flash_message")
            flash[:error] = nil
          end
        end
      end
    end
  end

  def update
    authorize!(:update,@user) unless @user.has_access?(:Documents)
    user_id = current_user.id
    params[:document_home].merge!({
        :updated_by_user_id => user_id
      })
    @document = @document_home.latest_doc
    @document_home.tag_list = params[:document_home][:tag_array].split(',')
    if @document_home.owner_user_id.blank?
      params[:document_home][:owner_user_id] = @emp_user_id
    end
    get_linked_details
    if @document_home.upload_stage == 2
      params[:document_home][:upload_stage] = 3
      params[:document_home][:converted_by_user_id] = user_id
    end
    @document_home.employee_user_id = @emp_user_id if params[:access_control].eql?("private")
    @document_home.contacts = (params[:document_home][:client_access] == '1') ? [@matter.contact] : []
    set_access_rights
    params[:document_home][:matter_issue_ids] ||= []
    params[:document_home][:matter_people_ids] ||= []
    params[:document_home][:matter_fact_ids] ||= []
    params[:document_home][:matter_task_ids] ||= []
    params[:document_home][:matter_research_ids] ||= []
    params[:document_home][:matter_risk_ids] ||= []
    employee_matter_people = @matter.matter_peoples.find_by_employee_user_id(@emp_user_id)
    if params[:document_home][:matter_people_ids] == []
      if @document_home.access_rights == 4
        params[:document_home][:matter_people_ids] << employee_matter_people.id
        params[:document_home][:matter_people_ids] << @matter.matter_peoples.find_by_employee_user_id(@matter.employee_user_id).id
      else
        params[:document_home][:matter_people_ids] << employee_matter_people.id
      end
    end
    respond_to do |format|
      if @document_home.update_attributes(params[:document_home]) && @document.update_attributes(params[:document_home][:document_attributes])
        if (@document_home.owner_user_id!=@emp_user_id && @document_home.access_rights==1) || !params[:document_home][:matter_people_ids].include?(employee_matter_people.id)
          return_path = matter_document_homes_path(@matter)
        else
          return_path = edit_matter_document_home_path(@matter,@document_home)
        end
        flash[:notice] = "#{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        format.js {redirect_to(matter_document_homes_path(@matter))}
        format.html {
          redirect_if(params[:save], return_path)
          redirect_if(params[:save_exit], matter_document_homes_path(@matter))
          redirect_if(params[:save_add], return_path)
        }
        format.xml  { head :ok }
      else
        format.html {redirect_to(edit_matter_document_home_path(@matter,@document_home))}
        format.js {redirect_to(matter_document_homes_path(@matter))}
        format.html { render :action => "edit" }
        format.xml  { render :xml => @document_home.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # Creating folder in matters : Added By Pratik 13-09-2011 
  def create_folder
    @folder = Folder.new()
    @parent_id = params[:parent_id]
    if request.post?
      params[:folder].merge!(:created_by_user_id=> @emp_user_id,:company_id=>@company.id,:livian_access=> !@emp_user.role?("lawyer"),
        :name=>(params[:folder][:name]).strip)
      params[:folder][:parent_id]= params[:parent_id] if params[:parent_id]
      @folder = @matter.folders.new(params[:folder])
      respond_to do |format|
        if @folder.save
          flash[:notice] = "#{t(:text_folder)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
          format.js{
            render :update do |page|
              page.call("tb_remove")
              page.redirect_to folder_list_matter_document_homes_path(:id=>params[:parent_id])
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
    @matter_peoples=@matter.matter_peoples.find(:all,:conditions=>"people_type='client'")
    @linked={:task=> params[:task_id], :fact=> params[:fact_id], :issue=> params[:issue_id], :risk=> params[:risk_id], :research=>params[:research_id]}
    @pagenumber = ''
    @parent_id=params[:parent_id] || params[:id]
    unless @parent_id.blank?
      @folder = @matter.folders.find(@parent_id) if (params[:id].nil? || (!params[:id].eql?("0")))
      get_folders
    else
      @folder=nil
      get_folders
    end
    if(is_access_matter?)
      @client_documents = @matter.document_homes.uploaded_by_client
    else
      @client_documents=  @matter.document_homes.uploaded_by_client.private_to_lawyer(get_employee_user_id)
    end
    if params[:flash]=="Cancled"
      flash[:notice] ="File(s) Upload interupted. Some of the file(s) may not be uploaded."
    elsif params[:flash].present?
      flash[:notice] ="#{params[:flash]} File(s) Uploaded Sucessfully."
    end
    if request.xhr?
      @flag=1
      render :partial => 'matter_document_list'
    else
      render :action=> 'index'
    end
  end

  def get_folders
    @folders = []
    @document_homes = []
    total  = 0
    @perpage = (params[:per_page] || 25).to_i
    params[:page] ||=1
    # If we are showing data for a selected folder
    params[:base] = true if params[:col].nil?
    params[:col] ||="created_at"
    params[:dir] ||= "down"
    folder_order,document_order = if params[:col] == "created_at"
      [params[:col]+DocumentHome::DIR_SORT_ORDER[params[:dir]],params[:col]+DocumentHome::DIR_SORT_ORDER[params[:dir]]]
    else
      ["created_at"+DocumentHome::DIR_SORT_ORDER[params[:dir]],params[:col]+DocumentHome::DIR_SORT_ORDER[params[:dir]]]
    end
    document_order.gsub!(/owner/,"first_name")
    document_order+=" ,users.last_name#{DocumentHome::DIR_SORT_ORDER[params[:dir]]}"  if document_order =~ /first_name/
    join_assocation,document_order =  (document_order =~ /first_name/ ? ["owner","users.#{document_order}"] : ["documents","documents.#{document_order}"] )
    if @folder
      # Paginate the folders in 25 per page
      @folders = @folder.children.paginate(:per_page => @perpage, :page => params[:page],:order => "folders.#{folder_order}")
      if @folders.size < @perpage
        # Paginate the files for remaining records (if there were fewer folders than 25)
        offset =  calculate_offset(@folders.total_entries,@perpage,params[:page])
        @document_homes= (@matter.document_homes.uploaded_by_lawyer(get_employee_user_id,@folder.id).all(:offset=>round_to_zero(offset),:limit=>set_limit(offset,@perpage),:joins => join_assocation.to_sym,:order => document_order)).uniq
      end
      # Total pages count is addition of all the folders + files + links records,
      # because we are paginating across all the three.
      total += @folder.children.count
      total += @matter.document_homes.uploaded_by_lawyer(get_employee_user_id,@folder.id).count
      # We are showing data for root folders
    else
      # Paginate the folders in 25 per page
      @folders = @matter.folders.paginate(:per_page => @perpage, :page => params[:page], :conditions=> ['parent_id is null'],:order => "folders.#{folder_order}")
      if @folders.size < @perpage
	      # Paginate the files for remaining records (if there were fewer folders than 25)
  	    offset =  calculate_offset(@folders.total_entries,@perpage,params[:page])
        @document_homes = (@matter.document_homes.uploaded_by_lawyer(get_employee_user_id,'').all(:offset=>round_to_zero(offset),:limit=>set_limit(offset,@perpage),:joins => join_assocation.to_sym,:conditions=> ['folder_id is null'],:order => document_order)).uniq
      end
      # Total pages count is addition of all the folders + files + links records,
      # because we are paginating across all the three.
      # all the root folders + all the file outside any folder + all the links outside any folder
      total += @matter.folders.all(:conditions => ['parent_id IS NULL']).count
      total += @matter.document_homes.uploaded_by_lawyer(get_employee_user_id,'').all(:conditions => ['folder_id IS NULL']).count
    end
    # Because the paginate is used on three different type of models (above)
    # we needed a custom paginate object to generate the view, using the will_paginate
    # helper. Here we are just creating it manually.
    params[:base],params[:dir],params[:col]=[nil,nil,nil] if params[:base]
    @documenthomes = WillPaginate::Collection.new(params[:page] || 1, @perpage, total)
    @documenthomes.replace(@folders.to_a + @document_homes.to_a)
  end

  def get_children
    params[:dir]= params[:dir].chomp.to_i if params[:dir]
    if params[:dir]==0
      @all_folders= @matter.folders.find(:all,:conditions=>folder_sql_conditional_str('parent_id is null',params[:move_for],params[:id]))
    else
      @all_folders= @matter.folders.find(:all,:conditions=>folder_sql_conditional_str('parent_id=?',params[:move_for],params[:id],params[:dir]) )
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
    err  = ((doc_home.folder_id.to_s == (params[:document_home][:folder_id]).to_s) || (params[:document_home][:folder_id] == "-1" )) ? true : false
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
            page.redirect_to folder_list_matter_document_homes_path(:id=>doc_home.folder_id,:matter_id=>params[:matter_id])
          end
        }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @document_home.destroy
        doc = DocumentHome.find_with_deleted(params[:id])
        unless doc.access_rights==2
          doc.update_attribute(:permanent_deleted_at, doc.deleted_at)
        end
        flash[:notice]="#{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_deleted)}"
      else
        flash[:error] = "#{t(:text_document)}  " "#{t(:text_already)}  " "#{t(:text_deleted)}"
      end

      if (current_user.role?(:livia_admin) || current_user.role?(:lawfirm_admin))
        format.html{redirect_to matter_documents_companies_path(:page => params[:page]=="" ? nil : params[:page], :m=>params[:matter_id])}
      else
        if params[:return_path]          
          format.html {render_back}
        elsif params[:matter_type]
          if params[:matter_type] == "matter_task"
            format.html {redirect_to(edit_matter_matter_task_path(@matter, params[:matter_commentable_id]))}
          elsif params[:matter_type] == "matter_issue"
            format.html {redirect_to(edit_matter_matter_issue_path(@matter, params[:matter_commentable_id]))}
          elsif params[:matter_type] == "matter_risk"
            format.html {redirect_to(edit_matter_matter_risk_path(@matter, params[:matter_commentable_id]))}
          elsif params[:matter_type] == "matter_research"
            format.html {redirect_to(edit_matter_matter_research_path(@matter, params[:matter_commentable_id]))}
          else
            format.html {redirect_to(edit_matter_matter_fact_path(@matter, params[:matter_commentable_id]))}
          end

        else
          format.html {redirect_to(matter_document_homes_path(@matter))}
        end
      end
      format.xml  { head :ok }
    end
  end

  def temp_delete
    sort = params[:dir].eql?("up")? "asc" : "desc"
    params[:col] = "document_homes.created_at" unless params[:col]
    @per_page = params[:per_page].blank? ? 25 : params[:per_page].to_i
    @current_employee_user = @emp_user
    if params[:path].eql?("repositories")
      path = folder_list_repositories_path(:id => @document_home.folder_id)
    elsif params[:path].eql?("matters")
      path = folder_list_matter_document_homes_path(:id => @document_home.folder_id)
    end
    if @document_home.delete
      flash[:notice]="#{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_deleted)}"
    else
      flash[:error] = "#{t(:text_document)}  " "#{t(:text_already)}  " "#{t(:text_deleted)}"
    end
    if request.xhr?
      flash[:notice]=''
      @folders, @files ,@related_to= DocumentHome.tree_node(params[:selected_node], @company, @current_employee_user, @emp_user_id, is_secretary_or_team_manager?, false, @per_page, params, nil, sort, params[:col])
      render :partial => "document_managers/documents_list", :layout => false
    else
      respond_to do |format|
        format.html { redirect_to(path) }
        format.xml  { head :ok }
      end
    end
  rescue
    flash[:error] = "#{t(:text_document)}  " "#{t(:text_already)}  " "#{t(:text_deleted)}"
    redirect_to path
  end
  
  #This Methods is for temperorily deleting folder form Workspace and Repositories - Pratik
  def temp_delete_folder
    @per_page = params[:per_page].blank? ? 25 : params[:per_page].to_i
    @current_employee_user = @emp_user
    path = params[:path]
    @folder = Folder.find(params[:id])
    if @folder.destroy
      flash[:notice]="#{t(:text_folder)} " "#{t(:flash_was_successful)} " "#{t(:text_deleted)}"
    else
      flash[:error] = "#{t(:text_folder)}  " "#{t(:text_already)}  " "#{t(:text_deleted)}"
    end
    if request.xhr?
      flash[:notice]=''
      @folders, @files ,@related_to= DocumentHome.tree_node(params[:selected_node], @company, @current_employee_user, @emp_user_id, is_secretary_or_team_manager?, false, @per_page, params)
      render :partial => "document_managers/documents_list", :layout => false
    else
      respond_to do |format|
        format.html { redirect_to(path) }
        format.xml  { head :ok }
      end
    end

  rescue
    flash[:error] = "#{t(:text_folder)}  " "#{t(:text_already)}  " "#{t(:text_deleted)}"
    redirect_to path
  end

  def get_tasks_issues_risks_facts_researches
    sort_column_order
    @ord = @ord.nil? ? 'name ASC':@ord
    @matter_document = @matter.document_homes.find(params[:id])
    @col = @matter.send(params[:col_type]).find(:all, :order => @ord)
    @col_ids = @matter_document.send(params[:col_type_ids])
    @label = params[:label]
  end

  def assign_tasks_issues_risks_facts_researches
    @matter_document = @matter.document_homes.find(params[:id])
    unless params[:document_home]
      eval("@matter_document.#{params[:dynamic_ids]}=nil")
      @matter_document.save false
    else
      @matter_document.update_attributes(params[:document_home])
    end
    redirect_to folder_list_matter_document_homes_path(:matter_id => @matter.id,:parent_id => params[:parent_id])
  end

  # Returns linked tasks/facts/risks etc.
  def get_linked_details
    @matter_issues = @matter.matter_issues
    @matter_facts = @matter.matter_facts
    @matter_risks = @matter.matter_risks
    @matter_tasks = @matter.matter_tasks
    @matter_researches = @matter.matter_researches
    @document_issue_array = @document_home.matter_issues.all(:select => ['id']).collect{|a| a.id}
    @document_contact_array = @document_home.contacts.all(:select => ['contacts.id']).collect{|a| a.id}
    @document_people_array = @document_home.matter_peoples.all(:select => ["matter_peoples.id"]).collect{|a| a.id}
    @document_fact_array = @document_home.matter_facts.all(:select => ['id']).collect{|a| a.id}
    @document_risk_array = @document_home.matter_risks.all(:select => ['id']).collect{|a| a.id}
    @document_task_array = @document_home.matter_tasks.all(:select => ['id']).collect{|a| a.id}
    @document_research_array = @document_home.matter_researches.all(:select => ['id']).collect{|a| a.id}
    @document_task_array.size>0?@matter_tasks_not_checked = @matter_tasks.all(:conditions => ['id NOT IN (?)',@document_task_array]) : @matter_tasks_not_checked = @matter_tasks
    @document_task_array.size>0?@matter_tasks_checked = @matter_tasks.all(:conditions => ['id IN (?)',@document_task_array]) : @matter_tasks_checked = []
    @document_issue_array.size>0?@matter_issues_not_checked = @matter_issues.all(:conditions => ['id NOT IN (?)',@document_issue_array]): @matter_issues_not_checked = @matter_issues
    @document_issue_array.size>0?@matter_issues_checked = @matter_issues.all(:conditions => ['id IN (?)',@document_issue_array]): @matter_issues_checked = []
    @document_fact_array.size>0?@matter_facts_not_checked = @matter_facts.all(:conditions=>['id NOT IN (?)',@document_fact_array]) : @matter_facts_not_checked = @matter_facts
    @document_fact_array.size>0?@matter_facts_checked = @matter_facts.all(:conditions => ['id IN (?)',@document_fact_array]) : @matter_facts_checked = []
    @document_risk_array.size>0?@matter_risks_not_checked = @matter_risks.all(:conditions => ['id NOT IN (?)',@document_risk_array]) : @matter_risks_not_checked = @matter_risks
    @document_risk_array.size>0?@matter_risks_checked = @matter_risks.all(:conditions => ['id IN (?)',@document_risk_array]) : @matter_risks_checked = []
    @document_research_array.size>0?@matter_researches_not_checked = @matter_researches.all(:conditions => ['id NOT IN (?)',@document_research_array]) : @matter_researches_not_checked=@matter_researches
    @document_research_array.size>0?@matter_researches_checked = @matter_researches.all(:conditions=>['id IN (?)',@document_research_array]) : @matter_researches_checked = []
  end

  # Returns document history records.
  def get_doc_history
    @doc_home = DocumentHome.scoped_by_company_id(@company.id).find(params[:id])
    @document_home = DocumentHome.scoped_by_company_id(@company.id).find_with_deleted(params[:id])
    if @document_home.wip_parent
      @documents= @doc_home.latest_doc.to_a
      @documents += @doc_home.wip_parent.documents
    else
      @documents = @document_home.documents.all(:order => 'created_at DESC')
    end
    render :layout=> false
  end

  # Document supercede.
  def supercede_document
    @replace = params[:replace] == 'true' ? 'Replace' : "#{t(:label_superseed)}"
    @doc_home = DocumentHome.scoped_by_company_id(@company).find(params[:id])
    @document_home = DocumentHome.new
    @document = @doc_home.latest_doc
    render :layout=> false
  end

  # Document supercede.
  def supercede_or_replace_document
    @doc_home = DocumentHome.scoped_by_company_id(@company).find(params[:id])
    @document_home=DocumentHome.new
    @document= @doc_home.latest_doc
    render :layout=> false
  end

  # Supercede (replace) and old version of document with a newer one.
  def supercede
    comp_id = @company.id
    @replace = params[:replace] == 'true' ? 'Replace' : 'Supercede'
    replace =  @replace == 'Replace'
    params[:document_home][:created_by_user_id] = @current_user.id
    params[:document_home][:employee_user_id] = @emp_user_id
    @doc_home = DocumentHome.scoped_by_company_id(comp_id).find(params[:id])
    if !params[:matter_id].blank?
      @matter = Matter.find(params[:matter_id])
    end
    if params[:document_home][:data].present? && params[:document_home][:data].size > 0  &&  params[:document_home][:data].size <= 52428800 && @doc_home.superseed_document(params[:document_home], replace, params[:bill_id])
      flash[:notice]="#{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
      path = ''
      if params[:fragment]=='fragment-2'
        path = redirect_to "#{edit_campaign_path(params[:campaign_id])}#fragment-2"
      elsif params[:from].eql?('repository')
        path = folder_list_repositories_path(:id=>params[:parent_id])
      elsif params[:from].eql?('document_manager')
        path = document_managers_path(:selected_node => params[:selected_node])
      elsif params[:from].eql?('common')
        path = "window.location.reload();"
      elsif params[:from].eql?('matter_documents')
        path = folder_list_matter_document_homes_path(:matter_id => params[:matter_id],:parent_id => params[:parent_id])
      end
      if path.blank?
        if params[:commit].eql?("Replace")
          render_back
        elsif params[:from].eql?('matter_terconditions')
          responds_to_parent do
            render :update do |page|
              page << "window.location.reload();"
            end
          end
        else
          if((params[:from]=="matters" || params[:from]=="time_open_entry") && params[:view]=="matter")
            params[:from_entry].eql?("time_entry")? mapable = @company.time_entries : mapable = @company.expense_entries
            @mapable = mapable.find(params[:mappable_id])
            @document_homes = @mapable.document_homes
          end
          responds_to_parent do
            render :update do |page|
              page.replace_html 'document_upload_list',:partial => "common/document_home",:local=>{:matter_id=>params[:matter_id]} if((params[:from]=="matters" || params[:from]=="time_open_entry") && params[:view]=="matter")
              page << "jQuery('#altnotice').append('#{escape_javascript(render(:partial => 'common/common_flash_message'))}')";
              page << "parent.tb_remove();"
              page << "jQuery('#altnotice').show();"
            end
          end
        end
      else
        responds_to_parent do
          render :update do |page|
            page << "parent.tb_remove();"
            if params[:from].eql?('common')
            page << path
            else
            page.redirect_to path
            end
          end
        end
      end
    else
      flash[:error] = 'File size is not in the correct range [1byte - 50 MB]'
      if params[:commit].eql?("Replace")
        render_back
      else
        responds_to_parent do
          render :update do |page|
            page << "parent.tb_remove();"
            page << "window.location.reload();"
          end
        end
      end
    end
  end

  def supercede_with_client_document
    emp_usr_id = get_employee_user_id
    @doc_home = DocumentHome.find(params[:id])
    @matter = Matter.scoped_by_company_id(current_company.id).find(@doc_home.mapable_id)
    @document_home = DocumentHome.new
    @documenthomes = @matter.employee_document_homes
    @document_homes = get_acessible_documents(@documenthomes)
    @document_homes = @document_homes.find_all {|e| (e.checked_in_by_employee_user_id ==nil || e.checked_in_by_employee_user_id ==  emp_usr_id) && e.upload_stage != 2 && !e.sub_type_id}
    @document= @doc_home.latest_doc
    @lable_txt = params[:txtlbl]
    render :layout=> false
  end

  def supercede_client
    comp_id= current_company.id
    begin
      responds_to_parent do
        render :update do |page|
          unless params[:document_home][:id].blank?
            @doc_home = DocumentHome.scoped_by_company_id(comp_id).find(params[:document_home][:id])
            document = @doc_home.latest_doc
            @client_doc_home = DocumentHome.scoped_by_company_id(comp_id).find(params[:client_doc_id])
            @client_doc = @client_doc_home.latest_doc
            DocumentHome.transaction do
              @client_doc.update_attributes(:name=>document.name,:document_home_id => @doc_home.id,:phase=>document.phase,:privilege=>document.privilege, :description=> document.description, :author=>document.author, :source=>document.source)
              @client_doc_home.destroy
            end
            page << "tb_remove();"
            page << "window.location.reload();"
            flash[:notice]= "#{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_superseeded)}"
          else
            page << "show_error_msg('matter_document_errors','#{t(:flash_no_document_selected)}','message_error_div');"
          end
        end
      end
    rescue Exception => exc
      logger.info("Error in superseeding client document: #{exc.message}")
      flash[:error] = "DB Store Error: #{exc.type}"
      render_back
    end
  end

  # Returns linked researches.
  def show_doc_researches
    render :partial => "common/linked_matter_researches", :locals => { :matter_researches => @document_home.matter_researches}
  end

  # Returns linked risks.
  def show_doc_risks
    render :partial => "common/linked_matter_risks", :locals => { :matter_risks => @document_home.matter_risks}
  end

  # Returns linked facts.
  def show_doc_facts
    render :partial => "common/linked_matter_facts", :locals => { :matter_facts => @document_home.matter_facts}
  end

  # Returns linked tasks.
  def show_doc_tasks
    render :partial => "common/linked_matter_tasks", :locals => { :matter_tasks => @document_home.matter_tasks}
  end

  # Returns linked issues.
  def show_doc_issues
    render :partial => "common/linked_matter_issues", :locals => { :matter_issues => @document_home.matter_issues}
  end

  # Retrieves access rights in proper form, used in update.
  # If the client has to be given access.
  def confirm_client_access
    if params[:document_home][:client_access]=='1'
      params[:document_home][:contact_ids]=[@matter.contact_id]
    else
      params[:document_home][:contact_ids]=[]
    end
  end

  # Get all private documents.
  def get_my_docs
    @document_homes = DocumentHome.all(:conditions => ["mapable_type = ? AND mapable_id = ?",@mapable_type,@mapable_id])
    @docs=[]
    @document_homes.each do |matter_document|
      if document_accesible?(matter_document)
        @docs <<  matter_document.latest_doc
      end
    end
  end

  # Validate this document.
  def document_validate(action)
    if !params[:document_home][:name] or params[:document_home][:name].blank?
      @document_home.errors.add("^This", "^"" #{t(:error_document_name_cant_be_blank)}")
      render :action => action
      return false
    else
      return true
    end
  end

  def search_document
    name = params[:name].strip
    @perpage = (params[:per_page] || 25).to_i
    if params[:from]=="workspaces"
      sort = params[:dir].eql?("up")? "asc" : "desc"
      params[:col]="created_at" unless params[:col]
      current_employee_user = @emp_user
      condition_part = ({:document_mapable_type => 'User'}).merge!(((name == '' )? {} : {:document_name => name}))
      with_part = {:document_mapable_id => current_employee_user.id }
      if name.present?
        @documents = Document.current_company(@company.id).search :conditions => condition_part, :with => with_part,:order=>params[:col].try(:to_sym),:sort_mode=>sort.try(:to_sym), :star => true, :limit => 10000
        @documents.compact!
        @files=@documents.collect{|c| c.document_home}
      else
        is_sec= is_secretary_or_team_manager?
        if is_sec
          folders= current_employee_user.folders.all(:select => "id", :conditions => ['livian_access=true'])
        else
          folders= current_employee_user.folders.all(:select => "id")
        end
        ids = folders.collect{|folder | folder.id}
        @files = current_employee_user.document_homes.all(:conditions => ['folder_id is null or folder_id IN  (?)',ids])
      end
      @folders =[]
      @files.compact!
      @flag=1
      render :partial => 'workspaces/workspace', :locals => {:documenthomes => @documenthomes, :folders=>@folders, :folder=>@folder}
    elsif params[:from]=="repositories"
      sort = params[:dir].eql?("up")? "asc" : "desc"
      params[:col]="created_at" unless params[:col]
      @categories=  @company.document_types
      @sub_categories = @company.document_sub_categories.find_all_by_category_id(@categories[0].id)
      # Buildup the conditions as given in search form.
      condition_part = {:document_mapable_type => 'Company'}
      link_condition_part = {:link_mapable_type => 'Company'}
      date_part = {}
      link_date_part = {}
      with_part = date_part.merge!({:document_mapable_id =>@company.id})
      link_with_part = link_date_part
      total = 0
      offset = calculate_offset(0, @perpage, params[:page])
      documents = Document.current_company(@company.id).search "#{name}",:conditions => condition_part, :with => with_part, :joins => :document_home, :select => "document_homes.*, documents.*", :order=>params[:col].try(:to_sym), :sort_mode=>sort.try(:to_sym), :star => true, :offset => round_to_zero(offset),:limit=>set_limit(offset,@perpage)
      @documenthomes = documents.compact
      if @documenthomes.size < @perpage
        total_document_homes = @perpage*(params[:page].to_i-1)+@documenthomes.size
        offset =  calculate_offset(0, @perpage, params[:page])
        search_links = Link.current_company(@company.id).search "#{name}",:conditions => link_condition_part, :with => link_with_part, :star => true, :offset => round_to_zero(offset),:limit=>set_limit(offset,@perpage) if params[:extension].blank?
        @documenthomes+=  search_links if search_links
      end
      total += Document.current_company(@company.id).search("#{name}",:conditions => condition_part, :limit => 10000, :with => with_part, :star => true).count
      total += Link.current_company(@company.id).search("#{name}",:conditions => link_condition_part, :limit => 10000, :with => link_with_part, :star => true).count if params[:extension].blank?
      @folders =[]
      @repositories = WillPaginate::Collection.new(params[:page] || 1, @perpage, total)
      @repositories.replace(@documenthomes.to_a)
      @search_result = true # FIXME: hack!

      @categories= @company.document_types
      render :partial => 'repositories/repository', :locals => {:documenthomes=> @documenthomes, :categories => @categories}
    elsif params[:from]=="document_homes"
      condition_part ={:document_mapable_type => 'Matter'}
      with_part = {:document_mapable_id => params[:matter_id]}
      if name.present?
        @documents = Document.current_company(@company.id).search "#{name}", :conditions => condition_part, :with => with_part, :star => true, :limit => 10000
        document_homes = @documents.find_all{|e| !e.blank? && e.document_home.sub_type.nil? && e.document_home.upload_stage != 2 }.collect(&:document_home)
        @document_homes = document_homes.find_all{|e| !e.wip_doc && ((e.owner.id==@emp_user_id && e.access_rights==1) || e.access_rights!=1) }.collect
      else
        @document_homes = @matter.document_homes.all(:conditions => ['sub_type IS NULL AND upload_stage !=2 AND wip_doc IS NULL AND ((owner_user_id = ? AND access_rights = 1) OR access_rights != 1)', @emp_user_id])
      end
      @folders =[]
      @document_homes = @document_homes.paginate(:page => params[:page], :per_page => @perpage)
      render :partial => 'document_homes/document_search_result', :locals => {:documents => @documents, :document_homes=>@document_homes}
    end
  end

  # Added by Kalpit Patel on 28 oct 2011 for editing document added(feature 8375)
  def edit_doc_link
    @type=params[:type]
    @msg= {:file=>params[:type]=='DocumentHome'? true:false,:link=>params[:type]=='Link'? true:false }
    if params[:controller_name]=~ /reposit/
      @categories=  @company.document_types
      @document_home = @type=='DocumentHome'? @company.repository_documents.find(params[:id]) :  @company.links.find(params[:id])
    else
      @document_home = DocumentHome.find(params[:id])
    end
    render :layout => false
  end

  # Added by Kalpit Patel on 28 oct 2011 for updating document added(feature 8375)
  def update_doc_link
    @type=params[:upload]
    @msg= {:file=> @type=='DocumentHome'? true:false,:link=> @type=='Link'? true:false }
    if params[:controller_name] =~ /reposit/
      @categories=  @company.document_types
      @document_home = @type=='DocumentHome'? @company.repository_documents.find(params[:id]) :  @company.links.find(params[:id])
    else
      @document_home = DocumentHome.find(params[:id])
    end
    @document_home.tag_list= params[:document_home][:tag_array].split(',') if params[:document_home][:tag_array]
    if @type=='DocumentHome'
      if  @document_home.update_with_document(params[:document_home] )
        flash[:notice]= 'Document was successfully updated'
      end
    else
      if  @document_home.update_attributes(params[:document_home])
        flash[:notice]= 'Link was successfully updated'
      else
        flash[:error]= 'Link was not removed'
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

  def check_uncheck_doc
    if params[:lock]=='check'
      @document_home.checked_in_by_employee_user_id = @emp_user_id
      @document_home.checked_in_at =Time.zone.now.to_date
      @document_home.save
      flash[:notice]=  "#{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_checked_out)}"
    elsif params[:lock]=='uncheck'
      @document_home.update_attributes(:checked_in_by_employee_user_id =>nil, :checked_in_at =>nil)
      flash[:notice]= "#{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_checked_in)}"
    end
    redirect_to matter_document_homes_path(params[:matter_id])
  end

  def check_out_all
    @current_employee=@emp_user_id
    @document_homes = @matter.employee_document_homes.find_all {|e| e.checked_in_by_employee_user_id && !e.wip_doc.present?}
    if request.post?
      if @document_homes.present?
        DocumentHome.transaction do
          case params[:check_in_action].to_i
          when 1
            #Check in all documents including WIP document,
            @document_homes.each do |doc_home|
              wip_doc= doc_home.wip_document
              if wip_doc.present?
                doc_home.documents << wip_doc.latest_doc
                wip_doc.delete
              end
              doc_home.update_attributes(:checked_in_by_employee_user_id =>nil, :checked_in_at =>nil)
              send_checkout_email(doc_home,@current_user)
            end
          when 2
            #Check in all documents excluding WIP document,
            @document_homes.each do |doc_home|
              wip_doc= doc_home.wip_document
              unless wip_doc.present?
                doc_home.update_attributes(:checked_in_by_employee_user_id =>nil, :checked_in_at =>nil)
                send_checkout_email(doc_home,@current_user)
              end
            end
          when 3
            #Check in selective documents.
            document_homes=@matter.employee_document_homes.find_all {|e|  params[:selected_records].include?(e.id.to_s) if params[:selected_records]}
            document_homes.each do |doc_home|
              send_checkout_email(doc_home,@current_user)
              wip_doc= doc_home.wip_document
              if wip_doc.present?
                doc_home.documents << wip_doc.latest_doc
                wip_doc.delete
              end
              doc_home.update_attributes(:checked_in_by_employee_user_id =>nil, :checked_in_at =>nil)
              if document_homes.empty?
                flash[:error] = "No document was selected to checkout"
              else
                flash[:notice] = "#{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_checked_in)}"
              end
            end
          end
        end
      else
        flash[:error]= "No document currently checked out"
      end
      render_back
    end
  end

  def restore_document
    @per_page = params[:per_page].blank? ? 25 : params[:per_page].to_i
    @current_employee_user = @emp_user
    @document_home.deleted_at=nil
    @document_home.save(false)
    if request.xhr?
      @folders, @files ,@related_to= DocumentHome.tree_node(params[:selected_node], @company, @emp_user, @emp_user_id, is_secretary_or_team_manager?, false, @per_page, params)
      render :partial => "document_managers/documents_list", :layout => false
    end
  end

  def restore_folder
    @per_page = params[:per_page].blank? ? 25 : params[:per_page].to_i
    @current_employee_user = @emp_user
    mainfolder= Folder.find_only_deleted(:first, :conditions => {:id => params[:id],:company_id => @company.id})
    match = Folder.find(:all ,:conditions=>{:name=> mainfolder.name,:mapable_type=>mainfolder.mapable_type, :parent_id=> mainfolder.parent_id, :company_id => mainfolder.company_id})
    unless match.count== 0
      flash[:error]="Cannot restore : Folder with same name already exist in destination folder."
      redirect_to document_managers_path(:from=>"recycle_bin")
    else
      folders = mainfolder.all_children_del
      folders << mainfolder
      folders.each do |folder|
        innerfiles = folder.files.find_with_deleted(:all)
        innerfiles << folder.links.find_with_deleted(:all)
        innerfiles = innerfiles.flatten
        unless innerfiles.nil?
          innerfiles.each do |file|
            file.update_attribute("deleted_at", nil)
          end
        end
        folder.update_attribute("deleted_at", nil)
      end
      if request.xhr?
        @folders, @files ,@related_to= DocumentHome.tree_node(params[:selected_node], @company, @emp_user, @emp_user_id, is_secretary_or_team_manager?, false, @per_page, params)
        render :partial => "document_managers/documents_list", :layout => false
      end
    end
  end

  def document_access_control
    @interim=params[:interim]
    if @interim
      @matter_peoples =get_accessible_people(@document_home.wip_parent)
    else
      @matter_peoples= MatterPeople.current_lawteam_members(@matter.id) 
    end
    get_linked_details
    if request.post?
      params[:document_home] ||= {}
      params[:document_home][:name]= @document_home.latest_doc.name
      params[:document_home][:description]= @document_home.latest_doc.description
      params[:access_control]='selective' if @interim
      set_access_rights
      if @document_home.update_attributes(params[:document_home])
        flash[:notice] ="Access rights updated for the document successfully."
      else
        flash[:error] ="Access rights could not be updated."
      end
      render_back
    end
  end

  def multi_documents_access_control
    @matter_peoples = @matter.matter_peoples.all(:conditions => "people_type='client'")
    if request.post?
      set_access_rights
      document_home_ids = params[:document_home_ids]
      matter_people_ids, user_column = params[:document_home][:user_ids].present? ? [params[:document_home].delete(:user_ids), "employee_user_id"] : [params[:document_home].delete(:matter_people_ids), "matter_people_id"]
      if params[:access_control] == "selective" || (params[:access_control] == "private" && params[:document_home][:owner_user_id].to_i != @emp_user_id.to_i)
        columns = "(document_home_id, #{user_column}, created_at, updated_at, company_id)"
        now = Time.now
        values = []
        document_home_ids.map{|dhi| matter_people_ids.map{|mpi| values << "(#{dhi.to_i}, #{mpi.to_i}, '#{now}', '#{now}', #{@company.id})" } }
        ActiveRecord::Base.connection.execute("INSERT INTO document_access_controls #{columns} VALUES #{values.join(',')}")
      end
      # Feature #10277 : Dont Remove this Code, will need this for optimaization perpose - Pratik AJ
=begin
      else params[:access_control] == "public"
        document_homes = Document.find_by_sql("select documents.*, document_homes.* from documents
left outer join document_homes on document_homes.id = documents.document_home_id where
documents.id in (select  max(docs.id) from documents docs inner join document_homes dh on dh.id=docs.document_home_id group by dh.id)
and document_homes.company_id = #{@company.id} and document_homes.deleted_at is NULL and document_homes.id IN (#{document_home_ids.join(',')})")
        dh_columns = "(mapable_type, mapable_id, access_rights, created_at, updated_at, upload_stage, company_id, created_by_user_id, parent_id, employee_user_id, owner_user_id, extension)"
        doc_columns = "(name, bookmark, description, author, source, privilege, data_file_name, data_content_type, data_file_size, created_at, updated_at, employee_user_id, company_id, created_by_user_id, updated_by_user_id, category_id)"
        category_id = @company.document_categories.find_by_lvalue('Other').id
        now = Time.now
        dh_values = []
        doc_values = []
        document_homes.each do|dh|
          path = File.join(dh.url, dh.data_file_name)
          dh_values << "('Company', #{@company.id}, #{dh.access_rights}, '#{dh.created_at}', '#{dh.updated_at}', #{dh.upload_stage}, #{@company.id}, #{dh.created_by_user_id}, #{dh.id.to_i}, #{dh.employee_user_id.to_i}, #{dh.owner_user_id.to_i}, '#{dh.extension}')"
          doc_values << "('#{dh.name}', '#{dh.bookmark}', '#{dh.description}', '#{dh.author}', '#{dh.source}', '#{dh.privilege}', '#{dh.data_file_name}', '#{dh.data_content_type}', #{dh.data_file_size.to_i}, '#{dh.created_at}', '#{dh.updated_at}', #{dh.employee_user_id.to_i}, #{dh.company_id}, #{dh.created_by_user_id.id}, #{dh.updated_by_user_id.to_i}, #{category_id})"
          #          doc_values << "('', '#{dh.name}', '#{dh.phase_id}', '#{dh.bookmark}', '#{dh.description}', '#{dh.author}', '#{dh.source}', '#{dh.privilege}', '#{dh.data_file_name}', '#{dh.data_content_type}', #{dh.data_file_size.to_i}, '#{dh.created_at}', '#{dh.updated_at}', #{dh.employee_user_id.to_i}, '', '#{dh.delta}', #{dh.company_id}, '', '' , #{dh.created_by_user_id.id}, #{dh.updated_by_user_id.to_i}, #{dh.category_id.to_i}, #{dh.sub_category_id.to_i}, #{dh.doc_source_id.to_i}, #{dh.doc_type_id.to_i}, '#{dh.share_with_client}', '#{dh.comment_id}')"
        con = ActiveRecord::Base.connection
        con.execute("INSERT INTO document_homes #{dh_columns} VALUES #{dh_values.join(',')}")
        con.execute("INSERT INTO documents #{doc_columns} VALUES #{doc_values.join(',')}")
=end
      params[:document_home].delete(:matter_people_ids)
      if params[:access_control] == "public" && params[:document_home][:repo_update] == true
        document_homes = @matter.document_homes.find(:all, :conditions => ["id in (?)", document_home_ids])
        document_homes.each do|dh|
          dh.update_attributes(params[:document_home])
        end
      else
        DocumentHome.update_all(params[:document_home], "id in (#{document_home_ids.join(',')})")
      end
      access_doc = @matter.document_homes.find_all{|e| e.upload_stage != 2 && ((e.access_rights == 1 && e.owner_user_id == @current_user.id ) || e.access_rights != 1 && !e.access_rights.nil?)}
      @other_document = []
      @private_document = []
      access_doc.each do |doc|
        if doc.access_rights != 1 && doc.owner_user_id == @current_user.id
          @other_document << doc
        elsif doc.access_rights == 1
          @private_document << doc
        end
      end
      render :partial => 'matters/all_documents'
    else
      render :layout => false
    end
  end

  def change_client_access
    @document_contact_array = @document_home.contacts.all(:select => ['contacts.id']).collect{|a| a.id}
    if request.post?
      if params[:client_access]=='1'
        @document_home.contacts=[@matter.contact]
      else
        @document_home.contacts= []
      end
      if @document_home.save!
        flash[:notice]='Client access updated successfully'
        render_back
      end
    end
  end

  def change_privilege
    if request.post?
      if @document_home.latest_doc.update_attributes(:privilege=> params[:document_home][:privilege])
        flash[:notice]='Document privilege updated successfully'
      end
      render_back
    end
  end

  def upload_interim
    @matter_peoples = @matter.matter_peoples.all(:conditions => "people_type='client'")
    @doc_in_progress=@document_home
    @access_right = @document_home.wip_doc.blank? ? @document_home.access_rights : @document_home.wip_parent.access_rights
    @document_people_array = @doc_in_progress.matter_peoples.all(:select => ["matter_peoples.id"]).collect{|a| a.id}
    @accessible_to_people =  get_accessible_people(@doc_in_progress)
    @document_home = @matter.document_homes.new
    @document= @document_home.documents.build
    params[:access_control] = 'selective'
    if request.post?
      wip_created=false
      document=params[:document_home][:document_attributes]
      set_access_rights
      if !@doc_in_progress.wip_doc
        params[:document_home].merge!({
            :created_by_user_id => @current_user.id,
            :employee_user_id=> @emp_user_id,
            :company_id => @company.id,
            :upload_stage=>1      })
        @document_home= DocumentHome.new(params[:document_home].merge(:mapable_type=>@doc_in_progress.mapable_type, :mapable_id=>@doc_in_progress.mapable_id, :checked_in_by_employee_user_id=> @doc_in_progress.checked_in_by_employee_user_id, :checked_in_at=> @doc_in_progress.checked_in_at,:enforce_version_change=> @doc_in_progress.enforce_version_change))
        @document_home.wip_doc =@doc_in_progress.id
        @document =@doc_in_progress.latest_doc.clone
        @document.created_by_user_id = @current_user.id
        @document.created_at = nil
        @document.employee_user_id =  @emp_user_id
        @document.data = document[:data]
        @document_home.documents << @document
        wip_created =true if @document_home.save
      else
        document[:created_by_user_id] = @current_user.id
        document[:employee_user_id]= @doc_in_progress.latest_doc.employee_user_id
        @document_home=@doc_in_progress
        wip_created =true if   @document_home.superseed_document(document,true,false)
      end
      document=params[:document_home][:document_attributes]
      if  wip_created
        flash[:notice] = "#{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
      else
        flash[:error]= 'Please fill all mandatory details for the document.'
      end
      responds_to_parent do
        render :update do |page|
          if @document_home.errors.blank?
            page.call("tb_remove")
            page.call("parent.location.reload")
            page.replace_html 'altnotice', "<div id='notice' class='message_sucess_div mt12'>#{flash[:notice]} </div>"
            page.show 'altnotice'
            page.call("common_flash_message")
            flash[:notice] = nil
          else
            page.hide 'loader1'
            format_ajax_errors(@document_home, page, "modal_new_document_errors")
            page.call("common_error_flash_message")
            flash[:error] = nil
          end
        end
      end
    end
  end

  def wip_doc_action
    @wip_doc=@company.document_homes.find(params[:id])
    @doc_home= @wip_doc.wip_parent
    if request.post?
      case params[:perform]
      when 'supercede'
        @doc_home.documents << @wip_doc.latest_doc
        flash[:notice]='Main document was successfully superceded with WIP document'
      when 'replace'
        @doc_home.latest_doc.destroy
        @doc_home.documents << @wip_doc.latest_doc
        flash[:notice]='Main document was successfully replaced with the WIP document'
      when 'discard'
        flash[:notice]='WIP document was discarded successfully'
      else
        flash[:error]='Invalid operation'
      end
      @wip_doc.delete
      @doc_home.update_attributes(:checked_in_by_employee_user_id =>nil,:checked_in_at =>nil)
      render_back
    end
  end

  # Modified by kalpit patel for plupload (feature 8375)
  def upload_document
    session[:search]=params[:search]
    company = @company
    if ["contacts", "accounts","opportunities","campaigns"].include?(params[:from])
      reports = CompanyReport.find_reports_favorites(@company.id, get_employee_user_id, "#{params[:from].singularize.capitalize}")
    else
      reports = CompanyReport.find_reports_favorites(@company.id, get_employee_user_id, 'TimeAndExpense')
    end
    if params[:from]=="contacts"
      mapable = company.contacts
      return_path = contacts_path
      @contacts_fav = reports
      @name = company.contacts.find(params[:mappable_id]).full_name
    elsif params[:from]=="accounts"
      mapable = company.accounts
      return_path = accounts_path
      @accounts_fav = reports
      @name = company.accounts.find(params[:mappable_id]).name
    elsif params[:from]=="opportunities"
      mapable = company.opportunities
      return_path = opportunities_path
      @opps_fav = reports
      @name = company.opportunities.find(params[:mappable_id]).name
    elsif params[:from]=="campaigns"
      mapable = company.campaigns
      return_path = campaigns_path
      @campaigns_fav = reports
      @name = company.campaigns.find(params[:mappable_id]).name
    elsif params[:from]=="matters" && params[:view]=="matter"
      params[:from_entry].eql?("time_entry")? mapable = company.time_entries : mapable = company.expense_entries
      return_path = physical_timeandexpenses_matter_view_path(:current_tab=>params[:current_tab],:from=>"matters",:start_date=>params[:start_date],:end_date=>params[:end_date],:matter_id=>params[:matter_id],:status => params[:status],:view=>'matter')
      @times_fav = reports
    elsif ["time_open_entry","time_close_entry"].include?(params[:from])
      mapable = company.time_entries
      @name = current_user.full_name
      if params[:time_entry_date]
        return_path = new_physical_timeandexpenses_time_and_expense_path(:time_entry_date=>params[:time_entry_date])
      else
        if params[:view]=="matter"
          return_path = physical_timeandexpenses_matter_view_path(:from=>params[:from],:current_tab=>params[:current_tab],:start_date=>params[:start_date],:end_date=>params[:end_date],:matter_id=>params[:matter_id],:status => params[:status],:view=>params[:view])
        elsif params[:view]=="contact" ||  params[:view]=="presales"
          return_path = physical_timeandexpenses_contact_view_path(:current_tab=>params[:current_tab],:start_date=>params[:start_date],:end_date=>params[:end_date],:contact_id=>params[:contact_id],:status => params[:status],:view=>params[:view])
        elsif params[:view]=="internal"
          return_path = physical_timeandexpenses_internal_path(:current_tab=>params[:current_tab],:start_date=>params[:start_date],:end_date=>params[:end_date],:status => params[:status],:view=>params[:view])
        end
      end
      @times_fav = reports
    elsif ["expense_open_entry","expense_close_entry","expense_asso_open_entry","expense_asso_close_entry"].include?(params[:from])
      mapable = company.expense_entries
      @name = current_user.full_name
      if params[:time_entry_date]
        return_path = new_physical_timeandexpenses_time_and_expense_path(:time_entry_date=>params[:time_entry_date])
      else
        if params[:view]=="matter"
          return_path = physical_timeandexpenses_matter_view_path(:current_tab=>params[:current_tab],:start_date=>params[:start_date],:end_date=>params[:end_date],:matter_id=>params[:matter_id],:status => params[:status],:view=>params[:view])
        elsif params[:view]=="contact" ||  params[:view]=="presales"
          return_path = physical_timeandexpenses_contact_view_path(:current_tab=>params[:current_tab],:start_date=>params[:start_date],:end_date=>params[:end_date],:contact_id=>params[:contact_id],:status => params[:status],:view=>params[:view])
        elsif params[:view]=="internal"
          return_path = physical_timeandexpenses_internal_path(:current_tab=>params[:current_tab],:start_date=>params[:start_date],:end_date=>params[:end_date],:status => params[:status],:view=>params[:view])
        end
      end
      @times_fav = reports
    end
    @mapable = mapable.find(params[:mappable_id])
    @return_path = return_path
    @document_home=DocumentHome.new
    sort_column_order
    @ord = @ord.nil? ? 'documents.name ASC':@ord
    @document_homes = @mapable.document_homes.find(:all, :joins =>[:documents], :order => @ord).uniq
    @document= @document_home.documents.build
    @pagenumber= 21
    tab_name=""
    if ["time_open_entry","time_close_entry","expense_open_entry","expense_close_entry","expense_asso_open_entry","expense_asso_close_entry"].include?(params[:from])
      tab_name="Time & Expense"
    else
      params[:from].eql?('contacts')? tab_name="Business Contacts" :  tab_name=params[:from].capitalize
     
    end
    if params[:from].eql?('matters') && params[:from_tab].eql?('time_expense')
      add_breadcrumb "Matters",matters_path
      add_breadcrumb "Time & Expense",return_path
    else
      add_breadcrumb tab_name,return_path
    end
    
    add_breadcrumb "Upload Document", upload_document_document_homes_path
    render :partial=> 'common/new_document', :layout => "full_screen"
  end

  def error_messages_for(*params)
    options = params.extract_options!.symbolize_keys
    if object = options.delete(:object)
      objects = Array.wrap(object)
    else
      objects = params.collect {|object_name| instance_variable_get("@#{object_name}") }.compact
    end
    count  = objects.inject(0) {|sum, object| sum + object.errors.count }
    unless count.zero?
      html = {}
      [:id, :class].each do |key|
        if options.include?(key)
          value = options[key]
          html[key] = value unless value.blank?
        else
          html[key] = 'errorExplanation'
        end
      end
      options[:object_name] ||= params.first
      I18n.with_options :locale => options[:locale], :scope => [:activerecord, :errors, :template] do |locale|
        header_message = if options.include?(:header_message)
          options[:header_message]
        else
          object_name = options[:object_name].to_s.gsub('_', ' ')
          object_name = I18n.t(object_name, :default => object_name, :scope => [:activerecord, :models], :count => 1)
          locale.t :header, :count => count, :model => object_name
        end
        message = options.include?(:message) ? options[:message] : locale.t(:body)
        error_messages = objects.sum {|object| object.errors.full_messages.map {|msg| content_tag(:li, ERB::Util.html_escape(msg)) } }.join
        contents = ''
        contents << content_tag(options[:header_tag] || :h2, header_message) unless header_message.blank?
        contents << content_tag(:p, message) unless message.blank?
        contents << content_tag(:ul, error_messages)
        content_tag(:div, contents, html)
      end
    else
      ''
    end
  end

  def content_tag(tag, contents, opts={})
    opt_values = opts.map {|k, v| "#{k}=\"#{v}\"" }.join(' ')
    "<#{tag} #{opt_values}>#{contents}</#{tag}>"
  end

  # Modified by kalpit patel for plupload(feature 8375)
  def upload
    if params[:document_home].present?
      if params[:from]=="contacts"
        mapable = @company.contacts.find(params[:document_home][:mapable_id])
      elsif params[:from]=="accounts"
        mapable = @company.accounts.find(params[:document_home][:mapable_id])
      elsif params[:from]=="opportunities"
        mapable = @company.opportunities.find(params[:document_home][:mapable_id])
      elsif params[:from]=="campaigns"
        mapable = @company.campaigns.find(params[:document_home][:mapable_id])
      elsif params[:from]=="time_open_entry" || params[:from]=="time_close_entry" || params[:from_entry]=="time_entry"
        mapable = @company.time_entries.find(params[:document_home][:mapable_id])
      elsif params[:from]=="expense_open_entry" || params[:from]=="expense_close_entry" || params[:from]=="expense_asso_open_entry" || params[:from]=="expense_asso_close_entry" || params[:from_entry]=="expense_entry"
        mapable = @company.expense_entries.find(params[:document_home][:mapable_id])
      end
      params[:name] = params[:name].gsub(/[.][^.]+$/,"")
      document={:name=>params[:name],:description=>params[:description],:data=>params[:file]}
      params[:document_home].merge!(:access_rights=>2, :employee_user_id=>@emp_user_id,
        :created_by_user_id=>@current_user.id,:company_id=>@company.id,
        :mapable_id=> params[:mapable_id],:upload_stage=>1,:mapable_type=> "#{mapable.class.name}" ,:owner_user_id=>@emp_user_id)
      @document_homes = mapable.document_homes
      @document_home = mapable.document_homes.new(params[:document_home])
      @document=@document_home.documents.build(document.merge(:company_id=>@company.id,  :employee_user_id=> @emp_user_id, :created_by_user_id=>@current_user.id ))
      @document_home.tag_list= params[:document_home][:tag_array].split(',')
      @mapable = mapable
      if @document_home.save
        flash[:notice]= "#{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_uploaded)}"
      end
    end
    render :nothing => true

  end

  def send_email_doc
    render :partial => "common/email_doc"
  end

  def send_email
    doc = Document.find_by_id(params[:id])
    path = doc.data.path
    send_doc(path, params)
    render :update do |page|
      flash[:notice] = "Mail sent succsessfully"
      page << "tb_remove();"
      page.replace_html "altnotice", :partial => '/common/common_flash_message'
    end
  end

  def move_multiple_doc
    if request.post?
      update_attr = "mapable_type = 'User', mapable_id = #{@emp_user_id}, folder_id = #{params[:folder_id].blank? ? 'NULL' : params[:folder_id] }"
      DocumentHome.scoped_by_company_id(@company).update_all(update_attr, "id in (#{params[:document_home_ids].join(',')})")
      @private_document = DocumentHome.find(:all, :conditions => "mapable_type='Matter' and mapable_id = #{params[:matter_id]} and owner_user_id = #{@emp_user_id} and company_id = #{@company.id} and access_rights = 1 ")
      render :partial => 'matters/private_document' ,:layout =>false
    else
      render :layout=> false
    end
  end
  
  private

  def check_access_to_doc
    unless (current_user.role?(:livia_admin) || current_user.role?(:lawfirm_admin))
      @document_home = DocumentHome.scoped_by_company_id(@company.id).find_with_deleted(params[:id])
      @matter= @document_home.mapable  if @document_home.mapable_type =='Matter'
      if(is_access_matter? || document_accesible?(@document_home,@emp_user_id ,@company.id,@matter))
        return true
      else
        flash[:error] = t(:flash_access_denied)
        render_back
      end
    else
      @company = Company.find params[:company_id]
      @document_home = DocumentHome.scoped_by_company_id(@company.id).find_with_deleted(params[:id])
      @matter= @document_home.mapable  if @document_home.mapable_type =='Matter'
    end
  end

  def document_not_checked_by_other
    unless current_user.role?:livia_admin
      if @document_home.checked_in_by_employee_user_id && @document_home.checked_in_by_employee_user_id != @emp_user_id
        flash[:error] = "Document checked out by #{@document_home.checked_in_by.try(:full_name).try(:titleize) } "

        redirect_to matter_document_homes_path(@document_home.mapable_id)
      end
    end
  end

  # Make access_control entry for this document.
  def set_access_rights
    access_control=params[:access_control]
    params[:document_home][:contact_ids]=[@matter.contact_id] if params[:document_home][:client_access]=='1'
    case  access_control.to_s
    when "private"
      params[:document_home][:user_ids]= [@emp_user_id]
      params[:document_home][:matter_people_ids]=[]
      params[:document_home][:access_rights] = 1
      params[:document_home][:repo_update] = false
    when "public"
      params[:document_home][:company_id] = @company.id
      params[:document_home][:matter_people_ids]=[]
      params[:document_home][:access_rights] = 2
      params[:document_home][:repo_update]=params[:document_home][:repo_update]? true : false
    when "matter_view"
      params[:document_home][:access_rights] = 3
      params[:document_home][:matter_people_ids]=[]
      params[:document_home][:repo_update] = false
    when "selective"
      params[:document_home][:access_rights] = 4
      params[:document_home][:repo_update] = false
    end
  end

  def get_base_data
    @company ||= current_company
    @emp_user_id ||= get_employee_user_id
    @emp_user ||= get_employee_user
    @current_user ||= current_user
  end

  def send_checkout_email(doc_home,cur_user)
    DocumentHome.checkout_email(doc_home,cur_user)
  end

  def check_for_file_existence
    begin
      unless is_client
        @document=Document.scoped_by_company_id(get_company_id).find(params[:id])
      else
        @document=Document.scoped_by_company_id(params[:company_id]).find(params[:id])
      end
      if @document.present? &&  File.exist?(@document.data.path)
        return true
      else
        flash[:error]= 'File Not Found'
        render_back
      end
    rescue Exception => e
      flash[:error]= 'File Not Found'
      render_back
    end
  end

  def is_firm_manager_previlege?(doc_home)
    if((is_access_matter? || is_access_t_and_e?) && doc_home.company_id == current_user.company_id)
      return (doc_home.mapable_type=='Matter' || doc_home.mapable_type=='Physical::Timeandexpenses::TimeEntry' || doc_home.mapable_type=='TimeEntry' || doc_home.mapable_type=='Physical::Timeandexpenses::ExpenseType' || doc_home.mapable_type=='ExpenseEntry') ? true : false
    end
  end

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

end
