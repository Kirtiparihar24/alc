namespace :set_for_workspace do
  task :update_for_workspace_workspace_and_repositories  => :environment do
    user = User.find(:all)
    user.each {|usr|
      usr_folder = usr.document_homes.find(:all ,:select => "folder_id", :conditions=>["folder_id is not null"])
      folder_ids = usr_folder.collect{|folder| folder.folder_id}.uniq
      Folder.update_all("for_workspace=true",['for_workspace is null and id in (?)',folder_ids])
    }

    companies = Company.find(:all)
    companies.each {|company|
      company_folders = company.repository_documents.find(:all, :select =>"folder_id", :conditions=>["folder_id is not null"]) + company.links.find(:all, :conditions=> ['folder_id is not null'])
      folder_ids = company_folders.collect{|folder| folder.folder_id}.uniq
      Folder.update_all("for_workspace=false",['for_workspace is null and id in (?)',folder_ids])
    }
  end
end