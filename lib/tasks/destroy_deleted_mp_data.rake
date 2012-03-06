# Author Anil
# For destroying deleted matter peoples associated document homes and document_access_controls
desc "For destroying deleted matter peoples associated document homes and document_access_controls"
task :destroy_deleted_mp_data => :environment do
  deleted_mp = MatterPeople.find_only_deleted(:all)
  deleted_mp.each do|mp|
    mp.document_homes.each{|dh| dh.destroy}
    mp.document_access_controls.each{|dac| dac.destroy}
  end
end