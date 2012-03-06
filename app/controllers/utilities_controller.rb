class UtilitiesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :get_base_data
  authorize_resource :class => :utilities
  include RptHelper
  
  layout 'full_screen'

  # This Action manipulates timer fields value in database on each request(Start,Pause,Resume,Reset,Stop). Feature 10280: Timer
  def set_timer
    user = current_user
    base_seconds = (!user.base_seconds && params[:state] == "paused") ? (user.base_seconds.to_i + params[:base_seconds].to_i) : params[:base_seconds].to_i
    user.update_attributes(:timer_start_time => params[:start_time], :timer_state => params[:state], :base_seconds => base_seconds)
    render :nothing => true
  end

  # This Action used to reset timer if duration hours exceeds 24 hours. Feature 10280: Timer
  def fetch_timer
    user = current_user
    if user.timer_state == "running" || user.timer_state == "resume"
      whats_now = Time.parse(params[:time_now])
      timer_time = Time.parse(user.timer_start_time)
      time_diff = (whats_now - timer_time) / 3600
      if time_diff > 24
        user.timer_start_time = nil
        user.timer_state = nil
        user.base_seconds = nil
      end
    end
    render :partial => "layouts/timer"
  end

  def index
    @pagenumber=162
    @employee = @user.employee
    @photo_path = @employee.photo.url.split("public")[1] if @employee.photo
    @additional_documents = 2.times{@employee.document_homes.build}
    @employee_documents = DocumentHome.get_employee_additional_document(@employee.id)
    add_breadcrumb "Utilities", utilities_path
    @tne_invoice_setting = @company.tne_invoice_setting || TneInvoiceSetting.new
  end

  def update_docs
    data = params
    @employee = @company.employees.find(data[:mapable_id])
    @employee_documents = DocumentHome.get_employee_additional_document(@employee.id)
    error = 0
    if data[:employee].present?
      if data[:employee][:photo].present?
        if @employee.update_attributes({:photo => data[:employee][:photo], :photo_upload => true})
          flash[:notice]= "Photo was successfully saved"
        else
          error +=1
          flash_error = @employee.errors.full_messages
        end
      else
        if @employee.update_attribute('reference1',data[:employee][:reference1]) and @employee.update_attribute('reference2',data[:employee][:reference2])
          flash[:notice]= "#{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_uploaded)}"
        else
          error +=1
          flash_error = @employee.errors.full_messages
        end
      end
    end
    if data[:additional_documents].present?
      document = data[:additional_documents][:document_attributes]
      document_error = 0
      document[:data].each do |doc|
        data[:additional_documents].merge!(
          :access_rights=>2, :employee_user_id=>@user.id,
          :created_by_user_id=>@user.id,:company_id=>@company.id,
          :mapable_id=> @employee.id,:mapable_type=>'AdditionalDocument',:upload_stage=>1)
        @additional_documents = DocumentHome.new(data[:additional_documents])
        @document = @additional_documents.documents.build(:data => doc, :name => doc.original_filename, :company_id=>@company.id,  :employee_user_id=> @user.id, :created_by_user_id=>@user.id, :from_others => true )
        unless @additional_documents.save
          document_error += 1
        end
      end
      unless document_error > 0
        flash[:notice]= "#{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_uploaded)}"
      else
        error +=1
        @additional_documents.errors.add(" ", "#{@document.errors.full_messages}")
        flash_error = @additional_documents.errors.full_messages
      end
    end
    if data[:company].present?
      if data[:company][:logo]
        if @company.update_attribute(:logo, data[:company][:logo])
          flash[:notice] = "Logo was successfully saved"
        else
          error +=1
          flash_error = @company.errors.full_messages
        end
      else
        if @company.update_attributes(data[:company])
          flash[:notice] = "Firm details were successfully saved"
        else
          error +=1
          flash_error = @company.errors.full_messages
        end
      end
    end
    if data[:user]
      @user.validate_sequrity_questions(params[:user][:questions_attributes])
      if @user.errors.blank?
        @user.update_attributes(data[:user])
        flash[:notice] = "User has been successfully updated"
      else
        error +=1
        flash_error = @user.errors.full_messages
      end
    end
    if error > 0
      flash[:error] = flash_error
    end
    redirect_to utilities_path
  end

  def update_user
    data = params
    if data[:user] and data[:user][:nick_name]
    end
  end

  def get_base_data
    @user = get_employee_user
    @company = current_company
  end


  def export_contacts
    conditions_hash,@conditions,@total_data,opts,data={},{},{},{},[]
    opts[:l_firm] = get_employee_user.company.name
    header_opts=opts[:l_firm]    
    col = current_company.contacts.find_for_rpt('',conditions_hash,{})
    table_headers = ["Salutation","First name","Middle Name","Last Name","#Primary Email","#Primary Phone","Nick Name","Alternate Email","Source","Source Details","Assigned To","Contact Stage","Company","Title","Street","City","State","Fax","Alternate Phone 1","Alternate Phone 2","Website","Street","City","State","Zip Code","Mobile","Fax","Skype, Account","Linked In Account","Facebook Account","Twitter Account","Other1","Other3","Other3","Other4","Other5","Other6"]
    col.each do |val|

      if val.contact_additional_field.present?
       addl_array1 =  [val.contact_additional_field.business_street,val.contact_additional_field.business_city,
               val.contact_additional_field.business_state,val.contact_additional_field.business_postal_code,
               val.contact_additional_field.business_phone,val.contact_additional_field.businessphone2]
       addl_array2 = [val.contact_additional_field.skype_account,
               val.contact_additional_field.linked_in_account,val.contact_additional_field.facebook_account,
               val.contact_additional_field.twitter_account,val.contact_additional_field.others_1,val.contact_additional_field.others_2,
               val.contact_additional_field.others_3,val.contact_additional_field.others_4,val.contact_additional_field.others_5,
               val.contact_additional_field.others_6]
      else
        addl_array1 =  ['','','','','','']
        addl_array2 = ['','','','','','','','','','']
      end

      if val.address.present?
       add_array1 =  [val.address.street,val.address.city,val.address.state,val.address.zipcode]
      else
       add_array1 =  ['','','','']
      end

      data << [val.salutation,val.first_name,val.middle_name,val.last_name,val.email,val.phone,val.nickname,val.alt_email,
               val.company_source.nil? ? "" : val.company_source.alvalue.try(:titleize),
               val.source_details,val.get_assigned_to,val.contact_stage.alvalue.try(:titleize),
               val.organization.nil? ? "" : val.organization,val.title] + addl_array1 + [val.website] + add_array1 + [val.mobile,val.fax] + addl_array2
    end
    @conditions[:col_length] = col.length
    @total_data=data    
   # respond_to do|format|
      #total_data = sort_display_data
	#		format.xls do
        xls_file = LiviaExcelReport.generate_excel_report_for_contacts(@total_data,data.length,table_headers,header_opts)
        send_data(xls_file,:filename => "contacts_report.xls", :type => 'application/xls', :disposition => 'inline')
	#		end
  # end
  end

end
