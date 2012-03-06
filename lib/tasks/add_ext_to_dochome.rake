namespace :document_home do
  task :add_ext => :environment do
    document = DocumentHome.find(:all) do|doc_home|
      doc = doc_home.latest_doc
      ext = doc.data_file_name || ""
      ext = ext.split('.')
      if ext.size > 1
        ext = ext.last
      else
        ext = nil
      end
      doc_home.update_attribute(:extension, ext)
    end
  end
end

