class ApplicationController < ActionController::Base

  if ENV["HOST_NAME"] == "https://production.liviatech.com"
    include ExceptionNotification::Notifiable
  end
  $time=30.minutes
  Max_Attachment_Size = 104857600 #File size in bytes to be used for max file upload size :Pratik
  Max_Single_Attachment_Size = 104857600/2 #File size in bytes to be used for max file upload size :Supriya
  helper :all
  helper_method :current_user_session, :current_user,:current_company, :assigned_user #:add_activate_comment, :add_deactivate_comment
  helper_method :current_service_session,:sorted_contacts,:get_date_on_specified_range,:get_upcoming_setting#,:end_user
  helper_method :find_calendar,:get_company_id,:get_employee_user_id, :get_employee_user,:get_contact_id,:get_employees,:get_service_session
  helper_method :is_secretary?,:is_liviaadmin, :is_admin, :is_client, :is_team_manager, :is_livia_emp,
    :is_lawfirmadmin, :is_secretary_or_team_manager?, :is_cpa?, :get_user_designation_id, :is_access_matter?, :is_access_t_and_e?,
    :is_common_pool_team_manager?, :belongs_to_back_office?, :is_back_office_team_manager?, :belongs_to_common_pool?, :is_back_office_agent?, :is_front_office_agent?
  protect_from_forgery
  filter_parameter_logging :password, :password_confirmation
  before_filter  :set_locale #,:set_user_time_zone
  before_filter :set_lawyer_for_livian, :bread,:load_sticky_notes
  before_filter :set_cattr_current_user
  before_filter :set_cattr_current_lawyer
  after_filter :set_previous_referer ,:except => [:get_children ,:supercede_or_replace_document]
  before_filter :set_timezone
  before_filter :check_if_ipad_request#,:set_smtp_email_settings
  before_filter :check_if_changed_password

