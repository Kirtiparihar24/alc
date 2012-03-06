# Author Mandeep
# Task to create access control entries for old ToE documents for all the matters.

namespace :docs_in_company_structure do
 task :create_docs  => :environment do
    p 'deleting docs which are virtually deleted'
    Asset.find_only_deleted(:all).each do |asset_temp|
     asset_temp.destroy!
    end

    Document.find_only_deleted(:all).each do |document_temp|
      document_temp.destroy!
    end
    
    DocumentHome.find_only_deleted(:all).each  do |doc_home_temp|
      doc_home_temp.destroy!
    end


   Asset.find(:all).each do |asset|
     unless File.exist?(RAILS_ROOT + "/#{asset.url}/#{asset.data_file_name}")
      asset.destroy!
     end
   end

    Document.find(:all).each do |document|
      unless Asset.find(:all, :conditions => ['attachable_id=?',document.id ]).length > 0
       document.destroy!
      end
    end
    DocumentHome.find(:all).each do |document_home|
       unless Document.find(:all, :conditions => ['document_home_id=?',document_home.id ]).length > 0
         document_home.destroy!
       end
    end
    



     p 'creating company folder'
    new_dir = File.join(RAILS_ROOT + '/assets/', 'company')
    FileUtils::mkdir_p(new_dir) unless File.exists?(new_dir)

        p 'creating ids of companies '
        assets=Asset.find_with_deleted(:all)
        company_ids = assets.collect{|e| e.company_id}.uniq
        company_ids.each do |company_id|
          FileUtils::mkdir_p(new_dir + '/' + company_id.to_s)
          in_company=File.join(RAILS_ROOT + '/assets/company/' + company_id.to_s , 'docs' )
          FileUtils::mkdir_p(in_company) unless File.exists?(in_company)
        end


        #create files
    assets.each do |asset|
      p 'Moving asset ' +  asset.id.to_s  + " of company " + asset.company.name if asset.company


      in_asset=File.join(RAILS_ROOT + '/assets/company/' + asset.company_id.to_s + '/docs/' , asset.attachable_id.to_s )
      FileUtils::mkdir_p(in_asset) unless File.exists?(in_asset)
      src_path = File.join(asset.url, asset.name)
      if File.exists?(src_path)
      FileUtils::copy_file(src_path, RAILS_ROOT + '/assets/company/' + asset.company_id.to_s + '/docs/' + asset.attachable_id.to_s + '/' + asset.name  )
      elsif File.exists?(src_path + '.')
      FileUtils::copy_file(src_path + '.', RAILS_ROOT + '/assets/company/' + asset.company_id.to_s + '/docs/' +  asset.attachable_id.to_s + '/'+ asset.name  )
      end
    end

           Asset.find_with_deleted(:all).each do |asset|
         document=Document.find_with_deleted(asset.attachable_id) rescue nil
        unless document.nil?
        document.update_attributes(:data_file_name=> asset.data_file_name,:data_content_type=> asset.data_content_type, :data_file_size=> asset.data_file_size )
        else
           asset.destroy!
           puts 'invalid document for asset id ' + asset.id.to_s + ' and document id ' + asset.attachable_id.to_s
         end
    end


 end

#    task :update_documents_table  => :environment do
#       Asset.find_with_deleted(:all).each do |asset|
#         document=Document.find_with_deleted(asset.attachable_id) rescue nil
#        unless document.nil?
#            if  document.data_file_name.blank? && document.data_content_type.blank?
#              document.update_attributes(:data_file_name=> asset.data_file_name,:data_content_type=> asset.data_content_type, :data_file_size=> asset.data_file_size )
#            else
#              puts 'document already has a file_name'
#            end
#         else
#           asset.destroy!
#           puts 'invalid document for asset id ' + asset.id.to_s + ' and document id ' + asset.attachable_id.to_s
#         end
#    end
#    Document.find_with_deleted(:all, :conditions => 'data_file_name is null').each do |document|
#      p 'deleting invalid document_homes'
#
#      DocumentHome.find_with_deleted(:first, :conditions=> ['id=?', document.document_home_id]).destroy! if DocumentHome.find_with_deleted(:first, :conditions=> ['id=?', document.document_home_id])
#      p 'deleting invalid documents' + document.id.to_s
#      document.destroy!
#    end
#  end
#
#
#  task :move_documents => :environment do
#
#    FileUtils::mkdir_p(File.join(RAILS_ROOT, 'assets')) unless File.exists?(File.join(RAILS_ROOT, 'assets'))
#
#    #create folders
#    p 'creating company folder'
#    new_dir = File.join(RAILS_ROOT + '/assets/', 'company')
#    FileUtils::mkdir_p(new_dir) unless File.exists?(new_dir)
#
#    p 'creating ids of companies '
#    assets=Asset.find_with_deleted(:all)
#    company_ids = assets.collect{|e| e.company_id}.uniq
#    company_ids.each do |company_id|
#      FileUtils::mkdir_p(new_dir + '/' + company_id.to_s)
#      in_company=File.join(RAILS_ROOT + '/assets/company/' + company_id.to_s , 'docs' )
#      FileUtils::mkdir_p(in_company) unless File.exists?(in_company)
#    end
#
#    #create files
#    assets.each do |asset|
#      p 'Moving asset ' +  asset.id.to_s  + " of company " + asset.company.name if asset.company
#
#
#      in_asset=File.join(RAILS_ROOT + '/assets/company/' + asset.company_id.to_s + '/docs/' , asset.attachable_id.to_s )
#      FileUtils::mkdir_p(in_asset) unless File.exists?(in_asset)
#      src_path = File.join(asset.url, asset.name)
#      if File.exists?(src_path)
#      FileUtils::copy_file(src_path, RAILS_ROOT + '/assets/company/' + asset.company_id.to_s + '/docs/' + asset.attachable_id.to_s + '/' + asset.name  )
#      elsif File.exists?(src_path + '.')
#      FileUtils::copy_file(src_path + '.', RAILS_ROOT + '/assets/company/' + asset.company_id.to_s + '/docs/' +  asset.attachable_id.to_s + '/'+ asset.name  )
#      end
#    end
#  end
end

