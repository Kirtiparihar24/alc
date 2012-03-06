# Author Mandeep
# Task to create access control entries for old ToE documents for all the matters.

namespace :access_control_fix_for_toe do
  task :access_control_fix => :environment do
    doc_homes = DocumentHome.find(:all, :conditions => ["mapable_type = 'Matter' AND sub_type = 'Termcondition'"])
    doc_homes.each do|doc_home|
      con_id = doc_home.mapable.contact_id rescue nil
      access = AccessControl.find(:first, :conditions => ["document_home_id = ? AND contact_id = ?", doc_home.id, con_id]) unless con_id.nil?
      if access.nil?
        new_access = AccessControl.new({:document_home_id => doc_home.id, :contact_id => con_id})
        new_access.save
      end
    end
    Asset.find(:all).each do |asset|
      comp = Document.find(asset.attachable_id).company_id
      asset.update_attribute(:company_id, comp)
    end      
  end
end

