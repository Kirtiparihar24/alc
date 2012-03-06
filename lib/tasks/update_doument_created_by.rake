namespace :document_homes_n_document do

  task :update_docs_created_by_user_id  => :environment do

    document_homes=DocumentHome.find(:all,:conditions=>["mapable_type = 'Company'"])
    document_homes.each do |doc_home|
      unless doc_home.created_by_user_id == doc_home.employee_user_id
        documents = doc_home.documents

        if doc_home.parent_id.present?
          new_document= DocumentHome.find_by_id(doc_home.parent_id)
          doc_home.update_attributes(:created_by_user_id => new_document.employee_user_id,:employee_user_id =>new_document.employee_user_id)
        else
          doc_home.update_attributes(:created_by_user_id => doc_home.employee_user_id)
        end

        documents.each do |doc|
          doc.update_attributes(:created_by_user_id=> doc.employee_user_id)
        end
      end
    end
  end
end