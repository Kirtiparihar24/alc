class AccessCodesController < ApplicationController
  
  def new
    @user=User.find(current_user.id)
    render :layout => false
  end

  def create
    begin
      result=current_user.generate_and_mail_new_tpin(params[:user][:email])
      render :update do |page|
        if result['flash'] == 'forgotten_notice'
          page.replace_html 'password_errors',result['message']
          page.show "error_upper_div"
          page.hide "loader_spinner"
        else
          flash[:notice] = result['message']
          page.redirect_to :back
        end
      end
    rescue Exception=>ex
      puts ex.message();
    end
  end

  def edit
    @user=User.new
    @user.reset_tpin_token = params[:reset_tpin_token]
    render :layout => false
  end

  def update
    @user = User.find_by_reset_tpin_token(params[:user][:reset_tpin_token], :include => [:employee])
    if @user.nil?
      flash[:error] = "Invalid Access Token"
      redirect_to new_session_path("user")
    elsif params[:tpin].length != 4 or params[:confirm_tpin].length != 4 or params[:tpin].match(/[0-9]{4}/).nil? or params[:confirm_tpin].match(/[0-9]{4}/).nil?
      flash[:error] = "Please enter 4 digit TPIN and Confirm TPIN."
      render :action=> :edit,:layout => false
    elsif params[:tpin] != params[:confirm_tpin]
      flash[:error] = "TPIN and Confirm TPIN don't match."
      render :action=> :edit,:layout => false
    else
      @user.reset_tpin_token = nil
      employee = @user.employee
      employee.access_code = params[:tpin]
      if employee.save false and @user.save
        flash[:notice] = "TPIN changed successfully."
        redirect_to new_session_path("user")
      else
        flash[:error] = "There was some error while changing TPIN. Please try again."
        render :action=> :edit,:layout => false
      end
    end
  end

  def reset_tpin_form
    unless current_user.role?(:livia_admin) || current_user.role?(:lawfirm_admin)
      redirect_to :back
      return
    end
    @user = User.find(params[:id])
    render :layout=>false
  end

  def reset_tpin
    unless current_user.role?(:livia_admin) || current_user.role?(:lawfirm_admin)
      render :text => "#{t(:text_operation)} #{t(:text_not)} #{t(:text_permitted)}."
      return
    end

    @user = User.find(params[:id], :include => [:employee])
    if params[:user][:tpin].length != 4 or params[:user][:confirm_tpin].length != 4 or params[:user][:tpin].match(/[0-9]{4}/).nil? or params[:user][:confirm_tpin].match(/[0-9]{4}/).nil?
      render :text => "Please enter 4 digit TPIN and Confirm TPIN."
    elsif params[:user][:tpin] != params[:user][:confirm_tpin]
      render :text => "TPIN and Confirm TPIN don't match."
    else
      employee = @user.employee
      employee.access_code = params[:user][:tpin]
      if employee.save(false)
        render :text => "TPIN updated successfully!"
      else
        render :text => "There was some error while changing TPIN. Please try again."
      end
    end
  end

end
