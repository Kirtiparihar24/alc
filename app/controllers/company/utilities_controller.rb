class Company::UtilitiesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts, :except =>[:automate_matter_numbering, :update_matter_sequence]

  layout "admin"
  
  private
  def perform_ftp_upload(params)
    if params[:user_setting][:setting_value].present?
      user_setting = UserSetting.find_or_create_by_user_id_and_company_id(params[:user_setting][:user_id], params[:user_setting][:company_id])
      user_setting.update_attributes(:setting_type => "FtpFolder", :setting_value => params[:user_setting][:setting_value])
      if params[:save].present?
        flash[:notice] = "FTP Folder set successfully"
      elsif params[:save_and_upload].present?
        Resque.enqueue(UploadRepository, params[:user_setting][:user_id])
        flash[:notice] = "Repository documents are being uploaded from FTP in the background."
      end
    else
      flash[:error] = "FTP Folder name not given"
    end
  end

  public
  def get_ftp_folder
    u = User.find(params[:user_id])
    ftp_folder = u.ftp_folder.try(:setting_value)
    render :text => ftp_folder
  end
  
  def ftp_upload
    authorize!(:company_settings,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    !params[:company_id].blank?? session[:company_id] = params[:company_id] : params[:company_id] = session[:company_id]
    if current_user.role?:lawfirm_admin
      params[:company_id]=current_user.company_id
    else
      @companies ||=Company.company(current_user.company_id)
    end
    @company ||=Company.find(params[:company_id]) unless params[:company_id].nil?
    @user_setting = UserSetting.new
    @employees = @company.employees
    if params[:user_setting]
      perform_ftp_upload(params)
    end
  end

  def utility
    authorize!(:utility,current_user) unless current_user.role?:livia_admin
    @companies ||= Company.getcompanylist(current_user.company_id)
    @type = params[:type]
    @linkage = (@type == "contact_stages") ? 'contacts' : params[:linkage]
    if request.xhr?
      @company ||= Company.find params[:company_id],:include=>@type.to_sym
    else
      @company ||= Company.find session[:company_id],:include=>@type.to_sym if session[:company_id]
    end
    
    session[:company_id] = @company.id if @company
  end

  # Feature 6407 - Supriya Surve - 9th May 2011
  def company_settings
    authorize!(:company_settings,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    !params[:company_id].blank?? session[:company_id] = params[:company_id] : params[:company_id] = session[:company_id]
    if current_user.role?:lawfirm_admin
      params[:company_id] = current_user.company_id
    else
      @companies ||= Company.company(current_user.company_id)
    end
    if params[:company_id].present?
      @company ||= Company.find(params[:company_id])
      @tne_setting = @company.tne_invoice_setting.id if @company.tne_invoice_setting.present?
    end
    if @company.present?
      @company.company_settings #added this line becasue company_settings not initialize
      @campaign_mailer_emails = @company.campaign_mailer_emails
      @campaign_mailer_email = @company.campaign_mailer_emails.new
      @duration_setting = @company.duration_setting
    end
  end

  # Feature 6323 :: reset_sequence action is called using the JavaScript Ajax function.
  # The JS function passes company id, mode type(constant) and the array of
  # record id and the index to update in the constant- Supriya Surve : 06/05/2011
  def reset_sequence
    model_type = params[:model_type]
    paramssequences = params[:sequences]
    companyid = params[:company_id].to_i
    paramssequences.each do |sequences|
      sequences.each do |sequence_array|
        sequence_record = sequence_array.split(",")        
        id = sequence_record[0].to_i
        sequence = sequence_record[1].to_i
        if model_type == "liti_types"
          object = TypesLiti
        elsif model_type == "nonliti_types"
          object = TypesNonLiti
        elsif model_type == "company_activity_types"
          object = CompanyActivityType
        elsif model_type == "expense_types"
          object = Physical::Timeandexpenses::ExpenseType
        else
          object = model_type.singularize.camelize.constantize
        end        
        object.update_all({:sequence => sequence}, {:id => id, :company_id => companyid})
      end
      
    end

    respond_to do |format|
      format.js {
        render :update do |page|
          # page.redirect_to manage_company_utilities_path(model_type)
          # need this block with out this it gives 302 error if sucess block added for ajax in javascript
          # else gives missing template error :: TODO
        end
      }
    end
  end

  def automate_matter_numbering
    authorize!(:automate_matter_numbering,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    !params[:company_id].blank?? session[:company_id] = params[:company_id] : params[:company_id] = session[:company_id]
    if current_user.role?:lawfirm_admin
      params[:company_id]=current_user.company_id
    else
      @companies ||=Company.company(current_user.company_id)
    end
    @company ||=Company.find(params[:company_id]) unless params[:company_id].nil?   
  end

  def update_matter_sequence
    authorize!(:update_matter_sequence,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    !params[:company_id].blank?? session[:company_id] = params[:company_id] : params[:company_id] = session[:company_id]
    if current_user.role?:lawfirm_admin
      params[:company_id]=current_user.company_id
    else
      @companies ||=Company.company(current_user.company_id)
    end
    @company ||=Company.find(params[:company_id]) unless params[:company_id].nil?
    @company.sequence_no=params[:company][:sequence_no].to_i
    @company.format=params[:company][:format]
    @company.sequence_seperator=params[:company][:sequence_seperator]
    if !params[:company][:current_sequence_year].eql?(params[:company][:sequence_reset_year]) && params[:company][:format].include?("CY")
      @company.sequence_reset_year=params[:company][:current_sequence_year].to_i      
    end      
    if @company.save
      basecon = ActiveRecord::Base.connection
      if !basecon.sequence_exists?('company'+@company.id.to_s+'_seq')
        basecon.create_sequence('company'+@company.id.to_s+'_seq', params[:company][:sequence_no].to_i)
      end
      if(params[:company][:sequence_no].to_i!=params[:company][:old_sequence_id].to_i)
        basecon = ActiveRecord::Base.connection
        basecon.set_sequence('company'+@company.id.to_s+'_seq', params[:company][:sequence_no].to_i)
      end
      basecon=nil
      flash[:notice] = "Company Matter Sequence Updated Successfully"
    else
      flash[:error] = @company.errors.full_messages
    end
    redirect_to :automate_matter_numbering
  end

  #to open the partial if items are associated with the item that is selected to be deleted
  #written here cause tb_show needs a url. cannot render partial directly
  def open_deactivate_form
    @company = Company.find(params[:company])
    final_items = @company.send(params[:modelclass].to_sym).find(:all, :conditions=>["id IN (?)",params[:dropdown].to_a ])
    render :partial=>'deactivate_item' ,:locals =>{:company=>params[:company],:modelclass =>params[:modelclass],:item=>params[:item],:all_items=>final_items,:linkage=>params[:linkage]}
  end


  # when clicking on the deactivate link
  # params[:linkage] is the association with the item. Run in loop in more than 1 associated items are present.
  #eg : for sources linked to contacts and opportunities.split based on"-"
  #destroy functions all the tab functions not required henceforth
  def deactivate_item
    @company = Company.find(params[:company_id])
    modelclass = params[:modelclass]
    type = @company.send(modelclass.to_sym).find(params[:item])
    all_types = @company.send(modelclass.to_sym).collect(&:id)
    @sub = all_types - [type.id] #to pass the ids for the dropdown after removing the item selected
    @total_length = 0
    @associated_items =[]
    association = params[:linkage]
    split_association = association.split("-")
    #Bug 9385 - issue with deactivating act type when linked to any task or activity.
    len = 0
    split_association.each do |x|
      if modelclass == "matter_fact_types"
        len = MatterFact.find(:all, :conditions => ["company_id = #{@company.id} and status_id = #{params[:item]}"]).count
      elsif modelclass == "company_activity_types"
        len = MatterTask.find(:all, :conditions => ["company_id = #{@company.id} and category_type_id = #{params[:item]}"]).length
        len += EmployeeActivityRate.find(:all, :conditions => ["company_id = #{@company.id} and activity_type_id = #{params[:item]}"]).length
        len += Physical::Timeandexpenses::TimeEntry.find_all_by_company_id(@company.id,:conditions => "activity_type  = #{params[:item]}").length
      else
        len = type.send(x.to_sym).count
      end
      @total_length += len
    end
    if  @total_length > 0
      respond_to do|format|
        format.js {
          render :update do|page|
            if @sub.empty?
              page.alert("Cannot deactivate since no replacement value present")
            else
              page << "tb_show('','#{open_deactivate_form_path({:company=>params[:company_id],:modelclass =>modelclass,:item=>params[:item],:dropdown=>@sub,:linkage=>params[:linkage]})}&height=170&width=450','');"
            end
          end
        }
      end
    else
      type.destroy
      set_sequence_for_lookups(@company.send(modelclass.to_sym))
      flash[:notice ] = "#{type.lvalue} deactivated successfully"
      respond_to do |format|
        format.js{
          render :update do |page|
            page<<"window.location.href='#{manage_company_utilities_path(modelclass,:linkage =>association)}';"
          end
        }
      end
    
    end
  end

  #Called from the deactivate form on clicking of save after
  #an alternate item is selected then the original can be deleted
  def update_item
    table_name = params[:linkage]
    updated_item = params[:item][:item_id]
    company_id = params[:company]
    modelclass = params[:modelclass]
    original_item = params[:original_item]
    @company = Company.find(company_id)
    type = @company.send(modelclass.to_sym).find(original_item)
    begin
      find_tables_associated_with_modelclass(modelclass,updated_item,company_id,original_item)
      #After updating destroy the selected item
      type.destroy
      set_sequence_for_lookups(@company.send(modelclass.to_sym))
      flash[:notice] = "#{type.lvalue} is deactivated successfully"
    rescue  Exception => exc
      logger.info("Error in updating: #{exc.message}")
      flash[:error] = "DB Store Error: #{exc.type}"
    end
    redirect_to(manage_company_utilities_path(modelclass,:linkage =>table_name,:company_id => company_id))
  end

  #Switch case to find the associated tables that contain the item and have to be updated when deleting a record
  def find_tables_associated_with_modelclass(modelclass,updated_item,company_id,original_item)
    case modelclass
    when "company_sources"
      ActiveRecord::Base.connection.execute("Update contacts set source =#{updated_item} where company_id = #{company_id} and source =#{original_item}")
      ActiveRecord::Base.connection.execute("Update opportunities set source =#{updated_item} where company_id = #{company_id} and source =#{original_item}")
    when "phases"
      ActiveRecord::Base.connection.execute("Update matters set phase_id =#{updated_item} where company_id = #{company_id} and phase_id =#{original_item}")
      ActiveRecord::Base.connection.execute("Update documents set phase=#{updated_item} where company_id = #{company_id} and phase = #{original_item}")
      ActiveRecord::Base.connection.execute("Update matter_tasks set phase_id=#{updated_item} where company_id = #{company_id} and phase_id = #{original_item}")
    when "liti_types"
      ActiveRecord::Base.connection.execute("Update matters set matter_type_id =#{updated_item} where company_id = #{company_id} and matter_type_id =#{original_item} ")
    when "nonliti_types"
      ActiveRecord::Base.connection.execute("Update matters set matter_type_id =#{updated_item} where company_id = #{company_id} and matter_type_id =#{original_item}")
    when "doc_sources"
      ActiveRecord::Base.connection.execute("Update documents set doc_source_id =#{updated_item} where company_id = #{company_id} and doc_source_id =#{original_item}")
      ActiveRecord::Base.connection.execute("Update matter_facts set doc_source_id =#{updated_item} where company_id = #{company_id} and doc_source_id =#{original_item}")
    when "document_categories"
      ActiveRecord::Base.connection.execute("Update documents set doc_type_id =#{updated_item} where company_id = #{company_id} and doc_type_id = #{original_item}")
      ActiveRecord::Base.connection.execute("Update links set category_id =#{updated_item} where company_id = #{company_id} and category_id =#{original_item} ")
    when "company_activity_types"
      ActiveRecord::Base.connection.execute("Update time_entries set activity_type =#{updated_item} where company_id = #{company_id} and activity_type=#{original_item}")
      ActiveRecord::Base.connection.execute("Update matter_tasks set category_type_id  =#{updated_item} where company_id = #{company_id} and category_type_id =#{original_item}")
      ActiveRecord::Base.connection.execute("Update employee_activity_rates set activity_type_id  =#{updated_item} where company_id = #{company_id} and activity_type_id =#{original_item}")
    when "expense_types"
      ActiveRecord::Base.connection.execute("Update expense_entries set expense_type =#{updated_item} where company_id = #{company_id} and expense_type= #{original_item}")
    when "research_types"
      ActiveRecord::Base.connection.execute("Update matter_researches set research_type =#{updated_item} where company_id = #{company_id} and research_type = #{original_item}")
    when "document_types"
      ActiveRecord::Base.connection.execute("Update documents set doc_type_id =#{updated_item} where company_id = #{company_id} and doc_type_id = #{original_item}")
      ActiveRecord::Base.connection.execute("Update links set category_id =#{updated_item} where company_id = #{company_id} and category_id =#{original_item} ")
      # ActiveRecord::Base.connection.execute("Update documents set doc_type_id =#{updated_item} where company_id = #{company_id} and doc_type_id = #{original_item}")
    when "salutation_types"
      ActiveRecord::Base.connection.execute("Update contacts set salutation_id =#{updated_item} where company_id = #{company_id} and salutation_id =#{original_item}")
      ActiveRecord::Base.connection.execute("Update matter_peoples set salutation_id =#{updated_item} where company_id = #{company_id} and salutation_id =#{original_item}")
    when "contact_stages"
      ActiveRecord::Base.connection.execute("Update contacts set contact_stage_id =#{updated_item} where company_id = #{company_id} and contact_stage_id =#{original_item}")
    when "team_roles"
      ActiveRecord::Base.connection.execute("Update matter_peoples set matter_team_role_id =#{updated_item} where company_id = #{company_id} and matter_team_role_id =#{original_item}")
    when "matter_fact_types"
      ActiveRecord::Base.connection.execute("Update matter_facts set status_id =#{updated_item} where company_id = #{company_id} and status_id =#{original_item}")
    when "task_types"
      ActiveRecord::Base.connection.execute("Update matter_tasks set category_type_id =#{updated_item} where company_id = #{company_id} and category_type_id =#{original_item}")
    end
  end

end
