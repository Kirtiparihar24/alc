class DocumentManagersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :get_base_data
  add_breadcrumb "#{I18n.t(:text_document)} #{I18n.t(:text_manager)}", :document_managers_path
  
  def index
    sort = params[:dir].eql?("up")? "asc" : "desc"
    params[:col] = "document_homes.created_at" unless params[:col]
    @matter = Matter.find(params[:matter_id]) if params[:matter_id]
    @pagenumber = 204
    @categories = @company.document_types.all(:select => 'id,alvalue')
    get_folders_list
    @folders = []
    @files = []
    if params[:selected_node].blank?
      params[:selected_node] = "root_#{@company.id}"
    end
    @folders, @files, @related_to = DocumentHome.tree_node(params[:selected_node], @company, @current_employee_user, @emp_user_id, is_secretary_or_team_manager?, false, 25, params, @folders_list, sort, params[:col])
    if request.xhr?
      render :partial => 'documents_list'
    else
      if params[:flash] == "Cancled"
        flash[:notice] = "File(s) Upload interupted. Some of the file(s) may not be uploaded."
      elsif params[:flash]
        flash[:notice] = "#{params[:flash]} File(s) Uploaded Sucessfully."
      end
      render :layout => "application"
    end
  end

  def get_folders_list
    folders_array = []
    folders_array << ["Workspace", @current_employee_user.full_name, @current_employee_user.full_name] if can? :manage, :workspace
    folders_array << ["Repository", t(:text_menu_repository), t(:text_menu_repository)] if can? :manage, :repository
    folders_array << ["Contacts", t(:text_menu_contacts), t(:text_menu_contacts)] if can? :manage, Contact
    folders_array << ["Accounts", t(:text_menu_accounts), t(:text_menu_accounts)] if can? :manage, Account
    folders_array << ["Opportunities", t(:text_menu_opportunity), t(:text_menu_opportunity)] if can? :manage, Opportunity
    folders_array << ["Matters", t(:text_menu_matter), t(:text_menu_matter)] if (can? :manage, Matter)
    folders_array << ["time and expense", t(:text_menu_tne), t(:text_menu_tne)] if can? :manage, :time_and_expense    
    folders_array << ["Campaigns",t(:text_menu_campaign),t(:text_menu_campaign)] if can? :manage, Campaign
    folders_array << ["Recycle_bin","Recycle Bin","Recycle Bin"]
    @folders_list = folders_array
    @lawfirm_users = [current_user]
  end

  def folders_tree
    json_result = DocumentHome.tree_node(params[:node], @company, @current_employee_user, @emp_user_id, is_secretary_or_team_manager?, true, 25, params)
    render :json => json_result.to_json
  end

  def documents_list
    sort = params[:dir].eql?("up")? "asc" : "desc"
    params[:col] = "document_homes.created_at" unless params[:col]
    @perpage = (params[:per_page] || 25).to_i
    get_folders_list
    @folders = []
    @files = []
    @folders, @files , @records, @related_to= DocumentHome.tree_node(params[:selected_node], @company, @current_employee_user, @emp_user_id, is_secretary_or_team_manager?, false, @perpage, params, @folders_list,sort,params[:col])
    render :partial => "documents_list", :layout => false
  end
  
  def search_document
    #FIXME
    folders_array = []
    folders_array << "User" if can? :manage, :workspace
    folders_array << "Company" if can? :manage, :repository
    folders_array << "Contact" if can? :manage, Contact
    folders_array << "Account" if can? :manage, Account
    folders_array << "Opportunity" if can? :manage, Opportunity
    folders_array << "Matter" if (can? :manage, Matter)
    folders_array << "Physical::Timeandexpenses::TimeEntry" if can? :manage, :time_and_expense
    folders_array << "Campaign" if can? :manage, Campaign
    date_type = params[:date_type].strip
    date_from = params[:date_from]
    date_to = params[:date_to]
    perpage = (params[:per_page] || 25).to_i
    date_range_for_link = get_date_on_specified_range("Link " + date_type, date_from, date_to)
    date_range_for_doc = get_date_on_specified_range(date_type, date_from, date_to)
    mapable_ids_hash, document_home_ids, folder_ids, search_links, documents  = DocumentManager.document_manager_search(params, @company, @current_employee_user, date_range_for_doc, date_range_for_link, folders_array)
    files = documents.collect{|document|
      if !document.blank? and !document.document_home.blank?
        if params[:mapable_type].blank? || params[:mapable_type].include?("Root_#{@company.id}")
          document
        else
          maptype = document.mapable_type.downcase
          if mapable_ids_hash.has_key?(maptype) and mapable_ids_hash["#{maptype}"].include?(document.mapable_id.to_i)
            if ["user","company"].include?(maptype) && !document_home_ids.blank?
              document if document_home_ids.include?(document.document_home_id)
            else
              document
            end
          end
        end
      end
    }.compact
    @search_result=true
    if search_links
      unless folder_ids.blank?
        files += search_links.find_all{|link| folder_ids.include?(link.folder_id)}
      else
        files += search_links.compact
      end
    end
    @files = files.paginate(:page => params[:page], :per_page => perpage)
    @folders=[]
    render :partial => 'documents_list'
  end
  
  def edit_folder
    @folder = Folder.find(params[:format]) if params[:format]
    render :layout=> false
  end

  def rename_folder
    folder = Folder.find(params[:folder_id])
    folder.name = (params[:folder][:name]).strip
    folder.updated_by_user_id = @current_user.id
    if params[:from].eql?("document_managers")
      path = document_managers_path(:selected_node=>params[:selected_node])
    elsif params[:from].eql?("workspace")
      path = folder_list_workspaces_path(:id => folder.parent_id)
    elsif params[:from].eql?("repositories")
      path = folder_list_repositories_path(:id => folder.parent_id)
    elsif params[:from].eql?("matters")
      path = folder_list_matter_document_homes_path(:id => folder.parent_id, :matter_id => params[:matter_id])
    end
    respond_to do |format|
      if folder.save
        flash[:notice] = "#{t(:text_folder)} " "#{t(:flash_was_successful)} " "#{t(:text_renamed)}"
        format.js{
          render :update do |page|
            page.call("tb_remove")
            page.redirect_to path
          end
        }
      else
        format.js{
          render :update do |page|
            errors = "<ul>" + folder.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
            page << "show_error_msg('one_field_error_div','#{errors}','message_error_div');"
            page << "jQuery('#loader').hide();"
          end
        }
      end
    end
  end

  def get_base_data
    @company = @company || current_company
    @current_user = @current_user || current_user
    @current_employee_user = @current_employee_user ||  get_employee_user
    @emp_user_id = @emp_user_id || @current_employee_user.id
  end
end
