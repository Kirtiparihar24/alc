#require 'ruby-debug'
class ImportDataController < ApplicationController
  require 'csv'
  include ImportData

  # added by sheetal on 3 June
  def imports_files
    @pagenumber=27
  end
  #Import Contact from Background Process Surekha 19 May
  def import_from_file
    path_to_file = ImportData::save_data_file(params[:import_file], current_company.id)
    if params[:import].eql?('time')
      Resque.enqueue(ImportTimeEntry, path_to_file, current_user.id, current_company.id, get_employee_user.id)
      flash[:notice] = "The time entries are being uploaded in the background. You can continue to use the LIVIA Portal. This will not impact the upload process. A detailed report will be mailed to  your registered email id once the process is completed."
      redirect_to(utilities_path(:radio=> "time"))
    elsif params[:import].eql?('expense')
      Resque.enqueue(ImportExpenseEntry, path_to_file, current_user.id, current_company.id, get_employee_user.id)
      flash[:notice] = "The expense entries are being uploaded in the background. You can continue to use the LIVIA Portal. This will not impact the upload process. A detailed report will be mailed to  your registered email id once the process is completed."
      redirect_to(utilities_path(:radio=> "expense"))
    elsif params[:import].eql?('matters')
      Resque.enqueue(ImportMatter, path_to_file, current_company.id, current_user.id, get_employee_user.id,params[:file_format])
      flash[:notice] = "The matters are being uploaded in the background. You can continue to use the LIVIA Portal. This will not impact the upload process. A detailed report will be mailed to  your registered email id once the process is completed."
      redirect_to(utilities_path(:radio=> "matters"))
    else
      #Resque.enqueue(ImportContact,params[:file_format], path_to_file, current_company.id, current_user.id, get_employee_user.id)
      ImportContact.perform(params[:file_format], path_to_file, current_company.id, current_user.id, get_employee_user.id)
      flash[:notice] = "The contacts are being uploaded in the background. You can continue to use the LIVIA Portal. This will not impact the upload process. A detailed report will be mailed to  your registered email id once the process is completed."
      redirect_to params[:import].eql?('util_contacts') ?  utilities_path : contacts_path
    end
  end

  def import_campaign_members
    path_to_file = ImportData::save_data_file(params[:import_file], current_company.id)
    Resque.enqueue(ImportCampaignMembers,params["file_format"],path_to_file,current_company.id,current_user.id,get_employee_user.id,params["campaign_id"])
    respond_to do |format|
      format.html {
        flash[:notice] = "The campaign members are being uploaded in the background. You can continue to use the LIVIA Portal. This will not impact the upload process. A detailed report will be mailed to  your registered email id once the process is completed."
        responds_to_parent do
          render :update do |page|
            page << "window.location.reload();"
          end
        end
      }
    end
  end

  def download_format_for_contact
    send_file RAILS_ROOT+'/public/sample_import_files/contacts_import_file.csv', :type => "application/csv"
  end

  def show
    import_entity = params[:id]
    file_format = params[:f].upcase
    if(import_entity.eql?('contacts') && file_format.eql?('CSV'))
      send_file RAILS_ROOT+'/public/sample_import_files/contacts_import_file.csv', :type => "application/csv"
    elsif(import_entity.eql?('contacts') && file_format.eql?('XLS'))
      send_file RAILS_ROOT+'/public/sample_import_files/contacts_import_file.xls', :type => "application/xls"
    elsif(import_entity.eql?('time') && file_format.eql?('CSV'))
      send_file RAILS_ROOT+'/public/sample_import_files/time_entries_import_file.csv', :type => "application/csv"
    elsif(import_entity.eql?('time') && file_format.eql?('XLS'))
      send_file RAILS_ROOT+'/public/sample_import_files/time_entries_import_file.xls', :type => "application/xls"
    elsif(import_entity.eql?('expense') && file_format.eql?('CSV'))
      send_file RAILS_ROOT+'/public/sample_import_files/expense_entries_import_file.csv', :type => "application/csv"
    elsif(import_entity.eql?('expense') && file_format.eql?('XLS'))
      send_file RAILS_ROOT+'/public/sample_import_files/expense_entries_import_file.xls', :type => "application/xls"
    elsif(import_entity.eql?('matters') && file_format.eql?('CSV'))
      send_file RAILS_ROOT+'/public/sample_import_files/matters_import_file.csv', :type => "application/csv"
    elsif(import_entity.eql?('matters') && file_format.eql?('XLS'))
      send_file RAILS_ROOT+'/public/sample_import_files/matters_import_file.xls', :type => "application/xls"
    end
  end
  
end
