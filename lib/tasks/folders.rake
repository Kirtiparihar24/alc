namespace :folders do
  task :set_all_to_workspace => :environment do
    doc_homes = DocumentHome.find_all_by_mapable_type('User')
    for doc in doc_homes
      if doc.folder_id
        folder = Folder.find(doc.folder_id)
        folder.update_attribute(:for_workspace,true)
      end
    end
  end
end

