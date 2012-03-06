class UploadLogosController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_company
  skip_before_filter :check_if_changed_password

  layout 'admin'

  def index
  end

  def update
    @company = Company.find(params[:company_id])
    if @company.update_attributes(:logo => params[:logo], :updated_by_user_id => current_user.id, :logo_for_invoice => params[:logo_for_invoice])
      flash[:notice] =  "Logo successfully uploaded for #{@company.name}"
    else
      flash[:error] =  generate_error_messages_helper(@company)
    end
    redirect_to :action => "index"
  end

  def delete
    @company = Company.find(params[:id])
    @company.logo = nil
    if @company.save
        flash[:notice] = "Logo  was successfully deleted"
    else
       flash[:error] = "Logo was unable to delete"
    end
    respond_to do |format|
      format.html { redirect_to(upload_logos_path) }
      format.xml  { head :ok }
    end
  end
  private

  def load_company
    authorize!(:logo_upload,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    !params[:company_id].blank?? session[:company_id] = params[:company_id] : params[:company_id] = session[:company_id]
    if current_user.role?:lawfirm_admin
      params[:company_id] = current_user.company_id
    else
      @companies ||= Company.company(current_user.company_id)
    end
    @company ||= Company.find(params[:company_id]) unless params[:company_id].nil?
  end

end