#  def set_smtp_email_settings
#    if current_user
#      current_company=current_company
#      company_smtp = CompanyEmailSetting.find_by_company_id_and_setting_type(current_company.id,'SMTP')
#      company_pop = CompanyEmailSetting.find_by_company_id_and_setting_type(current_company.id,'POP3')
#      if company_smtp.nil?
#        company_smtp = CompanyEmailSetting.find_by_company_id_and_setting_type(1,'SMTP')
#        company_pop = CompanyEmailSetting.find_by_company_id_and_setting_type(1,'POP3')
#      end
#      CampaignMailer.smtp_settings = {
#        :address               => company_smtp.address ,
#        :port                  => company_smtp.port,
#        :domain                => company_smtp.domain,
#        :user_name             => company_smtp.user_name,
#        :password              => company_smtp.password,
#        :authentication => :plain,
#        :enable_ssl          =>  company_smtp.enable_ssl,
#        :enable_starttls_auto  => company_smtp.enable_starttls_auto
#      }
#    end
#  end

  # Added To set current page referer in session -Pratik A J
  # replaced request.request_uri to request.referer for display previous url with base url added by Ganesh
  # Used in Before filter
  def set_previous_referer
    session[:prev_referer] = request.referer
  end

  # Used in Before filter
  def set_timezone # before filter
    zone = current_user.time_zone if current_user
    zone ||= 'UTC'
    Time.zone = zone
  end

  # Used in Before filter
  def set_cattr_current_user
    $zimbra_tz = {"International Date Line West"=>"Pacific/Midway" ,"Midway Island"=>"Pacific/Midway","Samoa"=>"Pacific/Midway" ,"Hawaii"=>"Pacific/Honolulu" ,"Alaska" =>"America/Anchorage" ,"Pacific Time (US & Canada)" =>"America/Los_Angeles" ,"Tijuana" =>"America/Los_Angeles" ,"Arizona" =>"America/Phoenix" , "Chihuahua" =>"America/Chihuahua" , "Mazatlan" =>"America/Chihuahua" , "Mountain Time (US & Canada)" => "America/Denver" , "Central America" => "America/Guatemala" , "Central Time (US & Canada)" => "America/Chicago" ,"Guadalajara" => "America/Mexico_City" , "Mexico City" => "America/Mexico_City" , "Monterrey" => "America/Mexico_City", "Saskatchewan" => "America/Regina" , "Bogota" => "America/Bogota" , "Eastern Time (US & Canada)" => "America/New_York" , "Indiana (East)" => "America/Indiana/Indianapolis" , "Lima" => "America/Bogota" , "Quito" => "America/Bogota" , "Caracas" => "America/Caracas" , "Atlantic Time (Canada)" => "America/Halifax" , "La Paz" => "America/Chihuahua" , "Santiago" => "America/Santiago" , "Newfoundland" => "America/St_Johns" , "Brasilia" => "America/Sao_Paulo" , "Buenos Aires" => "America/Argentina/Buenos_Aires" , "Georgetown" => "America/Guyana" , "Greenland" => "America/Godthab" , "Mid-Atlantic" => "Atlantic/South_Georgia" , "Azores" => "Atlantic/Azores" , "Cape Verde Is." => "Atlantic/Cape_Verde" , "Casablanca" => "Africa/Casablanca" , "Dublin" => "Europe/Dublin" , "Edinburgh" => "Europe/London" , "Lisbon" => "Europe/Lisbon" , "London" => "Europe/London" , "Monrovia" => "Africa/Monrovia" , "UTC" => "Etc/UTC" , "Amsterdam" => "Europe/Berlin" , "Belgrade" => "Europe/Belgrade" , "Berlin" => "Europe/Berlin" , "Bern" => "Europe/Berlin" , "Bratislava" => "Europe/Belgrade" , "Brussels" => "Europe/Brussels" , "Budapest" => "Europe/Belgrade" , "Copenhagen" => "Europe/Brussels" , "Ljubljana" => "Europe/Belgrade" , "Madrid" => "Europe/Brussels" , "Paris" => "Europe/Brussels" , "Prague" => "Europe/Belgrade" , "Rome" => "Europe/Berlin" , "Sarajevo" => "Europe/Belgrade" , "Skopje" => "Europe/Belgrade" , "Stockholm" => "Europe/Berlin" , "Vienna" => "Europe/Berlin" , "Warsaw" => "Europe/Warsaw" , "West Central Africa" => "Africa/Algiers" , "Zagreb" => "Europe/Belgrade" , "Athens" => "Europe/Athens" , "Bucharest" => "Europe/Athens" , "Cairo" => "Africa/Cairo" , "Harare" => "Africa/Harare" , "Helsinki" => "Europe/Helsinki" , "Istanbul" => "Europe/Athens" , "Jerusalem" => "Asia/Jerusalem" , "Minsk" => "Europe/Athens" , "Pretoria" => "Africa/Harare" , "Riga" => "Europe/Helsinki" , "Sofia" => "Europe/Helsinki" , "Tallinn" => "Europe/Helsinki" , "Vilnius" => "Europe/Helsinki" , "Baghdad" => "Asia/Baghdad" , "Kuwait" => "Asia/Kuwait" , "Moscow" => "Europe/Moscow" , "Nairobi" => "Africa/Nairobi" , "Riyadh" => "Asia/Kuwait" , "St. Petersburg" => "Europe/Moscow" , "Volgograd" => "Europe/Moscow" , "Tehran" => "Asia/Tehran" , "Abu Dhabi" => "Asia/Muscat" , "Baku" => "Asia/Baku" , "Muscat" => "Asia/Muscat" , "Tbilisi" => "Asia/Baku" , "Yerevan" => "Asia/Baku" , "Kabul" => "Asia/Kabul" , "Ekaterinburg" => "Asia/Yekaterinburg" , "Islamabad" => "Asia/Karachi" , "Karachi" => "Asia/Karachi" , "Tashkent" => "Asia/Karachi" , "Chennai" => "Asia/Kolkata" , "Kolkata" => "Asia/Kolkata" , "Mumbai" => "Asia/Kolkata" , "New Delhi" => "Asia/Kolkata" , "Sri Jayawardenepura" => "Asia/Colombo" , "Kathmandu" => "Asia/Kathmandu" , "Almaty" => "Asia/Novosibirsk" , "Astana" => "Asia/Dhaka" , "Dhaka" => "Asia/Dhaka" , "Novosibirsk" => "Asia/Novosibirsk" , "Rangoon" => "Asia/Rangoon" , "Bangkok" => "Asia/Bangkok" , "Hanoi" => "Asia/Bangkok" , "Jakarta" => "Asia/Bangkok" , "Krasnoyarsk" => "Asia/Krasnoyarsk" , "Beijing" => "Asia/Hong_Kong" , "Chongqing" => "Asia/Chongqing" , "Hong Kong" => "Asia/Hong_Kong" , "Irkutsk" => "Asia/Irkutsk" , "Kuala Lumpur" => "Asia/Kuala_Lumpur" , "Perth" => "Australia/Perth" , "Singapore" => "Asia/Kuala_Lumpur" ,  "Taipei" => "Asia/Taipei" , "Ulaan Bataar" => "Asia/Irkutsk" , "Urumqi" => "Asia/Hong_Kong" , "Osaka" => "Asia/Tokyo" , "Sapporo" => "Asia/Tokyo" , "Seoul" => "Asia/Seoul" , "Tokyo" => "Asia/Tokyo" ,  "Yakutsk" => "Asia/Yakutsk" , "Adelaide" => "Australia/Adelaide" , "Darwin" => "Australia/Darwin" , "Brisbane" => "Australia/Brisbane" , "Canberra" => "Australia/Sydney" , "Guam" => "Pacific/Guam" , "Hobart" => "Australia/Hobart" , "Melbourne" => "Australia/Melbourne" , "Port Moresby" => "Pacific/Guam" , "Sydney" => "Australia/Sydney" , "Vladivostok" => "Asia/Vladivostok" , "Magadan" => "Asia/Magadan" , "New Caledonia" => "Asia/Magadan" , "Solomon Is." => "Asia/Magadan" , "Auckland" => "Pacific/Auckland" , "Fiji" => "Pacific/Fiji" , "Kamchatka" => "Pacific/Fiji" , "Marshall Is." => "Pacific/Fiji" , "Wellington" => "Pacific/Auckland" , "Nuku'alofa" => "Pacific/Tongatapu"}
    User.current_user = current_user
  end

  # Used in Before filter
  def set_cattr_current_lawyer
    if current_user
      if is_secretary_or_team_manager? && current_service_session
        User.current_lawyer = current_service_session.assignment.nil? ?  current_service_session.user : current_service_session.assignment.user
      elsif !is_secretary?
        User.current_lawyer = current_user
      end
    end
  end

  def load_sticky_notes
    if controller_name != 'sessions' && assigned_user
      @sticky_note_user = User.find(assigned_user)
      if @sticky_note_user.sticky_notes.blank?
        @sticky_note_user.sticky_notes.build(:assigned_to_user_id=>assigned_user)
        @note_count = ''
      else
        @note_count = @sticky_note_user.sticky_notes.size.try(:to_s)
      end
    end
  end

  # calls the breadcrumb, init check the home path for different logins
  def bread
    if current_user.present?
      if is_secretary_or_team_manager?
        home_path = :physical_liviaservices_livia_secretaries_url
      else
        home_path = :physical_clientservices_home_index_path
      end
      add_breadcrumb I18n.t(:label_home), home_path
    end
  end

  def set_lawyer_for_livian
    current_user.verified_lawyer_id_by_secretary = session[:verified_lawyer_id] if current_user
    current_user.service_provider_id_by_telephony = session[:verified_secretary_id] if current_user
  end


  def set_locale
    curr_user = current_user
    unless curr_user.nil?   # Modified By - Hitesh
      return true if (curr_user.role?(:secretary) and session[:service_session].nil?)
    else
      return true
    end
    dyn_label = current_company.dynamic_label unless curr_user.blank?
    params[:locale] = dyn_label.file_name if dyn_label
    I18n.locale = params[:locale].to_s
  end
  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = t(:flash_application_error)
    redirect_to root_url
  end

  # Used to show new instructions on left hand panal in 'contacts','accounts','opportunities','campaigns','matters'
  # added order by last_name asc,first_name asc  gaensh 19052011
  def new_instructions
    cid = current_company.id
    @matters = Matter.find_all_matters_for_instructions(get_employee_user_id, cid).collect{|mt| [mt.clipped_name ,mt.id]}
    #Matter.team_matters(get_employee_user_id, get_company_id).collect{|mt| [mt.clipped_name ,mt.id]}
    @contacts = Contact.all(:conditions => ["(company_id = ? AND status_type != #{CompanyLookup.find_by_lvalue_and_company_id("Rejected", current_company.id).id})", cid], :order => "coalesce(last_name,'') || '' || first_name || '' || coalesce(middle_name, '') ASC")
    @contacts = @contacts.collect { |contact| [contact.full_name, contact.id]  }
    @note = Communication.new
    @max_upload_size = Max_Attachment_Size
    render :layout => false
  end

  #Email Id is used when 2 contacts are having same email ids and share same client login : Surekha
  def get_contact_id    
    Contact.all(:conditions => ["email = ? AND company_id = ?", current_user.email, current_user.company_id], :select => :id).collect(&:id)
  end

  # used for document search
  def get_date_on_specified_range(date_type, from_date, to_date)
    begin
      date_from = Time.parse(from_date)
      date_to = Time.parse(to_date)
    rescue => e
      return {}
    end
    if (date_type == 'Modified Date')
      return {:document_updated_date => date_from.to_i..(date_to + 1.day).to_i}
    elsif (date_type == 'Created Date')
      return {:document_created_date => date_from.to_i..(date_to + 1.day).to_i}
    elsif (date_type == 'Link Created Date')
      return {:link_created_date => date_from.to_i..(date_to + 1.day).to_i}
    elsif (date_type == 'Link Modified Date')
      return {:link_updated_date => date_from.to_i..(date_to + 1.day).to_i}
    else
      return {}
    end
  end

  # Check if account is deactivated
  def unique_name(obj)
    #Select query throw exception if ' char is present in select
    #So searching ' char and updating to ''
    nm = obj.name.strip.gsub("'","''") unless obj.name.nil?
    account_name=Account.find(:first, :conditions => ["name ilike ?", "#{nm}"])
    if account_name.nil?
      @account_name=nil
      return true
    else
      @account_name=obj
      return false
    end
  end

  # Check if the email given is unique for the contact.
  #Name original unique_email function--4/4/2011 By Ketki
