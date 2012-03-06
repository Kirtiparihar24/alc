class UsersController < ApplicationController

  before_filter :authenticate_user!, :only => [ :show ]
  before_filter :assign_user, :except => [ :new, :create, :show ]
  after_filter :load_sticky_notes ,:only => [:set_user_time_zone]
  skip_before_filter :check_if_changed_password, :only => :change_password
  
  layout "admin"
  # GET /users
  # GET /users.xml                              HTML (not directly exposed yet)
  #----------------------------------------------------------------------------

  def check_exisitng
    users = User.all(:conditions => ["username = ?", params[:username]])
    render :text => (users.size > 0).to_json
  end

  # GET /users/1
  # GET /users/1.xml                                                       HTML
  #----------------------------------------------------------------------------
  def show
    if is_secretary_or_team_manager?
      redirect_to "/physical/liviaservices/livia_secretaries"
      return
    elsif current_user.end_user
      redirect_to physical_clientservices_home_index_path
      return
    end
    @user = params[:id] ? User.find(params[:id]) : @current_user
    respond_to do |format|
      format.html # show.html.haml
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/new
  # GET /users/new.xml                                                     HTML
  #----------------------------------------------------------------------------
  def new
    @user = User.new
    respond_to do |format|
      format.html # new.html.haml <-- signup form
      format.xml  { render :xml => @user }
    end
  end
  
  # GET /users/1/edit                                                      AJAX
  #----------------------------------------------------------------------------
  def edit
    # <-- render edit.js.rjs
  end
  
  # POST /users
  # POST /users.xml                                                        AJAX
  #----------------------------------------------------------------------------
  def create
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = "#{t(:text_successful)} ""#{t(:text_signup)} " " #{t(:text_welcome_to_livia)}"
      redirect_back_or_default profile_url
    else
      render :action => :new
    end
  end
  
  # PUT /users/1
  # PUT /users/1.xml                                                       AJAX
  #----------------------------------------------------------------------------
  def update
    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.js
        format.xml { head :ok }
      else
        format.js
        format.xml { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end





  # PUT /users/1/change_password
  # PUT /users/1/change_password.xml                                       AJAX
  #----------------------------------------------------------------------------
  def change_password
    if request.get?
      if params[:first_login]
        session[:first_login] = true
      end
      render :layout => false
    elsif request.put?
      msg=''
      if @user.valid_password?(params[:user][:current_password])
        if params[:user][:password].present?
          if validate_password(params[:user][:password], params[:user][:password_confirmation])
            #--updating sign in count for first logged in user--kalpit patel -06/05/2011
            if params[:first_login]=='true'
              @user.sign_in_count = 2
              @user.update_attributes(params[:user])
            else
              @user.update_attributes(params[:user])
            end
            flash[:notice] = "#{t(:text_your)} #{t(:text_password)} #{t(:text_has_been)} #{t(:text_changed)}. #{t(:text_please)} #{t(:text_login_again)}"
          else
            msg = @err_msg
          end
        else
          msg="#{t(:text_please)} #{t(:text_specify)} #{t(:text_valid)} #{t(:text_new)} #{t(:text_password)}" #@user.errors.full_messages.join("<br />") #"Your password hasn't been changed."
        end
      else
        @user.errors.add(:current_password, "^ #{t(:text_please)} #{t(:text_specify)} #{t(:text_valid)} #{t(:text_current)} #{t(:text_password)}")
        msg= "#{t(:text_please)} #{t(:text_specify)} #{t(:text_valid)} #{t(:text_current)} #{t(:text_password)}"
      end
      if msg.present?
        respond_to do |format|
          format.js{
            render :update do |page|
              page.replace_html 'password_errors',msg
              page.show "error_upper_div"
              page<<" jQuery('#error_upper_div')
                .fadeIn('slow')
                .animate({
                    opacity: 1.0
                }, 8000)
                .fadeOut('slow', function() {
                    jQuery('#error_upper_div').hide();
                });"
              unless params[:height]
                page.hide "loader_spinner"
              end
            end
          }
        end
      else
        respond_to do |format|
          format.js{
            render :update do |page|
              if params[:height]
                page.call("tb_remove")
              end
              page.redirect_to destroy_user_session_path(:msg=>"changed_and_signedout")
            end
          }
        end
      end
    end
  end


  # PUT /users/1/change_password
  # PUT /users/1/change_password.xml                                       AJAX
  #----------------------------------------------------------------------------
  def change_password_old
    if request.get?
      render :layout => false
    elsif request.put?
      if @user.valid_password?(params[:current_password], true)
        params[:user][:change_password]=nil
        unless params[:user][:password].blank?
          if @user.update_attributes(params[:user])
            if session[:service_session]
              @svc_sesion = current_service_session
              if @svc_sesion
                @svc_sesion.session_end = Time.zone.now
                @svc_sesion.save!
              end
              session[:service_session] = nil
            end
            # end the service provider session

            if session[:sp_session]
              @sp_sesion = current_service_provider_session
              if @sp_sesion
                @sp_sesion.session_end = Time.zone.now
                @sp_sesion.save!
              end
              session[:sp_session] = nil
            end

            if session[:eu_session]
              @eu_sesion = current_employee_session
              if @eu_sesion
                @eu_sesion.session_end = Time.zone.now
                @eu_sesion.save!
              end
              session[:eu_session] = nil
            end
            current_user.session_key = nil
            current_user.save!
            current_user_session.destroy
            flash[:notice] = "#{t(:text_your)} #{t(:text_password)} #{t(:text_has_been)} #{t(:text_changed)}. #{t(:text_please)} #{t(:text_login_again)}"
            #redirect_to login_url
            render :text => ""
            return
          else
            render :text=> @user.errors.full_messages.join("<br />") #t(:flash_user_confirm_password_unmatched)
            return
          end
        else
          render :text => "#{t(:text_please)} #{t(:text_specify)} #{t(:text_valid)} #{t(:text_new)} #{t(:text_password)}" #@user.errors.full_messages.join("<br />") #"Your password hasn't been changed."
          return
        end
      else
        @user.errors.add(:current_password, "^ #{t(:text_please)} #{t(:text_specify)} #{t(:text_valid)} #{t(:text_current)} #{t(:text_password)}")
        #render :action=> 'password'
        render :text => "#{t(:text_please)} #{t(:text_specify)} #{t(:text_valid)} #{t(:text_current)} #{t(:text_password)}"
        return
      end
    end
  end

  def reset_password_form
    unless current_user.role?(:livia_admin) || current_user.role?(:lawfirm_admin)
      redirect_to :back
      return
    end
    @user = User.find(params[:id])
    render :layout=>false
  end

  def reset_password
    unless current_user.role?(:livia_admin) || current_user.role?(:lawfirm_admin)
      render :text => "#{t(:text_operation)} #{t(:text_not)} #{t(:text_permitted)}."
      return
    end
    @user = User.find(params[:id])
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    if validate_password(@user.password, @user.password_confirmation)
      if @user.save(false)
        #TODO: Feature 6326 User to get blocked after 5 attempts  comment the line while implementing this
        #@user.update_attribute(:sign_in_count,0)
        # devise lockable uncommented locking the users after 5 attempts.
        # But as per the requirement admin should also b able to change the password of the user to unlock the user login if required.
        # for which failed_attempts = 0, unlock_token and locked_at = nil undated. Supriya Surve :: 8:26 am :: 02/05/2011
        #TODO: Feature 6326 User to get blocked after 5 attempts  uncomment the line while implementing this
        User.update_all({:sign_in_count=>0,:failed_attempts => 0, :unlock_token => nil, :locked_at=>nil},{:id => @user.id})
        flash[:notice] = "#{t(:text_password)} #{t(:text_was)} #{t(:text_reset)} #{t(:text_successfully)}!"
        render :text => ""
      else
        render :text => "#{t(:text_password)} #{t(:text_reset)} #{t(:text_error)}"
      end
      return
    else
      render :text => @err_msg
    end
  end

  def set_user_time_zone
    @user = User.find(get_employee_user_id)
    if request.post?
      params[:user][:zimbra_time_zone] = $zimbra_tz[params[:user][:time_zone]]
      respond_to do |format|
        format.js{
          @user.update_attributes(params[:user])
          msg = "Time Zone #{t(:text_successfully)} saved."
          render :update do |page|
            #               page << "tb_remove();"
            if request.referrer.nil? || request.referrer.include?('timeandexpenses') || request.referrer.include?('rpt')
              current_user=@user
              zone = current_user.time_zone if current_user
              zone ||= 'UTC'
              Time.zone = zone
              page.replace_html "sticky_note",:partial=>'sticky_notes/note'#,:collection=>@sticky_note_user.sticky_notes
              page.call "stickyInit"
              page.call "stop_propogation"
              page << "jQuery('#add_note').click();"
              page << "show_error_msg('altnotice','#{msg}','message_sucess_div');"
            else
              flash[:notice] = msg
              page.redirect_to request.referrer
            end
          end
        }
      end
    else
      render :layout =>false
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
  
  def assign_user
    @user = current_user 
  end
end
