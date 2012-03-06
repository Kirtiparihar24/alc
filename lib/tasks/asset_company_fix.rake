#Author Mandeep
#Task to update the company id in assets table
namespace :asset_company_fix do
  task :company_fix => :environment do
    Asset.find(:all).each do |asset|
      comp = Document.find(asset.attachable_id).company_id
      asset.update_attribute(:company_id, comp)
    end      
  end

  task :workspace_fix => :environment do
    doc_homes= DocumentHome.find(:all,:conditions=>["mapable_type='Workspace'"])
    doc_homes.each do |doc_home|
      doc_home.update_attribute(:mapable_type, 'User')
      doc_home.documents.each do |doc|
        doc.update_attribute(:employee_user_id, doc_home.mapable_id)
      end
    end
  end

  task :repository_fix => :environment do
    doc_homes= DocumentHome.find_with_deleted(:all,:conditions=>["mapable_type='Repository'"])
    doc_homes.each do |doc_home|
      doc_home.update_attributes({:mapable_type=> 'Company'})
    end
  end
  
  task :remove_old_deleted_docs => :environment do
    doc_homes= DocumentHome.find_only_deleted(:all,:conditions=>["mapable_type in ('User','Company')"])
    doc_homes.each do |doc_home|
      doc_home.destroy!
    end
  end
  task :update_employee_in_doc_homes => :environment do
    DocumentHome.all.each do |doc_home|
      if doc_home.latest_doc.present?
        doc_home.update_attribute(:employee_user_id, doc_home.latest_doc.employee_user_id) unless doc_home.employee_user_id
      end
    end
  end


end