=begin
  Not in use
  def unique_email_original(obj, params)
    #raise params.inspect
    obj['email'].strip! if obj['email']
    obj['phone'].strip! if obj['phone']
    if params[:action] == 'add_client_contact'
      return true if params[:allow_dup] || params[:matter_people][:email].nil? || params[:matter_people][:phone].nil?
    else
      return true if params[:allow_dup] || params[:contact][:email].nil? || params[:contact][:phone].nil?
    end
    return true if params.has_key?(:activate) && params[:activate].eql?("1")
    # Return true incase of invalid object and let the model handle validation.
    return true unless obj.valid?
    @same_contacts = []
    begin
      comp_id=get_company_id
    rescue
      comp_id=User.find_by_email(params[:email_add]).try(:company_id) unless comp_id
    end
    @same_contacts << Contact.find_with_deleted(:all,:conditions=>{:email=>obj.email,:company_id=>comp_id}) if obj.email.present?
    @same_contacts << Contact.find_with_deleted(:all,:conditions=>{:phone=>obj.phone,:company_id=>comp_id}) if obj.phone.present?
    @same_contacts.flatten!
    unless obj.valid?
      @same_contacts=[]
      return true
    end
    @deleted_cnt_id,@exist_but_deleted=nil,false
    if params[:action] == 'add_client_contact'
      @same_contacts.each{|sc| (@exist_but_deleted=true;@deleted_cnt_id=sc.id) if(sc.first_name==obj.name && sc.last_name==obj.last_name && sc.deleted_at.present?)} if @same_contacts.present?
    else
      @same_contacts.each{|sc| (@exist_but_deleted=true;@deleted_cnt_id=sc.id) if(sc.first_name==obj.first_name && sc.last_name==obj.last_name && sc.deleted_at.present?)} if @same_contacts.present?
    end
    @same_contacts.map!{|sc| sc if sc.id==@deleted_cnt_id } if @deleted_cnt_id.present?
    @same_contacts.map!{|sc| sc if sc.deleted_at.nil? } unless @deleted_cnt_id.present?
    @same_contacts = @same_contacts - [obj]
    @same_contacts.compact!
    @same_contacts.uniq!
    @same_contacts.empty?
  end
=end

  # This method is for creating dynamic_label file for companies during company create as well update  --   Rahul 3/5/2011
  def create_company_own_file(abt_paths,selected_file_type,file_name)
    unless selected_file_type.nil?
      f = File.new(abt_paths + file_name + ".yml" ,"w+")
      exist_file_contents = File.read(abt_paths + "#{selected_file_type}.yml")
      exist_file_contents =exist_file_contents.sub("#{selected_file_type}",file_name)
      f.write(exist_file_contents)
      f.close
    end
    I18n.load_path << "#{RAILS_ROOT}/config/locales/" + file_name + ".yml"
    I18n.reload!
  end

  # Recreated unique_email method due to many issues in previous method - Ketki 4/4/2011
  def unique_email(obj, params)
    obj['email'].strip! if obj['email']
    obj['phone'].strip! if obj['phone']
    matter_people = (params[:action] == 'add_client_contact' or params[:action] == 'edit_client_contact' or !params[:matter_people].blank?)
    param_contact = matter_people ? params[:matter_people] : params[:contact]
    same_phone = obj.phone == param_contact[:phone]
    same_email = obj.email == param_contact[:email]
    checkemail = obj.new_record? ? obj.email : param_contact[:email]
    checkphone = obj.new_record? ? obj.phone : param_contact[:phone]
    if matter_people
      return true if params[:allow_dup] || params[:matter_people][:email].nil? || params[:matter_people][:phone].nil?
    else
      return true if params[:allow_dup] || params[:contact][:email].nil? || params[:contact][:phone].nil?
    end
    return true if params.has_key?(:activate) && params[:activate].eql?("1")
    # Return true incase of invalid object and let the model handle validation.
    #return true unless obj.valid?
    @same_contacts = []
    params['contact'].each{|k,v| obj[k] = v} if params[:contact]
    begin
      comp_id=get_company_id
    rescue
      comp_id=User.find_by_email(params[:email_add]).try(:company_id) unless comp_id
    end
#    @same_contacts << Contact.find_with_deleted(:all, :conditions => {:email => checkemail, :company_id => comp_id}) if param_contact[:email].present? && (obj.new_record? ? true : !same_email)
#    @same_contacts << Contact.find_with_deleted(:all, :conditions => {:phone => checkphone, :company_id => comp_id}) if param_contact[:phone].present? && (obj.new_record? ? true : !same_phone)
    @same_contacts << Contact.find(:all, :conditions => {:email => checkemail, :company_id => comp_id}) if param_contact[:email].present? && (obj.new_record? ? true : !same_email)
    @same_contacts << Contact.find(:all, :conditions => {:phone => checkphone, :company_id => comp_id}) if param_contact[:phone].present? && (obj.new_record? ? true : !same_phone)
    @same_contacts.flatten!
    @deleted_cnt_id,@exist_but_deleted=nil,false
    unless @same_contacts.blank?
      if params[:action] == 'add_client_contact' or params[:action] == 'edit_client_contact'
        @same_contacts.each{|sc| (@exist_but_deleted=true;@deleted_cnt_id=sc.id) if(sc.first_name==obj.name && sc.last_name==obj.last_name && sc.deleted_at.present?)} if @same_contacts.present?
      else
        @same_contacts.each{|sc| (@exist_but_deleted=true;@deleted_cnt_id=sc.id) if(sc.first_name==obj.first_name && sc.last_name==obj.last_name && sc.deleted_at.present?)} if @same_contacts.present?
      end
      @same_contacts.map!{|sc| sc if sc.id==@deleted_cnt_id } if @deleted_cnt_id.present?
      @same_contacts.map!{|sc| sc if sc.deleted_at.nil? } unless @deleted_cnt_id.present?
      @same_contacts = @same_contacts - [obj]
    end
    @same_contacts.compact!
    @same_contacts.uniq!
    @same_contacts.empty?
  end

  # Returns matter specific contacts
  def get_matters_contact
    unless (params[:comID].eql?("undefined")||params[:comID].blank?)
      @comID             = params[:comID].to_i
      @com_notes_entries = Communication.find(@comID)
      @formINDEX         = "undefined"
      @form_contact_field = "com_notes_entries[contact_id]"
      @form_span_id       = '#contact_span'
    else
      @comID             = "undefined"
      @com_notes_entries = "undefined"
      @formINDEX         = params[:formINDEX].to_i
      @form_contact_field = "com_notes_entries[#{@formINDEX}][contact_id]"
      @form_span_id       = "#contact_#{@formINDEX}_span"
    end
    @contacts = (@formINDEX.eql?("undefined"))? Contact.all(:conditions => ["status_type != '#{CompanyLookup.find_by_lvalue_and_company_id("Rejected",current_company.id).id}' AND (company_id = ?)",@com_notes_entries.company_id]) : Contact.all(:conditions => ["status_type != '#{CompanyLookup.find_by_lvalue_and_company_id("Rejected", current_company.id).id}' AND (company_id = ?)", get_company_id])
    unless (params[:matter_id].blank? ||params[:matter_id].eql?("undefined"))
      @contacts = []
      @matters = Matter.find(params[:matter_id])
      @contacts << @matters.contact if !@matters.contact.nil?
      @contact_id = @matters.contact.id
    else
      @contact_id = params[:contact_id].blank? ? '' : params[:contact_id].to_i
    end
  end

