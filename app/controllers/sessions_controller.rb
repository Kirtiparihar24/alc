class SessionsController < ApplicationController
  require 'devise/hooks/timeoutable'
  prepend_before_filter :require_no_authentication, :only => [ :new, :create ]
  skip_before_filter :check_if_changed_password # added by kalpit patel 09/05/11
  include Devise::Controllers::InternalHelpers
  include Devise::Models::Timeoutable
  # GET /resource/sign_in
  def new
    unless flash[:notice].present?
      Devise::FLASH_MESSAGES.each do |message|
        set_now_flash_message :alert, message if params.try(:[], message) == "true"
      end
    end
    build_resource
    render_with_scope :new
  end

  def login_from_telephony
    resource = User.first(:conditions => ["username = ? AND encrypted_password = ?", params[:user][:username], params[:user][:encrypted_password]])
    if resource
      reset_session
      role_name=resource.role.try(:name)
      sign_in(User,resource,role_name)
      User.current_user = current_user
      redirect_to after_sign_in_path_for(role_name)
    else
      set_now_flash_message :error, (warden.message || :invalid)
      clean_up_passwords(build_resource)
      render_with_scope :new
    end
  end

  # POST /resource/sign_in
  def create
    if resource = authenticate(resource_name)
      reset_session
      if is_domain_name_liviaservices
        last_session = ActiveRecord::SessionStore::Session.find_by_user_id(resource.id, :order => "id DESC")
        if last_session.present?
          if resource.timedout?(last_session.updated_at)
            resource.update_attribute(:is_signedin,false)
          end
        end
        allow_concurrent_login = !resource.is_signedin || params[:session_kill].to_i == 1
        if params[:session_kill].to_i == 1
          signed_out_other_scope(resource)
        end
      else
        allow_concurrent_login = true
      end
      if allow_concurrent_login
        @flag = false
        # Following Code Update user timezone acording to is Zone :BY-Pratik Jadhav
        utc = params[:user][:UTC_Time]
        unless resource.time_zone == ActiveSupport::TimeZone[-(utc.to_i.minutes)].to_s.split(') ')[1].strip
          time_zone = ActiveSupport::TimeZone[-(utc.to_i.minutes)].to_s.split(') ')[1].strip
          resource.time_zone = time_zone
          resource.zimbra_time_zone = $zimbra_tz[time_zone]
          resource.save false
          Time.zone = resource.time_zone
        end
        if $zimbra_tz[resource.time_zone] != resource.zimbra_time_zone
          resource.zimbra_time_zone = $zimbra_tz[resource.time_zone]
          resource.save(false)
        end
        role_name = resource.role.try(:name)
        sign_in(resource_name,resource,role_name)
        # this code make change password manditory for firstime login --kalpit patel 06/05/2011
        if resource.sign_in_count<=2
          resource.sign_in_count=0
          current_user.update_attribute(:sign_in_count,'0') #resets sign_in_count to zero
          redirect_to root_url
        else
          redirect_to after_sign_in_path_for(role_name)
        end
      else
        @flag = true
        set_flash_message :warning, t(:flash_authentications_already_loggedin)
        render_with_scope :new
      end
    elsif [:custom, :redirect].include?(warden.result)
      throw :warden, :scope => resource_name
    else
      user = User.find_by_username(params[:user][:username])
      if user.present? && user.failed_attempts >= 5
        msg = "#{t(:blocked_due_to_multiple_unsuccessful_attempts_part1)} #{user.email} #{t(:blocked_due_to_multiple_unsuccessful_attempts_part2)}"
      elsif user.present? && user.failed_attempts >= 3
        msg = t(:forgot_password_msg)
      else
        msg = warden.message || :invalid
      end
      set_now_flash_message :error, msg
      clean_up_passwords(build_resource)
      render_with_scope :new
    end
  end

  #Override the default sign_in method of devise
  def sign_in(resource_or_scope, resource, role_name)
    scope = Devise::Mapping.find_scope!(resource_or_scope)
    last_login = resource.last_sign_in_at.strftime("%A, %B %d %Y at %I:%M %p.") unless resource.last_sign_in_at.nil?
    warden.set_user(resource, :scope => scope)   
    current_user.update_attribute(:is_signedin, true)
    #create_sessions(role_name,resource)
    set_flash_message :notice,"Signed in successfully. Your last login was on #{last_login}"
  end

  # remove the session of user from other sides
  def signed_out_other_scope(resource)
    ActiveRecord::SessionStore::Session.all(:conditions => ['user_id = ?', resource.id]).compact.each do |s|
      begin
        s.destroy
      rescue
        next
      end
    end
  end

  def get_helpdesk_user_id
    res = ActiveRecord::Base.connection.execute("SELECT helpdesk_user_id FROM single_signon.user_apps WHERE product_user_id=#{current_user.id} and product_id=(select id from helpdesk.products where key='#{APP_URLS[:livia_portal_key]}' limit 1)")
    res.getvalue(0,0)
  end

  def signed_out_other_helpdesk_scope
    user_id = get_helpdesk_user_id
    ActiveRecord::Base.establish_connection(:helpdesk)
    #resource = User.find(user_id.to_i)
    ActiveRecord::SessionStore::Session.all.compact.each do |s|
      begin
        unless s.data['warden.user.user.key'].nil?
          if s.data['warden.user.user.key'][1] == user_id.to_i
            s.destroy
          end
        end
      rescue
        next
      end
    end
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.establish_connection(RAILS_ENV)
  end

  def set_sesssion_time_zone
    if params[:tz]
      Time.zone = params[:tz]
      session[:tz] = params[:tz]
    end
    if is_secretary_or_team_manager?
      redirect_to physical_liviaservices_livia_secretaries_url
    else
      redirect_to physical_clientservices_home_index_path
    end
  end
 
  def destroy
    if APP_URLS[:use_helpdesk] && session[:helpdesk]
      logout_from_helpdesk(ENV["HOST_NAME"] + '/logout')
    else
      current_user.update_attributes({:is_signedin=> false,:timer_start_time=>nil,:timer_state=>nil,:base_seconds=>nil}) if current_user
      destroy_current_user_session
      reset_session
      respond_to do |format|
        format.html {
          if params[:session_time_out]
            set_flash_message :notice, :timeout
          elsif params[:msg]
            set_flash_message :notice, :changed_and_signedout
          else
            set_flash_message :notice, :signed_out
          end
          sign_out(resource_name)
          redirect_to new_user_session_url #root_url
        }
      end
    end
  end
  
  def check_session_validity
  end

  protected

  def clean_up_passwords(object)
    object.clean_up_passwords if object.respond_to?(:clean_up_passwords)
  end

end
