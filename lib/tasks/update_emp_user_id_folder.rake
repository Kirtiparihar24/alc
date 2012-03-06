  namespace :update_employee_user_id_folder do
    task :set_employee_user_id_to_create_by_user_id => :environment do
      folders = Folder.find_with_deleted(:all,:conditions =>["employee_user_id IS ?",nil])
      folders.each do |folder|
        folder.employee_user_id=folder.created_by_user_id
        folder.save
      end
    end
  end