#  def add_activate_comment(object,commentable_type,current_user_id)
#    object.comments<< Comment.new(:title=> commentable_type + ' Activated',
#      :created_by_user_id=> current_user_id,
#      :commentable_id => object.id,:commentable_type=> commentable_type,
#      :comment => commentable_type + " Activated",
#      :company_id=> object.company_id )
#  end
#
#  def add_deactivate_comment(object,commentable_type,current_user_id)
#    object.comments<< Comment.new(:title=> commentable_type + ' Deactivated',
#      :created_by_user_id=> current_user_id,
#      :commentable_id => object.id,:commentable_type=> commentable_type,
#      :comment => commentable_type + " Deactivated",
#      :company_id=> object.company_id )
#  end

  # Get employee all matters/contact specific employee matters and updates contact.
  def get_new_matters
    @contacts =Contact.find(params[:contact_id]) unless  params[:contact_id].blank?
    @matter_id = params[:matter_id].blank? ? '' : params[:matter_id].to_i
    # Below code will check comID is preset or not.
    # comID is preset for edit_task,show action in communication.
    unless (params[:comID].eql?("undefined")||params[:comID].blank?)
      @comID             = params[:comID].to_i
      #Below code is to find details for the notes.
      @com_notes_entries = Communication.find(@comID)
      @formINDEX         = "undefined"
      @form_contact_field = "com_notes_entries"
      @form_span_id       = '#matters_div'
      @matters = params[:contact_id].blank? ? Matter.team_matters(@com_notes_entries.assigned_by_employee_user_id, @com_notes_entries.company_id).uniq : Matter.employee_contact_matters(@com_notes_entries.assigned_by_employee_user_id, @com_notes_entries.company_id, @contacts.id,nil)
    else
      @comID             = "undefined"
      @com_notes_entries = "undefined"
      @formINDEX         = params[:formINDEX].to_i
      @form_contact_field = "com_notes_entries[#{@formINDEX}]"
      @form_span_id       = "#matters_#{@formINDEX}_div"
      @matters = params[:contact_id].blank? ? Matter.team_matters(get_employee_user_id, get_company_id).uniq : Matter.employee_contact_matters(get_employee_user_id, get_company_id, @contacts.id,nil)
    end
  end

  def get_matters_contacts
    if params[:cnt_span_id].present? && (params[:cnt_span_id]=="#old_cnt_span" || params[:cnt_span_id]=="#comm_cnt_#{params[:formINDEX].to_i}_span")
      # this code is for livian login in - Supriya
      if params[:cnt_span_id]=="#old_cnt_span"
        @com_notes_entries = Communication.find(params[:formINDEX].to_i)
      end
      if params[:contact_id].present?
        @contacts=Contact.find(params[:contact_id])
        @matters= @com_notes_entries.present? ? Matter.employee_contact_matters(@com_notes_entries.assigned_by_employee_user_id, @com_notes_entries.company_id, @contacts.id,nil) : Matter.employee_contact_matters(get_employee_user_id, get_company_id, @contacts.id,nil)
      end
      if params[:matter_id].present?
        @matter=Matter.find(params[:matter_id])
        @contacts=[@matter.contact]
      end
      if params[:contact_id].blank? &&  params[:matter_id].blank?
        if @com_notes_entries.present?
          @matters =  Matter.team_matters(@com_notes_entries.assigned_by_employee_user_id, @com_notes_entries.company_id)
        else
          @matters = Matter.team_matters(get_employee_user_id, get_company_id).uniq
        end
        @contacts = Contact.all(:conditions => ["status_type != '#{CompanyLookup.find_by_lvalue_and_company_id("Rejected",current_company.id).id}' AND (company_id = ?)",get_company_id], :order => "first_name")
      end
    else
      # code for lawyer login - Sanil
      if params[:contact_id].present?
        @contacts=Contact.find(params[:contact_id])
        @matters=@contacts.matters.team_matters(get_employee_user_id, get_company_id).uniq
      end
      if params[:matter_id].present?
        @matter=Matter.find(params[:matter_id])
        @contacts=[@matter.contact]
      end
      if params[:contact_id].blank? &&  params[:matter_id].blank?
        @matters = Matter.team_matters(get_employee_user_id, get_company_id)
        @contacts = Contact.all(:conditions => ["(company_id = ? AND status_type != #{CompanyLookup.find_by_lvalue_and_company_id("Rejected",current_company.id).id})", current_company.id], :order => 'first_name')
      end
    end
  end

  #This method redirects to a url based on a condition
  def redirect_if(ok, url)
    if ok
      redirect_to url
    end
  end

  # Returns employee records for current lawyer's firm.
  def url_link
    @request_protocol =request.env['SERVER_PROTOCOL']== "HTTP/1.1" ? "http://" : "https://"
    @request_url = @request_protocol + request.env['HTTP_HOST']
    return @request_url
  end

  def get_employee_user
    if is_secretary_or_team_manager?
      current_service_session.assignment.nil? ? current_service_session.user : current_service_session.assignment.user
    else
      current_user
    end
  end

  # Current employee's user ID.
  def get_employee_user_id
    get_employee_user.id
  end

  # returns the user setting for upcoming for loged in user
  def get_upcoming_setting
    current_user.upcoming
  end

  # returns the role id of the current user
  def get_user_role_id
    if is_secretary_or_team_manager?
      current_service_session.assignment.nil? ? current_service_session.user.employee.role_id : current_service_session.assignment.user.employee.role_id
    else
      current_user.end_user.role_id
    end
  end

  def get_user_designation_id
    if is_secretary_or_team_manager?
      return current_service_session.assignment.nil? ? current_service_session.user.employee.designation_id : current_service_session.assignment.user.employee.designation_id
    else
      return current_user.end_user.designation_id
    end
  end

  #returns the current lawyers email address
  def get_lawyer_email
    if is_secretary_or_team_manager?
      current_service_session.assignment.nil? ? current_service_session.user.email : current_service_session.assignment.user.email
    else
      current_user.end_user.role_id
    end
  end

  #returns the current lawyers comapny id
  def get_company_id
    if is_secretary_or_team_manager?
      current_service_session.assignment.nil? ? current_service_session.user.company_id : current_service_session.assignment.user.company_id
    else
      current_user.company_id
    end
  end

  # Return lawyer's company id, if secretary is logged-in.
  # Else, return current logged-in user's company id.
  def current_company
    if is_secretary_or_team_manager? && current_service_session
      if current_service_session.assignment.nil?
        current_company||= current_service_session.user.company(:include=>[:contact_stages,:rating_type,:expense_types,:company_activity_types,:research_types,:doc_sources,:nonliti_types,:liti_types,:company_sources,:phases])
      else
        current_company||= current_service_session.assignment.user.company(:include=>[:contact_stages,:rating_type,:expense_types,:company_activity_types,:research_types,:doc_sources,:nonliti_types,:liti_types,:company_sources,:phases])
      end
    else
      current_company ||= current_user.company(:include=>[:contact_stages,:rating_type,:expense_types,:company_activity_types,:research_types,:doc_sources,:nonliti_types,:liti_types,:company_sources,:phases])
    end
    # In production mode the current company was not resetting after logout.
    User.current_company = current_company
    current_company
  end

  #returns contacts and contacts without any account---saneil 25nov
  def sorted_contacts
    @contacts  = current_company.contacts.all(:include => [:accounts] , :conditions=> [current_company.lead_status_types.find_by_lvalue("Rejected") ? "status_type!= '#{current_company.lead_status_types.find_by_lvalue("Rejected").id}'" : ""],:order=>"coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') asc")
    @account_contacts=@contacts.find_all{|c| !c.accounts[0]}
    return @contacts,@account_contacts
  end

  #returns all the employees of the current company
  def get_employees
    @employees =  current_company.employees
  end

  #Returns the matter based on the id
  def get_matter
    @company ||=  current_company
    @matter = Matter.scoped_by_company_id(@company).find(params[:matter_id]) if params[:matter_id].present?
  end

  def sort_order(default)
    "#{(params[:c] || default.to_s).gsub(/[\s;'\"]/,'')} #{params[:d] == 'down' ? 'ASC' : 'DESC'}"
  end

  #Used in sorting to specify the sorting order
  def sort_column_order
      array_for_numeric = ["opportunities.amount","opportunities.probability","contacts.phone","accounts.phone","member_count","responded_date","campaign_member_status_type_id","opportunity","opportunity_amount","matter_risks.details","matter_facts.details","documents.description"]
      null_position = params[:dir].eql?("up")? "NULLS FIRST":"NULLS LAST"
      #--------- SETTING THE SORTING ORDER HERE
      secondary_sort = params[:secondary_sort_direction].eql?("up")? "asc" : "desc"
      sort = params[:dir].eql?("up")? "asc" : "desc"
        if params[:col] && params[:secondary_sort]
