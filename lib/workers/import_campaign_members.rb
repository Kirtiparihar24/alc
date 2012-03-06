class ImportCampaignMembers
  @queue = :import_campaign_members
  def self.perform(file_format = nil,path_to_file = nil, company=nil,current_user=nil,employee_user=nil,campaign_id = nil)
    if file_format=='CSV'
      ImportData::campaign_member_csv_file(path_to_file,company,current_user,employee_user,campaign_id)
    else
      ImportData::campaign_member_excel_file(path_to_file,company,current_user,employee_user,campaign_id)
    end
  end
end
