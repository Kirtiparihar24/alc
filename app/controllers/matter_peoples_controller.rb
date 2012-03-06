# Matter people represent all the involved persons for the particular matter.
# The people are of four type:
# * People who come from the lawyer's company and are law team member. They only
# have access to see a matter.
# * People who are involved in opposite's law team, and we store them as entries
# in matter_people.
# * People who act as representative of client (they may have some level of
# legal expertise).
# * Other people that are in anyway related to the matter.

class MatterPeoplesController < ApplicationController
  verify :method => :post , :only => [:create] , :redirect_to => {:action => :index}
  verify :method => :put , :only => [:update] , :redirect_to => {:action => :index}

  layout 'left_with_tabs',:except => [:new,:edit]
  
  before_filter :authenticate_user!
  before_filter :get_matter
  before_filter :check_for_matter_acces, :only=>[:index]
  before_filter :check_access_to_matter
  before_filter :get_employee_users
  before_filter :get_user, :only => [:index,:edit,:new,:update,:create]
  add_breadcrumb I18n.t(:text_matters), :matters_path

  def edit_matter_access_periods
    start_date = Date.parse(params[:start_date].to_s)
    end_date = Date.parse(params[:end_date].to_s)    
    respond_to do |format|
      format.js {
        render :update do |page|
          if end_date >= start_date && start_date >= @matter.matter_date
            matter_people_client = MatterPeople.find(params[:matter_people_id])
            matter_access_period_actual = MatterAccessPeriod.find(params[:id_val])
            entry_date = @matter.fetch_time_and_expense_max_date(matter_people_client.employee_user_id)
            in_range_start, in_range_end, ids = MatterAccessPeriod.dates_in_range(@matter,matter_people_client, nil,params[:start_date], params[:end_date], params[:id_val])
            condition = false
            if entry_date.present?
              in_range_start.each do |ma|
                if(entry_date >= ma)
                  condition = true
                  break
                end
              end
            else
              condition = true
            end
            if condition
              in_range_start.each_with_index do |ma, index|
                if (ma <= Date.today && in_range_end[index] >= Date.today) || (matter_access_period_actual.start_date == matter_people_client.start_date && matter_access_period_actual.end_date == matter_people_client.end_date)
                  matter_people_client.update_attributes(:end_date => in_range_end[index], :start_date => ma)
                  break
                end
              end
              ids.each do |id_val|
                MatterAccessPeriod.destroy_all({:id => id_val.to_i})
              end
              in_range_start.each_with_index do |ma, index|
                matter_people_client.matter_access_periods.build(:matter_id => @matter.id,:start_date => ma,:end_date => in_range_end[index], :company_id => matter_people_client.company_id, :employee_user_id => matter_people_client.employee_user_id, :is_active => matter_people_client.is_active).save!
              end
              @matter_access_periods = matter_people_client.matter_access_periods
              in_range_start.each_with_index do |ma, index|
                ###Please don't remove this comment as it may require 
#                if (ma <= Date.today && in_range_end[index] >= Date.today) ||
#                    (matter_access_period_actual.start_date == matter_people_client.start_date &&
#                      matter_access_period_actual.end_date == matter_people_client.end_date)
                if (ma <= Date.today && in_range_end[index] >= Date.today) || (@matter_access_periods.size == 1) ||
                    (matter_access_period_actual.start_date == matter_people_client.start_date &&
                      matter_access_period_actual.end_date == matter_people_client.end_date)
                    page << "jQuery('#period_span_#{matter_people_client.id}').html('<span id= period_span_#{matter_people_client.id}>#{ma.strftime("%m/%d/%Y")} - #{in_range_end[index].strftime("%m/%d/%Y")}</span>');"                  
                  break
                end
              end
              page.replace_html "old_dates", :partial=> "matter_access_period",  :collection => @matter_access_periods
              page.replace_html "add_access",:partial=> "add_row_click",  :locals => {:matter_access_periods => @matter_access_periods}
            else
              errors = "<ul>" +  "<li>" + "There are time and expense entries upto #{entry_date.strftime('%B %d, %Y')}, please select date after that" + "</li>" + "</ul>"
              page << "show_error_msg('matter_lawteam_errors','#{errors}','message_error_div');"
              page << "disableWithPleaseWait('add_lawteam_button', false, 'Save');"
              page << "jQuery('#loader').hide();"
            end
          else
            if end_date < start_date
              errors = "<ul>" +  "<li>" + "Please select proper end date" + "</li>" + "</ul>"
            elsif start_date < @matter.matter_date
              errors = "<ul>" +  "<li>" + "Start date canot be less than matter inception date #{@matter.matter_date.strftime("%d %B, %Y")}" + "</li>" + "</ul>"
            end
            page << "show_error_msg('matter_lawteam_errors','#{errors}','message_error_div');"
            page << "disableWithPleaseWait('add_lawteam_button', false, 'Save');"
            page << "jQuery('#loader').hide()"
          end
        end
      }
    end
    
  end
  
  def add_lawteam_member_form
    # Used for handling the case of creating law team member from matter task page.
    @from_matter_task = params[:from_matter_task]
    if params[:lawteam_member_id]
      @matter_people_client = @matter.matter_peoples.find(params[:lawteam_member_id])
    else
      @matter_people_client = @matter.matter_peoples.new(:type=>'client')
      @matter_people_client.start_date = Time.zone.now.to_date
    end
    filter_employees
    render :partial => "add_lawteam_member_form"
  end

  def add_lawteam_member
    params[:matter_people].merge!({:start_date => @matter.matter_date || @matter.created_at}) unless params[:matter_people][:effective_from].eql?("date_given")
    @matter_people_client = @matter.matter_peoples.new(params[:matter_people])
    respond_to do |format|
      format.js {
        render :update do |page|
          if params[:lawteam_member_id].blank?
            if @matter_people_client.save
              @matter_people_client.handle_additional_priv(params)
              if params[:matter_people][:end_date].present?
                access = @matter_people_client.matter_access_periods.first(:conditions => ["matter_id = ? AND start_date =? AND end_date = ? AND company_id = ? AND employee_user_id = ? AND is_active = ?", @matter.id, params[:matter_people][:start_date], params[:matter_people][:end_date], params[:matter_people][:company_id],  @matter_people_client.employee_user_id, @matter_people_client.is_active])
              else
                access = @matter_people_client.matter_access_periods.first(:conditions => ["matter_id = ?  and start_date =? and company_id=? and employee_user_id =? and is_active =?", @matter.id,params[:matter_people][:start_date], params[:matter_people][:company_id],  @matter_people_client.employee_user_id, @matter_people_client.is_active])
              end
              if access.blank?
                @matter_people_client.matter_access_periods.build(:matter_id => @matter.id,:start_date => params[:matter_people][:start_date],:end_date => params[:matter_people][:end_date], :company_id => params[:matter_people][:company_id], :employee_user_id => @matter_people_client.employee_user_id, :is_active => @matter_people_client.is_active).save!
              end
              unless params[:matter_date].blank?
                @all_dates = []
                params[:matter_date].each_value do |matter_date|
                  dates = matter_date.values_at("start_date","end_date")
                  @matter_people_client.matter_access_periods.build(:matter_id => @matter.id,:start_date => dates[0],:end_date => dates[1], :company_id => params[:matter_people][:company_id], :employee_user_id => @matter_people_client.employee_user_id, :is_active => @matter_people_client.is_active).save!
                end
              end                     
              page << "tb_remove();"
              if params[:from_matter_task]
                page << "jQuery('#activity_assignees_').empty();"
                mt=Matter.find(params[:matter_id])
                attnds = MatterPeople.get_name_and_email(mt)               
                attnds.collect do |j|
                  page << "jQuery('#activity_assignees_').append('<option value=#{j[1]}>#{j[0]}</option>');"
                end
                page << "jQuery('#matter_task_assigned_to_matter_people_id').empty();"                
                page << "jQuery('#matter_task_assigned_to_matter_people_id').append('<option value="" selected="">----------Select----------</option>');"                                
                assignees = MatterPeople.current_lawteam_members(mt.id)
                assignees.each do |i|
                  page << "jQuery('#matter_task_assigned_to_matter_people_id').append('<option value=#{i.id}>#{i.get_name}</option>');"
                end
              else
                page << "window.location.reload()"
              end
            else              
              errors = "<ul>" + @matter_people_client.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
              page << "show_error_msg('matter_lawteam_errors','#{errors}','message_error_div');"
              page << "jQuery('#loader').hide();"
              page << "disableWithPleaseWait('add_lawteam_button', false, 'Save')"
            end
          else
            @matter_people_client = @matter.matter_peoples.find(params[:lawteam_member_id])
            if @matter_people_client.update_attributes(params[:matter_people])
              page << "tb_remove()"
              page << "window.location.reload()"
            else
              errors = "<ul>" + @matter_people_client.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
              page << "show_error_msg('matter_lawteam_errors','#{errors}','message_error_div');"
            end
          end
        end
      }
    end
  end

  def edit_lawteam_member_form
    @matter_people_client = @matter.matter_peoples.find(params[:id])
    @counter = 0
    @matter_access_periods = @matter_people_client.matter_access_periods
    render :partial => "add_lawteam_member_form"
  end

  def assign_additional_access
    @matter_people_client = @matter.matter_peoples.find(params[:id])    
    render :layout => false
  end

  def edit_lawteam_member
    @matter_people_client = @matter.matter_peoples.find(params[:id])
    if params[:matter_date].present?
      in_range_start, in_range_end = MatterAccessPeriod.dates_in_range(@matter,@matter_people_client,params[:matter_date])
    else
      in_range_start = [true]
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          if in_range_start.present?
            if @matter_people_client.update_attributes(params[:matter_people])
              if @matter_people_client.additional_priv.present? && params[:additional_privs].blank?
                @matter_people_client.update_attribute(:additional_priv,nil)
              end
              @matter_people_client.handle_additional_priv(params)
              if params[:matter_people][:start_date].present?
                if params[:matter_people][:end_date].present?
                  access = @matter_people_client.matter_access_periods.first(:conditions => ["matter_id = ?  and start_date =? and end_date =? and company_id=? and employee_user_id = ? and is_active = ?", @matter.id,params[:matter_people][:start_date],params[:matter_people][:end_date].to_date, params[:matter_people][:company_id],  @matter_people_client.employee_user_id, @matter_people_client.is_active])
                else
                  access = @matter_people_client.matter_access_periods.first(:conditions => ["matter_id = ?  and start_date =? and company_id=? and employee_user_id =? and is_active =?", @matter.id,@matter.matter_date, params[:matter_people][:company_id],  @matter_people_client.employee_user_id, @matter_people_client.is_active])
                end
                if access.blank?
                  @matter_people_client.matter_access_periods.build(:matter_id => @matter.id,:start_date => params[:matter_people][:start_date],:end_date => params[:matter_people][:end_date], :company_id => params[:matter_people][:company_id], :employee_user_id => @matter_people_client.employee_user_id, :is_active => @matter_people_client.is_active).save!
                end
              end
              if params[:matter_date].present?
                MatterAccessPeriod.destroy_all({:matter_people_id => @matter_people_client.id})
                in_range_start.each_with_index do |dates, index|
                  @matter_people_client.matter_access_periods.build(:matter_id => @matter.id,:start_date => dates,:end_date => in_range_end[index], :company_id => params[:matter_people][:company_id], :employee_user_id => @matter_people_client.employee_user_id, :is_active => @matter_people_client.is_active).save!
                end
                in_range_start.each_with_index do |start_date,index|
                  if (in_range_end[index].blank? && start_date <= Date.today || (start_date <= Date.today && (in_range_end[index]) >= Date.today && @matter_people_client.end_date.present?))
                    @matter_people_client.update_attributes(:start_date => start_date, :end_date => in_range_end[index].present? ? (in_range_end[index]) : "")
                  end
                end
              end
              page << "tb_remove()"
              page << "window.location.reload()"
            else
              errors = "<ul>" + @matter_people_client.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
              page << "show_error_msg('matter_lawteam_errors','#{errors}','message_error_div');"
              page << "disableWithPleaseWait('add_lawteam_button', false, 'Save')"
              page << "jQuery('#loader').hide()"
            end
          else
            errors = "<ul>" +  "<li>" + "Please select proper date range/s" + "</li>" + "</ul>"
            page << "show_error_msg('matter_lawteam_errors','#{errors}','message_error_div');"
            page << "disableWithPleaseWait('add_lawteam_button', false, 'Save');"
            page << "jQuery('#loader').hide()"
          end
        end
      }
    end
  end

  def add_client_contact_form
    @matter_people_client_contact = @matter.matter_peoples.new(:type=>'client')
    @matter_people_client_contact.start_date = Time.zone.now.to_date
    #to get the id of 'Clients' contact stage to be set as the default one selected for stage
    @client_stage_value = @company.contact_stages.find(:all, :conditions=>['"company_lookups"."alvalue"= ? or "company_lookups"."alvalue"= ?', "Client", "Clients"])
    filter_employees
    render :partial => "add_client_contact_form"
  end

  def add_client_contact
    params[:matter_people].merge!({:start_date => @matter.matter_start_date}) unless params[:matter_people][:effective_from].eql?("date_given")
    @matter_people_client_contact = @matter.matter_peoples.new(params[:matter_people])
    uniq_email = verify_matter_people_contact(@matter_people_client_contact, params) unless params[:matter_people][:can_access_matter].eql?("1") && params[:matter_people][:email].blank?
    if params[:create_method].eql?("create_new")
      contact = Contact.new
      if uniq_email and @matter_people_client_contact.set_contact(contact, params)
        if params[:matter_people][:can_access_matter]=="1" 
          @matter_people_client_contact.create_matter_client(params[:matter_people][:email],params[:matter_people][:can_access_matter],contact)
        end
        respond_to do |format|
          format.js {
            render :update do |page|
              page << "tb_remove()"
              page << "window.location.reload()"
            end
          }
        end
      else
        respond_to do |format|
          format.js {
            render :update do |page|
              if @same_contacts.present?
                page << "jQuery('#same_contact_errors').html('#{same_contacts_show}')"
                page << "jQuery('#same_contact_errors').show();"
                page << "jQuery('#add_client_contact_button').val('Save');"
                page << "jQuery('#loader').hide();"
              else
                reqex=/^(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6}$/
                email_check=reqex.match(params[:matter_people][:email]) if (params[:matter_people][:email].present?)
                if (params[:matter_people][:can_access_matter]=="1" && (params[:matter_people][:email].blank? || params[:matter_people][:name].blank? || (params[:matter_people][:email].present? && email_check.nil?)))
                  error=[]
                  error << 'Please Specify First Name' if(params[:matter_people][:name].blank?)
                  error << 'Please Specify Email' if (params[:matter_people][:email].blank?)
                  error << 'Please Specify A Valid Email Address' if (params[:matter_people][:email].present? && email_check.nil?)
                  errors = "<ul>" + error.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
                else
                  errors = "<ul>" + contact.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
                end
                page << "show_error_msg('matter_client_contact_errors','#{errors}','message_error_div');"
                page << "disableWithPleaseWait('add_client_contact_button', false, 'Save')"
                page << "disableWithPleaseWait('add_client_contact_button2', false, 'Save')"
                page << "jQuery('#loader').hide();"
              end
            end

          }
        end
      end
    else
      respond_to do |format|
        format.js {
          render :update do |page|
            if @matter_people_client_contact.create_from_contact(params, page)              
            else
              page << "disableWithPleaseWait('add_client_contact_button', false, 'Save')"
              page << "disableWithPleaseWait('add_client_contact_button2', false, 'Save')"
            end
          end
        }
      end
    end
  end

  def edit_client_contact_form
    @matter_people_client_contact = @matter.matter_peoples.find(params[:id])
    render :partial => "edit_client_contact_form"
  end

  def edit_client_contact
    @matter_people_client_contact = @matter.matter_peoples.find(params[:id])
    uniq_email = verify_matter_people_contact(@matter_people_client_contact, params)
    respond_to do |format|
      format.js {
        render :update do |page|
          contact = Contact.find(@matter_people_client_contact.contact_id)
          if uniq_email and @matter_people_client_contact.update_attributes(params[:matter_people]) && @matter_people_client_contact.set_contact(contact, params)
            if params[:matter_people][:can_access_matter]=="1" && @matter_people_client_contact.email == params[:matter_people][:email] &&  !User.exists?(:username=> params[:matter_people][:email])
              @matter_people_client_contact.create_matter_client(params[:matter_people][:email],params[:matter_people][:can_access_matter],contact)
            end
            page << "tb_remove()"
            page << "window.location.reload()"
          else
            if @same_contacts.present?
              page << "jQuery('#same_contact_errors').html('#{same_contacts_show}')"
              page << "jQuery('#same_contact_errors').show();"
              page << "jQuery('#edit_client_contact_button').val('Save')"
              page << "jQuery('#loader').hide();"
            else
              errors = "<ul>" + @matter_people_client_contact.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
              page << "show_error_msg('matter_client_contact_errors','#{errors}','message_error_div');"
              page << "disableWithPleaseWait('edit_client_contact_button', false, 'Save')"
            end
          end
        end
      }
    end
  end

  def add_matter_people_form
    @matter_people = @matter.matter_peoples.new(:people_type=>params[:people_type])
    render :partial => "add_matter_people_form", :locals => {:people_type => params[:people_type]}
  end

  def add_matter_people
    if params[:matter_people][:phone].present? && params[:matter_people][:email].present?
      conditions =  "phone = '#{params[:matter_people][:phone]}' and email = '#{params[:matter_people][:email]}' "
    elsif params[:matter_people][:phone].present?
      conditions =  "phone = '#{params[:matter_people][:phone]}'"
    elsif params[:matter_people][:email].present?
      conditions =  "email = '#{params[:matter_people][:email]}'"
    end
    matter_people_contact = @matter.matter_peoples.first(:conditions => [conditions]) unless params[:contact][:id].present?
    already_matter_people = @matter.matter_peoples.first(:conditions => ["contact_id = ?", params[:contact][:id]]) if params[:contact][:id].present?
    contact = Contact.find(params[:contact][:id]) if params[:contact][:id].present?
    if already_matter_people.blank? && matter_people_contact.blank?
      unless params[:contact][:id].blank?
        params[:matter_people][:name] = contact.first_name
        params[:matter_people][:middle_name] = contact.middle_name
        params[:matter_people][:last_name] = contact.last_name
        params[:matter_people][:address] = contact.address
        params[:matter_people][:email] = contact.email
        params[:matter_people][:alternate_email] = contact.alt_email
        params[:matter_people][:fax] = contact.fax
        params[:matter_people][:phone] = contact.phone
        params[:matter_people][:mobile] = contact.mobile
        params[:matter_people][:contact_id] = params[:contact][:id]
      end
      @matter_people = @matter.matter_peoples.new(params[:matter_people])
      uniq_email = true
      uniq_email = verify_matter_people_contact(@matter_people, params) if params[:matter_people].present? && params[:matter_people][:contact_id].present?
      respond_to do |format|
        format.js {
          render :update do |page|
            if uniq_email and @matter_people.save_with_contact(params)
              close_and_reload(page)
            else
              if @same_contacts.present?
                page << "jQuery('#same_contact_errors').html('#{same_contacts_show}')"
                page << "jQuery('#same_contact_errors').show();"
                page << "jQuery('#add_matter_people_button').val('Save')"
                page << "jQuery('#loader').hide();"
              else
                if params[:check_exising] == "false"
                  errors = "<ul>" + @matter_people.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
                else
                  errors = "<ul>" + "<li>" + "Contat already added for this matter" + "</li>" + "</ul>"
                end
                page << "show_error_msg('matter_people_errors','#{errors}','message_error_div');"
                page << "jQuery('#loader').hide();"
                page << "disableWithPleaseWait('add_matter_people_button', false, 'Save');"
              end
            end
          end
        }
      end
    else
      respond_to do |format|
        format.js {
          render :update do |page|
            errors = "<ul>" + "<li>" + "Contact already added for this matter" + "</li>" + "</ul>"
            page << "show_error_msg('matter_people_errors','#{errors}','message_error_div');"
            page << "jQuery('#loader').hide();"
            page << "disableWithPleaseWait('add_matter_people_button', false, 'Save');"
          end
        }
      end      
    end
  end

  def edit_matter_people_form
    @matter_people = @matter.matter_peoples.find(params[:id])
    render :partial => "edit_matter_people_form"
  end

  def edit_matter_people
    @matter_people = @matter.matter_peoples.find(params[:id])
    uniq_email = true
    uniq_email = verify_matter_people_contact(@matter_people, params) if params[:matter_people] and params[:hidden_added_to_contact]=="true"
    respond_to do |format|
      format.js {
        render :update do |page|
          if uniq_email and @matter_people.update_with_contact(params)
            close_and_reload(page)
          else
            unless @same_contacts.blank?
              page << "jQuery('#same_contact_errors').html('#{same_contacts_show}')"
              page << "jQuery('#same_contact_errors').show();"
              page << "jQuery('#edit_matter_people_button').val('Save')"
              page << "jQuery('#loader').hide();"
            else
              errors = "<ul>" + @matter_people.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
              page << "show_error_msg('matter_people_errors','#{errors}','message_error_div');"
              page << "disableWithPleaseWait('edit_matter_people_button', false, 'Save');"
            end
          end
        end
      }
    end
  end

  def get_employee_users
    @employees = current_company.employees.all(:conditions => ["user_id IS NOT NULL"])
  end

  def index
    authorize!(:index,@user) unless @user.has_access?('People & Legal Team')
    filter_employees
    @all_employees_included_in_law_team = @employees.size == 0
    @matter_people_others = @matter.matter_peoples.others
    @matter_people_clients = @matter.matter_peoples.client
    @matter_people_opposite = @matter.matter_peoples.opposite if @matter.is_litigation
    @matter_people_client_representatives = @matter.matter_peoples.client_representative
    @matter_people_client_contacts = @matter.matter_peoples.client_contacts_and_matter_client
    @pagenumber=140
    add_breadcrumb t(:text_people_amp_legal_team), matter_matter_peoples_path(@matter)
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def new
    authorize!(:new,@user) unless @user.has_access?('People & Legal Team')
    @matter_people = @matter.matter_peoples.new
    @matter_people_other = @matter.matter_peoples.new(:type=>'other')
    @matter_people_client = @matter.matter_peoples.new(:type=>'client')
    @matter_people_client.start_date = Time.zone.now.to_date
    filter_employees
    @matter_people_opposite = @matter.matter_peoples.new(:type=>'opposite')
    @matter_people_client_representative = @matter.matter_peoples.new(:type=>'client_representative')
    @matter_people_client_contact = @matter.matter_peoples.new(:type=>'client_contact')
    respond_to do |format|
      format.html {render :layout => false}
      format.js # new.js.erb
      format.xml  { render :xml => @matter_people }
    end
  end

  def edit
    authorize!(:edit,@user) unless @user.has_access?('People & Legal Team')
    filter_employees
    add_self
    if params[:people_type] == 'others'
      @matter_people = @matter_people_other = @matter.matter_peoples.find(params[:id])
    elsif params[:people_type] == 'client'
      @matter_people = @matter_people_client = @matter.matter_peoples.find(params[:id])
    elsif params[:people_type] == 'opposites'
      @matter_people = @matter_people_opposite = @matter.matter_peoples.find(params[:id])
    elsif params[:people_type] == 'client_representative'
      @matter_people = @matter_people_client_representative = @matter.matter_peoples.find(params[:id])
    end
    respond_to do |format|
      format.js {render :layout => false}
      format.html {render :layout => false}
      format.xml  { render :xml => @matter_people }
    end
  end

  # POST /matter_peoples
  # POST /matter_peoples.xml
  def create
    authorize!(:create,@user) unless @user.has_access?('People & Legal Team')
    data = params
    matter_ppl_data = data[:matter_people]
    matter_ppl_data.merge!({
        :created_by_user_id => current_user.id,
        :company_id => get_company_id
      })
    @matter_people = @matter.matter_peoples.new(matter_ppl_data)
    @matter_people_client = @matter_people
    filter_employees
    @matter_people.is_active = true
    @matter_people_other = @matter_people
    @matter_people_opposite = @matter_people
    @matter_people_client_representative = @matter_people
    respond_to do |format|
      if @matter_people.save(matter_ppl_data)
        flash[:notice] = "#{t(:text_matter_people)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        format.html { redirect_to matter_matter_peoples_path(@matter) }
        format.xml  { head :ok }
      else
        format.html { redirect_to matter_matter_peoples_path(@matter) }
      end
    end
  end

  # PUT /matter_peoples/1
  # PUT /matter_peoples/1.xml
  def update
    authorize!(:update,@user) unless @user.has_access?('People & Legal Team')
    matter_ppl_data = params[:matter_people]
    matter_ppl_data.merge!({
        :updated_by_user_id => current_user.id
      })
    @matter_people = nil
    @matter_people = @matter.matter_peoples.find(params[:lawteam_member_id]) unless params[:lawteam_member_id].blank?
    @matter_people = @matter.matter_peoples.find(params[:id]) if @matter_people.nil?
    filter_employees
    add_self
    respond_to do |format|
      if @matter_people.update_attributes(matter_ppl_data)
        flash[:notice] = "#{t(:text_matter_people)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        format.html { redirect_to matter_matter_peoples_path(@matter) }
        format.js { redirect_to matter_matter_peoples_path(@matter) }
      else
        format.html {redirect_to matter_matter_peoples_path(@matter)}
      end
    end
  end

  # Filter and return only those employees who are not part of the law team.
  def filter_employees
    @matter_clients = @matter.matter_peoples.client
    @employees.each do |employee|
      if  @matter.employee_user_id== employee.user_id
        @employees = @employees - [employee]
      end
      @matter_clients.each do |matter_people|
        if  matter_people.employee_user_id == employee.user_id
          @employees = @employees - [employee]
        end
      end
    end
    return @employees
  end

  # After filter_employees called we need to add back the name of current
  # lead lawyer.
  def add_self
    if params[:id]
      @me= @matter.matter_peoples.find(params[:id])
      if @me.people_type == 'client' && @me.employee_user_id
        @employees = @employees + [Employee.first(:conditions => ["user_id = ?", @me.employee_user_id])]
      end
      return @employees
    end
  end

  # Update matter people access in matter using ajax request from checkbox.
  def access_update
    matter_people = @matter.matter_peoples.find(params[:id])
    if params[:grant_access].eql?("true")
      edate = nil
    else
      edate = Time.zone.now.to_date # - 1.day # Expire the matter people's role.
    end
    matter_people.update_attribute(:end_date, edate)
    render :text => "#{matter_people.start_date} - #{matter_people.end_date}"
  end


  def order_rows
    params[:order] += params[:dir]
    col = @matter.matter_peoples.all(:conditions => ["people_type=?",params[:people_type]] , :order => params[:order])
    @matter_peoples = col.collect do |obj|
      [obj.get_name,obj.get_email,obj.get_phone,obj.matter_team_role_id == 0? "Lead Lawyer" : current_company.client_roles.find_by_id(obj.matter_team_role_id).lvalue,obj]
    end
    if params[:dir] == " asc"
      @icon = "sort_asc.png"
      params[:dir] = " desc"
    else
      @icon = "sort_desc.png"
      params[:dir] = " asc"
    end
    render :file => "matter_peoples/order_rows.js.erb"
  end

  def sort_rows
    col = @matter.matter_peoples.all(:conditions => ["people_type=?",params[:people_type]])
    @matter_peoples = col.collect do |obj|
      [obj.get_name,obj.get_email,obj.get_phone,obj.matter_team_role_id == 0? "Lead Lawyer" : CompanyLookup.find_by_id(obj.matter_team_role_id).lvalue,obj]
    end
    index = get_sorting_index
    @matter_peoples.sort! do|a,b|
      if params[:dir] == " asc"
        a[index] <=> b[index]
      else
        b[index] <=> a[index]
      end
    end
    if params[:dir] == " asc"
      @icon = "sort_asc.png"
      params[:dir] = " desc"
    else
      @icon = "sort_desc.png"
      params[:dir] = " asc"
    end
    render :file => "matter_peoples/order_rows.js.erb"
  end

  def get_sorting_index
    case params[:sort_by]
    when "name"
      0
    when "role"
      3
    end
  end

  def attendees_autocomplete_new
    email = "#{params[:q]}"
    company_id = "#{params[:company_id]}"
    matter_id = "#{params[:matter_id]}"
    comp = Company.find(company_id)
    if email.strip == ''
      @atnds_emails = []
      if matter_id.present?
        mat = Matter.find(matter_id)
        MatterPeople.all(:select => :email, :conditions => ["company_id = ? AND matter_id = ? AND contact_id IS NULL AND email IS NOT NULL and email != ''", company_id, matter_id]).collect {|e| @atnds_emails << e.email}          
        mat.contact.matter_peoples.all(:select => :email, :conditions => ["company_id = ? AND email IS NOT NULL and email != ''", company_id]).collect {|e| @atnds_emails << e.email}
      else
        MatterPeople.all(:select => :email, :conditions => ["company_id = ? AND contact_id IS NULL AND email IS NOT NULL AND email != ''", company_id]).collect {|e| @atnds_emails << e.email}
        @company.contacts.all(:select => :email).collect {|e| @atnds_emails << e.email}
      end      
      render :text => @atnds_emails.join("\n")
    else
      email = "%#{email}%"
      @atnds_emails = []      
      if matter_id.present?
        mat = Matter.find(matter_id)
        MatterPeople.all(:select => :email, :conditions => ["email like ? AND company_id = ? AND matter_id = ? AND contact_id IS NULL AND email IS NOT NULL AND email!=''", email, company_id, matter_id]).collect {|e| @atnds_emails << e.email}
        mat.contact.matter_peoples.all(:select => :email, :conditions => ["email like ? AND company_id = ? AND email IS NOT NULL and email != ''", email,company_id]).collect {|e| @atnds_emails << e.email}
        mat.contact.matter_peoples.all(:select => :email, :conditions => ["email like ? AND company_id = ? AND email IS NOT NULL and email != ''", email, company_id]).collect {|e| @atnds_emails << e.email}
      else        
        MatterPeople.find(:all, :select => :email, :conditions => ["email like ? and company_id=? and contact_id IS NULL AND email IS NOT NULL AND email != ''", email, company_id]).collect {|e| @atnds_emails << e.email}
        contact_email = comp.contacts.search email, :star => true, :limit => 10000
        contact_email.collect{|e| @atnds_emails << e.email unless e.blank?}
      end      
      render :text => @atnds_emails.join("\n")
    end
  end

  def verify_matter_people_contact(matter_people, params)
    if matter_people.contact_id
      contact = Contact.find( matter_people.contact_id)
    else
      contact = Contact.new
    end
    contact = matter_people.set_contact(contact, params, true)
    unique_email(contact, params)
  end
  
end