#          if(params[:col]=='contacts.assigned_to_employee_user_id' || params[:col]=='accounts.assigned_to_employee_user_id' || params[:col]=='matter_tasks.assigned_to_user_id' )
#            @ord = "users.first_name" + ' ' + sort + ',' + "users.last_name" + ' ' + sort + ',' + params[:secondary_sort] + ' ' + secondary_sort
          if params[:col] == "contacts.last_name" && params[:controller] != "opportunities"
            @ord = "coalesce(#{params[:col]+",'')||''||contacts.first_name||''||coalesce(middle_name,'')  " + sort + ',' +params[:secondary_sort] + ' ' + secondary_sort}"
          else
            @ord = params[:col] + ' ' + sort + ',' +params[:secondary_sort] + ' ' + secondary_sort
          end
        elsif params[:col] && !params[:secondary_sort]
#          if(params[:col]=='contacts.assigned_to_employee_user_id' || params[:col]=='accounts.assigned_to_employee_user_id' || params[:col]=='matter_tasks.assigned_to_user_id' )
#            @ord = "users.first_name"+ ' ' +sort
          if params[:col] == "contacts.last_name" && params[:controller] != "opportunities"
            @ord = "coalesce(#{params[:col]+",'')||''||contacts.first_name||''||coalesce(middle_name,'')  " +sort}"
          else
            @ord = params[:col] + ' ' + sort
          end
        end
  end

  #Used in sticky notes for assigned user
  def assigned_user
    if current_user
      if is_secretary_or_team_manager?
        return session[:verified_lawyer_id]
      elsif current_user.role?(:lawyer)
        return current_user.id
      end
    end
  end

#  def get_sticky_notes
#    if current_user
#      @sticky_note = StickyNote.find_all_by_assigned_to_user_id(assigned_user,:order=>'note_id')  if current_user
#      if @sticky_note.nil?
#        @last_note=0
#      else
#        @last_note=@sticky_note.last.note_id if @sticky_note.present?
#      end
#    end
#  end

  # *****************************************************************************
  # -------------- Checking current user role starts here --------------------------

  def is_secretary?
    current_user.role?:secretary if current_user
  end

  def is_liviaadmin
    current_user.role?:livia_admin
  end

  def is_admin
    if is_liviaadmin
      return true
    end
  end

  def is_client
    current_user.role?:client
  end

  def is_team_manager
    current_user.role?(:team_manager)
  end

  def is_livia_emp
    current_user && !current_user.service_provider.nil?
  end

  def is_lawfirmadmin
    current_user && current_user.role?("lawfirm_admin")
  end

  def is_secretary_or_team_manager?
    is_secretary? or is_team_manager
    # in case of revrting functinality of manager working as livian uncomment followin line
    #is_secretary?
  end

  def is_cpa?
    is_secretary? && current_user.service_provider.has_common_pool_access?
  end

  def is_common_pool_team_manager?
    is_team_manager && current_user.service_provider.has_common_pool_access?
  end

  def is_back_office_agent?
    is_secretary? && current_user.service_provider.has_back_office_access?
  end

  def is_back_office_team_manager?
    is_team_manager && current_user.service_provider.has_back_office_access?
  end

  def belongs_to_back_office?
    is_back_office_agent? || is_back_office_team_manager?
  end

  def belongs_to_common_pool?
    is_common_pool_team_manager? || is_cpa?
  end

  def is_front_office_agent?
    is_secretary? && current_user.service_provider.has_front_office_access?
  end

  def is_front_office_team_manager?
    is_team_manager && current_user.service_provider.has_front_office_access?
  end

  def belongs_to_front_office?
    is_front_office_agent? || is_front_office_team_manager?
  end

  # *****************************************************************************
  # -------------- Checking current user role ends here --------------------------

  #   Feature 6454 : Dynamic listing sequencing
  #   This will update the inherited class of company_lookups,
  #   which is passed through that own inherited class from show and destroy actions.
  #   This method will update the sequence for the records which are deleted_at nil.
  #   Supriya Surve - 24th May 2011 - 08:17
  def set_sequence_for_lookups(modelclass)
    modelclass.each_with_index do |obj, index|
      obj.update_attribute(:sequence, index+1)
    end
  end

  private
