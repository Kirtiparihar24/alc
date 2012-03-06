class CompanyReportsController < ApplicationController
  before_filter :authenticate_user!  
  layout "left_with_tabs"
  
  def fav_reports
    index
    if request.xhr? and params[:list_fav]
      render :file => 'company_reports/favorite_reports.js',:layout => false
    else
      render :layout => false
    end
  end
  
  def index
    @manage_favourites = "selected"    
    @col = CompanyReport.find_favorites(get_company_id,get_employee_user_id)
    @favourites = {}
    account = t(:label_Account)
    @col.group_by(&:report_type).each do|key,gcol|
      case key
      when 'Contact'
        @contacts_fav = gcol
      when account
        @accounts_fav = gcol
      when 'Opportunity'
        @opps_fav = gcol
      when 'Matter'
        @matters_fav = gcol
      when 'TimeAndExpense'
        @times_fav = gcol
      when 'Campaign'
        @campaigns_fav = gcol
      end
    end
  end

  def destroy
    CompanyReport.destroy(params[:id])
    redirect_to company_reports_path
  end

  def edit_report_name
    @favourite = CompanyReport.find_favorite(params[:id], get_company_id)
    render :layout => false
  end

  def update_report_name
    data=params
    @favourite = CompanyReport.find data[:id]
    if @favourite.update_attributes(:report_name => data[:report_favourite][:report_name],:updated_by_user_id =>current_user.id)
      render :update do|page|
        page.replace_html(params[:td_update],:partial => 'favourite_obj',:locals => {:obj => @favourite})
        page.replace_html('TB_ajaxContent',:partial => 'rpt_partials/favourite_success',:locals => {:created => false})
      end      
    else
      flash[:error]=t(:flash_report_favourite_error)
      redirect_to company_reports_path
    end
  end
  
end
