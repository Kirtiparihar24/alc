  namespace :update_employee_user_id_document_home do
    task :set_employee_user_id_to_create_user_bu_id => :environment do
      document = DocumentHome.find(:all,:conditions =>["employee_user_id IS ?",nil])
      document.each do |doc|
        doc.employee_user_id=doc.created_by_user_id
        doc.save
      end
    end
  end