#  def render_404
#    url = request.request_uri.downcase
#    is_image = url.include?("png") || url.include?("jpg") || url.include?("gif")
#    unless is_image
#      if url == '/login' or url== '/logout'
#        redirect_to url
#      else
#        render_back
#      end
#    end
#  end

  # Added to redirect to previous page - Pratik A J.
  def render_back
    if session[:prev_referer].present?
      prev_url = session[:prev_referer]
      if prev_url.include?("workspaces")
        prev_url = "/" + prev_url.split("/")[1]
      end
      redirect_to prev_url
    end
  end

  def local_request?
    false
  end

  #:TODO Move method to user model
  #it returns the full name of the current user
  def get_user_name
    @current_user.first_name + ' '+   @current_user.last_name
  end

  #redirect method to redirect back or to the default url
  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  #This method is used in rescue for record not found. It returns a flash notice of record not found and returns back to respective index page
  def respond_to_not_found(*types)
    asset = self.controller_name.singularize
    flick = case self.action_name
    when "destroy" then "delete"
    when "promote" then "convert"
    else self.action_name
    end
    if self.action_name == "show"
      flash[:warning] = "This #{asset} is no longer available."
    else
      flash[:warning] = "Can't #{flick} the #{asset} since it's no longer available."
    end
    respond_to do |format|
      format.html { redirect_to(:action => :index) }                         if types.include?(:html)
      format.js   { render(:update) { |page| page.reload } }                 if types.include?(:js)
      format.xml  { render :text => flash[:warning], :status => :not_found } if types.include?(:xml)
    end
  end

  #This method is used in rescue for record not found. It returns a flash notice of record not found and returns back to respective index page
  def respond_to_related_not_found(related, *types)
    asset = self.controller_name.singularize
    asset = "note" if asset == "comment"
    flash[:warning] = "Can't create the #{asset} since the #{related} is no longer available."
    url = send("#{related.pluralize}_path")
    respond_to do |format|
      format.html { redirect_to(url) }                                       if types.include?(:html)
      format.js   { render(:update) { |page| page.redirect_to(url) } }       if types.include?(:js)
      format.xml  { render :text => flash[:warning], :status => :not_found } if types.include?(:xml)
    end
  end

  # Autocomplete handler for all core controllers.
#  def auto_complete
#    @query = params[:auto_complete_query]
#    @auto_complete = self.controller_name.classify.constantize.my(:user => @current_user, :limit => 10).search(@query)
#    session[:auto_complete] = self.controller_name.to_sym
#    render :template => "common/auto_complete", :layout => nil
#  end

  # Proxy current page for any of the controllers by storing it in a session.
#  def current_page=(page)
#    @current_page = session["#{controller_name}_current_page".to_sym] = page.to_i
#  end
#
#  def current_page
#    page = params[:page] || session["#{controller_name}_current_page".to_sym] || 1
#    @current_page = page.to_i
#  end
#
#  # Proxy current search query for any of the controllers by storing it in a session.
#  def current_query=(query)
#    @current_query = session["#{controller_name}_current_query".to_sym] = query
#  end
#
#  def current_query
#    @current_query = params[:query] || session["#{controller_name}_current_query".to_sym] || ""
#  end

  # Returns the current service provider session. It contains the logged in details of the current service provider
  def current_service_provider_session
    Physical::Liviaservices::ServiceProviderSession.find(session[:sp_session])
  end

  # Returns the current service session. It contains the details of the current service provider and the lawyer service provider is serving to.
  def current_service_session
    unless session[:service_session].nil?
      Physical::Liviaservices::ServiceSession.find(session[:service_session])
    end
  end

  #It sets the @sp_session
  def get_service_session
    if is_secretary_or_team_manager?
      @sp_session = current_service_session
    end
  end

  #It Returns the employee session details
  def current_employee_session
    EmployeeSession.find(session[:eu_session])
  end

  # It returns the employee record
#  def end_user
#    current_user
#    if current_user.present?
#      current_user && !current_user.end_user.nil?
#    else
#      redirect_to login_url
#      return false
#    end
#  end

  # Returns whether the client has the access to the document.
  def access_right_client(document_home_id, contact_id)
    ac = DocumentAccessControl.all(:conditions => {
        :document_home_id => document_home_id,
        :contact_id => contact_id
      })
    if ac.empty?
      return false
    end
    return true
  end

  #Returns true if the current service session exists
  def current_service_session_exists
    if is_secretary_or_team_manager?
      if current_service_session
        return true
      else
        flash[:notice]= t(:flash_logged_out_lawyer)
        redirect_to physical_liviaservices_livia_secretaries_url
        return false
      end
    else
      return true
    end
  end

  #:TODO Move method to lib
  #Sets the timezone of the user
  def set_user_time_zone
    if session[:tz]
      Time.zone = session[:tz]
    elsif UserSession.find && current_user
      Time.zone = current_user.time_zone
    end
  end

  def domain_name
    if request.domain.nil?
      return nil
    else
      return request.domain.split('.').first
    end
  end

  def is_domain_name_liviaservices
    if domain_name.nil?
      return false
    else
      return domain_name == 'liviaservices'
    end
  end

  #:TODO Remove the method
#  def superseed()
#  end

  #:TODO Move it to lib
#  def concate_date(obj)
#    return Date.new(obj['(1i)'].to_i,obj['(2i)'].to_i,obj['(3i)'].to_i)
#  end

  #this function is used to get the email id of the lawfirm when a user id is provided
  def get_lawfirm_admin_email(user_id)
    user = User.find(user_id)
    get_lawfirm_admin_email_for_companyid(user.company_id)
  end

  #this function is used to get the email id of the lawfirm when a company id is provided
  def get_lawfirm_admin_email_for_companyid(company_id)
    user = User.find_all_by_company_id(company_id).find{|user| user if user.role and user.role?('lawfirm_admin') }
    return user.blank??nil:user.email
  end

  #This function is used to get the email id of liviaadmin
  def get_liviaadmin_email
    return User.find(UserRole.find_by_role_id(Role.find_by_name("livia_admin").id).user_id).email
  end

  #:TODO Move method to department model
  #This function is for returning the department name along with its location when a department id is provided
