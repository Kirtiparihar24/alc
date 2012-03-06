namespace :set_folders do
  task :mapable_type_mapable_id  => :environment do
    folders = Folder.find_with_deleted(:all)
    folders.each do |folder|
      if folder.for_workspace=="false" or folder.for_workspace==false
        folder.update_attributes(:mapable_type =>'Company' , :mapable_id => folder.company_id)
      elsif folder.for_workspace=="true" or folder.for_workspace==true
        if folder.employee_user_id.present?
          id = folder.employee_user_id
        else
          id = folder.created_by_user_id
        end
        folder.update_attributes(:mapable_type =>'User' , :mapable_id => id)
      end
    end
  end
end