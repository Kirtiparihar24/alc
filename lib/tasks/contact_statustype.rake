namespace :contact_status_type_update do

  task :update_status_type => :environment do
    update
  end

  task :update_status_stage_type => :environment do
    Contact.find_with_deleted(:all, :order => 'id asc').each do |contact|
      cstage = contact.contact_stage.lvalue
      cstatus = CompanyLookup.find(contact.status_type) rescue nil
      if !cstatus.nil?
        if ['New', 'Contacted', 'Active', 'Inactive'].include?(cstatus.lvalue) && ['Lead', 'Client', 'Prospect', 'Others'].include?(cstage)        
            if cstage == 'Lead'
              unless ['New', 'Contacted'].include?(cstatus.lvalue)
                contact.status_type = LeadStatusType.find_by_lvalue_and_company_id('New', contact.company_id).id
              end
            elsif ['Prospect','Client', 'Others'].include?(cstage)
              unless ['Active', 'Inactive'].include?(cstatus.lvalue)
                contact.status_type = ProspectStatusType.find_by_lvalue_and_company_id('Active', contact.company_id).id                
              end
            end
        else
          if cstage == 'Lead'
            contact.status_type = LeadStatusType.find_by_lvalue_and_company_id('New', contact.company_id).id            
          else
            contact.status_type = ProspectStatusType.find_by_lvalue_and_company_id('Active', contact.company_id).id            
          end
        end
      else
          if cstage == 'Lead'
            contact.status_type = LeadStatusType.find_by_lvalue_and_company_id('New', contact.company_id).id            
          else
            contact.status_type = ProspectStatusType.find_by_lvalue_and_company_id('Active', contact.company_id).id            
          end
      end
      contact.save false
    end
  end

end

def update
  lookup = LeadStatusType.find_by_lvalue('New')
  Contact.all.each do |contact|
    unless !contact.status_type.blank?
      contact.status_type= lookup.id
      contact.save false
    end
  end
end

def update_unknown_status
  lstat = LeadStatusType.find_by_lvalue('New')
  pstat = ProspectStatusType.find_by_lvalue('Active')
  Contact.find_with_deleted(:all, :order => 'id asc').each do |contact|
    lookstatus = Lookup.find_by_id(contact.status_type)
    if lookstatus.nil? &&  contact.contact_stage.nil?
      contact.status_type= lstat.id
      contact.contact_stage_id = ContactStage.find_by_lvalue_and_company_id('Lead', contact.company_id).id
    elsif lookstatus.nil? && !contact.contact_stage.nil?
      if contact.contact_stage.lvalue == 'Lead'
        contact.status_type= lstat.id
      else
        contact.status_type= pstat.id
      end
    else
      if !contact.contact_stage.nil?
        if contact.contact_stage.lvalue == 'Lead'
          #p "#{contact.id} ------- #{contact.contact_stage.lvalue} ------ #{lookstatus.lvalue}" if !['New','Contacted'].include?(lookstatus.lvalue)
          contact.status_type= lstat.id if !['New','Contacted'].include?(lookstatus.lvalue)
        else
          #p "#{contact.id} ------- #{contact.contact_stage.lvalue} ------ #{lookstatus.lvalue}" if !['Active','Inactive'].include?(lookstatus.lvalue)
          contact.status_type= pstat.id if !['Active','Inactive'].include?(lookstatus.lvalue)
        end
      else
        if ['New','Contacted'].include?(lookstatus.lvalue)
          contact.contact_stage_id = ContactStage.find_by_lvalue_and_company_id('Lead', contact.company_id).id
        elsif ['Active','Inactive'].include?(lookstatus.lvalue)
          contact.contact_stage_id = ContactStage.find_by_lvalue_and_company_id('Prospect', contact.company_id).id
        end
      end
    end
    contact.save false
  end

end