#  def department_with_location(dep_records)
#    dep=[]
#    dep_records.each do |dept|
#      dept.name = dept.name + "(" + dept.location + ")"
#      dep << dept
#      return dep
#    end
#  end

  def get_contact_stages(con_stage,arr=[])
    contact_stages = []
    arr.each do |ar|
      contact_stages << con_stage[ar]
    end
    return contact_stages
  end

  # currently this function returns nothing, so always it is prompted for password
  # but if we want to hold the temporary authentication for some time we can
  # check the temporary authentication time set in the session and modify the
  # behavious accordingly
#  def temporarily_authenticated?
#  end

  def filter_contacts
    unless is_liviaadmin
      respond_to do |format|
        format.html{
          redirect_back_or_default("/")
        }
        format.js{
          render :update do |page|
            page << "<script>window.location.href='/';</script>"
          end
        }
      end
    end
  end

#  def is_user_company?
#    current_user.company_id == @company.id
#  end

  def get_company
    @company ||= Company.find(params[:company_id])
  end

  # It checks the login request.
  # If the request comes from internal subnet ip or localhost then it return true
  # otherwise false.
#  def authorized_subnet
#    addr = request.remote_addr
#    if (AUTHORIZE_SUBNET.match(addr) || LOCAL_IP.match(addr))
#      return true
#    else
#      return false
#    end
#  end

  def url_check(type)
    redirect_to :overwrite_params => {:controller=>'company/utilities', :action=>:utility,:type=>type}
  end

  # It is use to clear the logedin user session,
  # before of destoying current user session it log his end time in respective table.
  # then set all the session variables with nil.
  # Added by - Hitesh
  def destroy_current_user_session
    # if logedin user is service provider,
    # then before destroy his session log his end time of service in service_session table
    # with respact to verified lawyer.
    if session[:service_session]
      @svc_sesion = current_service_session
      if @svc_sesion
        @svc_sesion.session_end = Time.zone.now
        @svc_sesion.save!
      end
    end
    # if logedin user is service provider,
    # then before destory his session log his end time in service_provider_session table.
    if session[:sp_session]
      @sp_sesion = current_service_provider_session
      if @sp_sesion
        @sp_sesion.session_end = Time.zone.now
        @sp_sesion.save!
        spuser = User.find(ServiceProvider.find(@sp_sesion.service_provider_id).user_id)
        spuser.update_attribute(:is_signedin, false)
      end
    end
    # if logedin user is lawyer,
    # then before destroy his session log his end time in the employee_session table.
    if session[:eu_session]
      @eu_sesion = current_employee_session
      if @eu_sesion
        @eu_sesion.session_end = Time.zone.now
        @eu_sesion.save!
        user = User.find(Employee.find(@eu_sesion.employee_id).user_id)
        user.update_attribute(:is_signedin, false)
      end
    end
  end

  def rounding(val)
    decimal_rounding(val)
  end


  def set_params_filter
    if search = params[:search]
      hash = {}
      search.keys.each do |key|
        hash[key.sub("--",".")] = search[key].strip
      end
      params[:search] = hash
    end
  end

#  def session_time_remaining
#    if request[:controller].eql?("zimbra_mail")
#      $time = 3.hours * 1000
#    else
#      $time = 30.minutes * 1000
#    end
#  end

  def check_if_ipad_request
    if request.user_agent =~ /iPad/
      @ipad_req = true
    end
  end

  # generating 50 character string token
  def generate_token
    chars = ['A'..'Z', 'a'..'z', '0'..'9'].map{|r|r.to_a}.flatten
    Array.new(50).map{chars[rand(chars.size)]}.join
  end

  protected

  def after_sign_in_path_for(role_name)
    path=nil
    actual_root = root_url
    case role_name
    when "secretary"
      path = actual_root + 'physical/liviaservices/livia_secretaries'
      sp = current_user.service_provider
      if sp.present? and params[:employee_id]
        record = Physical::Liviaservices::ServiceProviderEmployeeMappings.first(:joins => "INNER JOIN employees ON service_provider_employee_mappings.employee_user_id=employees.user_id",:conditions => ["service_provider_employee_mappings.service_provider_id=? AND employees.id=?", sp.id, params[:employee_id]])
        unless record.nil?
          params[:service_provider_id]=sp.id
        end
      end
      if  params[:service_provider_id].present? and  params[:employee_id].present?
        path+="?service_provider_id=#{params[:service_provider_id]}" + "&employee_id=#{params[:employee_id]}" + "&call_id=#{params[:call_id]}"
      elsif params[:employee_id].present?
        path+="?employee_id=#{params[:employee_id]}" + "&call_id=#{params[:call_id]}"
      elsif params[:employee_verified].present?
        path+="/show_lawyer_list" if params[:employee_verified] == "false"
      end
    when "lawyer"
      path= actual_root + 'physical/clientservices/home'
    when "client"
      path= actual_root + 'matter_clients'
    when "livia_admin"
      path= actual_root + 'companies'
    when "lawfirm_admin"
      path=lawfirm_admins_url
    when "manager"
      path=physical_liviaservices_managers_portal_path
    when "team_manager"
      path = actual_root + 'physical/liviaservices/livia_secretaries'
    else
      path=contacts_path
    end
    path
  end

  def create_sessions(role_name,resource)
    if role_name.eql?('secretary') or role_name.eql?('team_manager')
      sp_session = Physical::Liviaservices::ServiceProviderSession.create(:service_provider_id=>resource.service_provider.id,
        :session_start => Time.zone.now, :company_id => resource.company_id)
      session[:sp_session] = sp_session.id
    end
    if role_name.eql?('lawyer')
      eu_session = EmployeeSession.create(:employee_id=>resource.end_user.id,
        :session_start => Time.zone.now, :company_id => resource.company_id)
      session[:eu_session] = eu_session.id
    end
  end

  def update_session
    obj = ActiveRecord::SessionStore::Session.find_by_session_id(request.session_options[:id])
    if obj.user_id.blank?
      obj.user_id = current_user.id
      obj.send(:update_without_callbacks)
    end
  end

  # Returns date formatted to LIVIA's standard format.
  def livia_date(d)
    unless d.nil?
      d.to_time.strftime("%m/%d/%Y")
    else
      ''
    end
  end

  # Returns date and time formatted to LIVIA's standard format.
  def livia_date_time(d)
    unless d.nil?
      d.to_time.strftime("%m/%d/%Y %H:%M")
    else
      ''
    end
  end

  public
  def check_access_to_matter
    matter = @matter || (Matter.find(params[:id]) if params[:id].present?)
    if matter
      euid = get_employee_user_id
      me ||= MatterPeople.me(current_user.id, matter.id, current_user.company_id)
      if(!is_access_matter? && me && (me.expired? && euid != matter.employee_user_id))
        flash[:error] = "Your role in this matter has expired. Please contact the Lead Lawyer of this matter"
        redirect_to matters_path
      end
    end
  end

  def check_for_matter_acces
    matter = @matter || (Matter.find(params[:id]) if params[:id].present?) || (Matter.find(params[:matter_id]) if params[:matter_id].present? )
    if(!matter.blank? && !is_access_matter?)
      law_team_member_ids = matter.matter_peoples.lawteam_members.collect{|ltm| ltm.employee_user_id}
      if !law_team_member_ids.include?(get_employee_user_id)
        flash[:error]="You do not have a role in this Matter. Please select a role if you want to have access to this Matter"
        redirect_to edit_matter_path(matter)
      end
    end
  end

  def is_lead_lawyer?
    if @matter.present?
      get_employee_user_id == @matter.employee_user_id
    end
  end

  def is_access_matter?
    employee = get_employee
    (employee !=nil && employee.is_firm_manager && current_user.has_access?(:Matters) && employee.can_access_matters)
  end

  def is_access_t_and_e?
    employee = get_employee
    (employee !=nil && employee.is_firm_manager && current_user.has_access?('Time & Expense') && employee.can_access_t_and_e)
  end

