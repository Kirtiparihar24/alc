class PasswordsController < ApplicationController
  prepend_before_filter :require_no_authentication
  include Devise::Controllers::InternalHelpers

  # GET /resource/password/new
  def new
    build_resource
    render_with_scope :new
  end

  # POST /resource/password
  def create
    result=User.generate_and_mail_new_password(params[resource_name][:username],params[resource_name][:email])
    if result['flash'] == 'forgotten_notice'
      flash.now[:error] = result['message']
      render_with_scope :new
    else
      set_flash_message :notice, :send_instructions
      redirect_to new_session_path(resource_name)
    end
  end

  def create_old
    self.resource = resource_class.send_reset_password_instructions(params[resource_name])
    if resource.errors.empty?
      set_flash_message :notice, :send_instructions
      redirect_to new_session_path(resource_name)
    else
      render_with_scope :new
    end
  end
  

  # GET /resource/password/edit?reset_password_token=abcdef
  def edit
    self.resource = resource_class.new
    pass = self.resource.class.find_by_reset_password_token(params[:reset_password_token])
    if pass
      resource.reset_password_token = params[:reset_password_token]
      render_with_scope :edit
    else
      set_flash_message :error, 'Forgot password token has been expired'
      redirect_to new_session_path(resource_name)
    end
  end

  # PUT /resource/password
  def update
    if validate_password(params[:user][:password], params[:user][:password_confirmation])
      self.resource = resource_class.reset_password_by_token(params[resource_name])
      if resource.errors.empty?
        resource.update_attribute(:reset_password_token,nil)
        flash[:notice] = t(:changed_and_signedout)
        redirect_to new_session_path(resource_name)
      else
        flash[:error] = resource.errors.full_messages.to_sentence
        render_with_scope :edit
      end
    else
      flash[:error] = @err_msg
      render_with_scope :edit
    end
  end

  private

  def validate_password(pass1, pass2)
    @err_msg = ''
    if pass1.blank? or pass2.blank?
      @err_msg = "#{t(:text_password)} #{t(:flash_cannot_blank)}!"
      return false
    end
    reg = /^(?=.*\d)(?=.*([a-z]))(?=.*([A-Z]))(?=.*([\x21-\x2F]|[\x3A-\x40]|[\x5B-\x60]|[\x7B-\x7E]))([\x20-\x7E]){8,40}$/
    unless reg.match(pass1)
      @err_msg = t(:flash_password)
      return false
    end
    unless pass1.eql?(pass2)
      @err_msg = "#{t(:text_passwords)} #{t(:text_dont_match)}!"
      return false
    end
    return true
  end
  
end
