namespace :delete_duplicate_documents do
  task :from_clients_logins => :environment do
    document_homes = DocumentHome.all
    document_homes.each do |document_home|
      if (document_home.created_by_user_id == document_home.owner_user_id) && document_home.mapable_type == "Matter" && document_home.employee_user_id.nil?        
        document_home.update_attributes({:owner_user_id => nil, :access_rights => 2})
        document_home.destroy!        
      end
    end
  end
end