#  def if_firmmanager_then_get_matter_employee_user_id(matter)
#     is_access_matter? ? matter.employee_user_id : get_employee_user_id
#  end

  def get_all_parent_matter_activities
    @parent_tasks ||= MatterTask.all(:conditions => ["parent_id IS NOT NULL"], :select => "parent_id")
  end

  def helpdesk_logged_in_id
    if current_service_session.present?
      get_employee_user_id
    else
      current_user.id
    end
  end

  def logout_from_helpdesk(redirect_url=nil)
    session[:helpdesk]= false
    redirect_to APP_URLS[:helpdesk_url] + "/signout_from_livia_portal?redirect_url_address=#{redirect_url}"
  end

  def check_if_changed_password
    if current_user and current_user.role? :lawyer and current_user.sign_in_count < 2 and (!params[:controller].eql?('home') or !params[:controller].eql?('physical/clientservices/home'))
      redirect_to after_sign_in_path_for(current_user.role.name)
    else
      return true
    end
  end

  def remember_past_path(control=nil)
    if control.present?
      params[:controller_name]= control
    end
    controller_path = params[:controller_name].blank? ? (params[:controller]+ "_path") : (params[:controller_name]+ "_path")
    controller_path= (params[:action_name]+ "_"+controller_path) unless params[:action_name].blank?
    perpage= params[:per_page].blank? ?  '25': params[:per_page]
    page= params[:page].blank? ?  '1': params[:page]
    if session[:search].present?
      hash= {:search_items=>true,:search=>session[:search],:mode_type => params[:mode_type],:per_page=>perpage,:page=>page,:contact_type=>params[:contact_type],:matter_status=>params[:matter_status]}
      path=send(controller_path.to_sym,hash)
    elsif params[:letter].present? && !params[:col].present?
      hash= {:letter=>params[:letter],:mode_type => params[:mode_type],:per_page=>perpage,:page=>page,:contact_type=>params[:contact_type],:status=>session[:status],:opp_stage=>params[:opp_stage],:stage=> params[:stage],:matter_status=>params[:matter_status]}
      path=send(controller_path.to_sym,hash)
    elsif params[:col].present?
      hash= {:col =>params[:col],:dir=>params[:dir],:letter=>params[:letter],:search_item=>true,:mode_type => params[:mode_type],:per_page=>perpage,:page=>page,:contact_type=>params[:contact_type],:status=>session[:status],:opp_stage=>params[:opp_stage],:stage=> params[:stage],:matter_status=>params[:matter_status]}
      path=send(controller_path.to_sym,hash)
    else
      if params[:return_url].blank?
        hash= {:mode_type => params[:mode_type],:per_page=>perpage,:page=>page,:contact_type=>params[:contact_type],:status=>session[:status],:opp_stage=>params[:opp_stage],:stage=> params[:stage],:matter_status=>params[:matter_status]}
        path=send(controller_path.to_sym,hash)
      else
        path=params[:return_url]
      end
    end
    return path
  end

  def remember_past_edit_path(value)
    controller_path = params[:controller_name].blank? ? ("edit_" +params[:controller].singularize+ "_path") : ("edit_" +params[:controller_name].singularize+ "_path")
    perpage= params[:per_page].blank? ?  '25': params[:per_page]
    page= params[:page].blank? ?  '1': params[:page]
    if session[:search].present?
      hash={:search_items=>true,:search=>session[:search],:mode_type => params[:mode_type],:per_page=>perpage,:page=>page,:contact_type=>params[:contact_type],:matter_status=>params[:matter_status],:opp_stage=>params[:opp_stage]}
      path=send(controller_path.to_sym,hash.merge!({"id" => value.id}))
    elsif params[:letter].present? && !params[:col].present?
      hash={:letter=>params[:letter],:mode_type => params[:mode_type],:per_page=>perpage,:page=>page,:contact_type=>params[:contact_type],:stage=> params[:stage],:action_name => params[:action_name],:matter_status=>params[:matter_status],:opp_stage=>params[:opp_stage]}
      path=send(controller_path.to_sym,hash.merge!({"id" => value.id}))
    elsif params[:col].present?
      hash={:col =>params[:col],:dir=>params[:dir],:letter=>params[:letter],:search_item=>true,:mode_type => params[:mode_type],:per_page=>perpage,:page=>page,:contact_type=>params[:contact_type],:stage=> params[:stage],:action_name => params[:action_name],:matter_status=>params[:matter_status],:opp_stage=>params[:opp_stage]}
      path=send(controller_path.to_sym,hash.merge!({"id" => value.id}))
    else
      if params[:return_url].blank?
        hash={:mode_type => params[:mode_type],:per_page=>perpage,:page=>page,:contact_type=>params[:contact_type],:stage=> params[:stage],:action_name => params[:action_name],:matter_status=>params[:matter_status],:opp_stage=>params[:opp_stage]}
        path=send(controller_path.to_sym,hash.merge!({"id" => value.id}))
      else
        path=params[:return_url]
      end
    end
    return path
  end

  def get_other_contacts(matter)
    # OLD LOGIC:
    # Return those contacts which are associated with the matter account (if any).
    # Filter away those contacts which are already added to matter client contacts.
    client_contacts = matter.client_contacts
    client_contacts << matter.primary_matter_contact
    client_contacts.compact
  end

  def get_user
    @user = get_employee_user
  end

  public

  # Group of functions for manual paginate for multiple models, used in
  # repositories and document homes controller.
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

  # helper method to generate error messages
  def generate_error_messages_helper(object)
    "<ul>"+object.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.uniq.join(" ") + "</ul>"
  end

  def folder_sql_conditional_str(args,move_for = nil,folder_id=nil,value=nil)
    str =nil
    if(move_for)
      args += " AND id !=?"
      if(value)
        str = [args,value,folder_id]
      else
        str = [args,folder_id]
      end
    elsif(value)
      str = [args,value]
    else
      str = [args]
    end
    str
  end

  def get_employee
    employee =nil
    if is_secretary_or_team_manager?
      employee = Employee.find_by_user_id(current_user.verified_lawyer_id_by_secretary)
    else
      employee = current_user.employee
    end
    employee
  end
end
