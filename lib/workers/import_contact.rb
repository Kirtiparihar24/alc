class ImportContact
  @queue = :import_contact

  def self.perform(file_format = nil,path_to_file = nil, company=nil,current_user=nil,employee_user=nil)
    # Below define variable are used to mantain invalid contacts in array,invalid contacts count in invalid_length,
    # valid contacts count in valid_length
    #@invalid_contacts=[]
    #@invalid_length=0
    #@valid_length=0
    #@company = company
    #@topic = params[:optional]? params[:optional] : nil

    if file_format=='CSV'
      ImportData::contact_process_file(path_to_file,company,current_user,employee_user)
    else
      ImportData::contact_process_excel_file(path_to_file,company,current_user,employee_user)
    end
  end
end
