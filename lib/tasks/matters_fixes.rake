# Author Mandeep
# For matter related fixes.

namespace :matter_fixes do


  task :fix_role_lookup => :environment do
    # change matter team role id lookup, replace values that are coming from old lookups table.
    MatterPeople.find(:all, :conditions => ["matter_team_role_id is not null"]).each do|mp|
      rolec = CompanyLookup.find(:all, :conditions => ["id = ? AND company_id = ?", mp.matter_team_role_id, mp.company_id])
      if rolec.empty?
        role = Lookup.find(:first, :conditions => ["id = ?", mp.matter_team_role_id])
        if role
          rolec = CompanyLookup.find(:first, :conditions =>
              ["type = ? AND lvalue = ? AND company_id = ?", role.type.to_s.singularize, role.lvalue, mp.company_id])
          if rolec
            unless mp.update_attribute(:matter_team_role_id, rolec.id)
              puts mp.errors.full_messages.join("\n")
            end
          end
        end
      end
    end
  end

  task :fix_client_matter_id => :environment do
    # Clean up the old entries which do not have contact_id.
    MatterPeople.connection.execute("DELETE FROM matter_peoples WHERE (contact_id IS NULL OR matter_id IS NULL) AND people_type = 'matter_client'")
    existing_clients = MatterPeople.find(:all, :conditions => ["contact_id is not null AND matter_id is not null AND people_type = 'matter_client'"])
    clientless_matters = Matter.find(:all, :conditions => ["contact_id NOT IN (?)", existing_clients.collect {|e| e.contact_id}])
    clientless_matters.each do |matter|
     
      client = matter.matter_peoples.new({
          :contact_id => matter.contact_id,
          :name => matter.contact.try(:full_name),
          :is_active => true,
          :people_type => 'matter_client',
          :matter_team_role_id => matter.company.client_roles.array_hash_value('lvalue','Matter Client','id'),
          :matter_id => matter.id,
          :start_date => matter.created_at,
          :created_by_user_id => matter.created_by_user_id,
          :company_id => matter.company_id,
          :can_access_matter => matter.client_access
        })
      client.save
    end
  end

  task :fix_matter_people_matter_client => :environment do
    clientless_matters =Matter.find(:all,:conditions=>['contact_id is not null'])
    clientless_matters.each do |matter|
      mp=MatterPeople.find_by_contact_id_and_matter_id_and_people_type(matter.contact_id,matter.id,'matter_client')
      if mp.nil?
        client = matter.matter_peoples.new({
            :contact_id => matter.contact_id,
            :name => matter.contact.try(:full_name),
            :is_active => true,
            :people_type => 'matter_client',
            :matter_team_role_id => matter.company.client_roles.array_hash_value('lvalue','Matter Client','id'),
            :matter_id => matter.id,
            :start_date => matter.created_at,
            :created_by_user_id => matter.created_by_user_id,
            :company_id => matter.company_id,
            :can_access_matter => matter.client_access
          })
        client.save
      end
    end
  end
  
  task :fix_matter_people_company_id_from_matter_company_id => :environment do
    # Fix matter_people company_id by taking the value from matter company_id.
    MatterPeople.all.each do|e|
      if e.company_id != e.matter.company_id
        puts "OLD: " + e.company_id.to_s
        e.company_id = e.matter.company_id
        e.send(:update_without_callbacks)
        puts "NEW: " + e.company_id.to_s
      end
    end
  end

  task :fix_matter_task_dates => :environment do
    matter_tasks = MatterTask.all
    matter_tasks.each do|mt|
      sd = mt.start_date
      ed = mt.end_date
      st = mt.start_time
      et = mt.end_time
      mt.start_date = DateTime.new(sd.year, sd.month, sd.day, st.hour, st.min, st.sec)
      mt.end_date = DateTime.new(ed.year, ed.month, ed.day, et.hour, et.min, et.sec)
      mt.send(:update_without_callbacks)

    end
  end

  task :matters_cleanup_for_celsus => :environment do
    celsus = User.find(:first, :conditions => ["username = ?", "fernandesc"])
    matters = Matter.find(:all, :conditions => ["company_id = ? AND employee_user_id = ?", celsus.company_id, celsus.id])
    matters = matters.find_all {|e| e.matter_peoples.size < 3}
    matters.each do|m|
      m.matter_tasks.each {|e| e.deleted_at = Time.zone.now.to_date; e.send(:update_without_callbacks)}
      m.matter_issues.each {|e| e.deleted_at =Time.zone.now.to_date; e.send(:update_without_callbacks)}
      m.matter_facts.each {|e| e.deleted_at = Time.zone.now.to_date; e.send(:update_without_callbacks)}
      m.matter_peoples.each {|e| e.deleted_at =Time.zone.now.to_date; e.send(:update_without_callbacks)}
      m.matter_researches.each {|e| e.deleted_at = Time.zone.now.to_date; e.send(:update_without_callbacks)}
      m.matter_risks.each {|e| e.deleted_at = Time.zone.now.to_date; e.send(:update_without_callbacks)}
      m.document_homes.each {|e| e.deleted_at = Time.zone.now.to_date; e.send(:update_without_callbacks)}
      m.matter_litigations.each {|e| e.deleted_at = Time.zone.now.to_date; e.send(:update_without_callbacks)}
      m.deleted_at = Time.zone.now.to_date; m.send(:update_without_callbacks)
    end

    matters.each do|m|
      m.matter_tasks.each {|e| e.deleted_at = nil; e.send(:update_without_callbacks)}
      m.matter_issues.each {|e| e.deleted_at = nil; e.send(:update_without_callbacks)}
      m.matter_facts.each {|e| e.deleted_at = nil; e.send(:update_without_callbacks)}
      m.matter_peoples.each {|e| e.deleted_at = nil; e.send(:update_without_callbacks)}
      m.matter_researches.each {|e| e.deleted_at = nil; e.send(:update_without_callbacks)}
      m.matter_risks.each {|e| e.deleted_at = nil; e.send(:update_without_callbacks)}
      m.document_homes.each {|e| e.deleted_at = nil; e.send(:update_without_callbacks)}
      m.matter_litigations.each {|e| e.deleted_at = nil; e.send(:update_without_callbacks)}
      m.deleted_at = nil; m.send(:update_without_callbacks)
    end

  end

  task :matters_cleanup_on_request => :environment do
    matters = Matter.find([6,8,10])
    matters.each do|m|
      puts "---Deleting Matter Task"
      m.matter_tasks.each {|e| e.deleted_at = Time.zone.now.to_date ; e.send(:update_without_callbacks)}
      puts "---Deleting Matter Issue"
      m.matter_issues.each {|e| e.deleted_at = Time.zone.now.to_date; e.send(:update_without_callbacks)}
      puts "---Deleting Matter Fact"
      m.matter_facts.each {|e| e.deleted_at = Time.zone.now.to_date; e.send(:update_without_callbacks)}
      puts "---Deleting Matter People"
      m.matter_peoples.each {|e| e.deleted_at = Time.zone.now.to_date; e.send(:update_without_callbacks)}
      puts "---Deleting Matter Termconditions"
      m.matter_termcondition.deleted_at = Time.zone.now.to_date; m.send(:update_without_callbacks)
      puts "---Deleting Matter Research"
      m.matter_researches.each {|e| e.deleted_at = Time.zone.now.to_date; e.send(:update_without_callbacks)}
      puts "---Deleting Matter Risk"
      m.matter_risks.each {|e| e.deleted_at = Time.zone.now.to_date; e.send(:update_without_callbacks)}
      puts "---Deleting Matter Document"
      m.document_homes.each {|e| e.deleted_at = Time.zone.now.to_date; e.send(:update_without_callbacks)}
      puts "---Deleting Matter Litigation"
      m.matter_litigations.each {|e| e.deleted_at = Time.zone.now.to_date; e.send(:update_without_callbacks)}
      puts "---Deleting Matter Budgets"
      m.matter_budgets.each {|e| e.deleted_at = Time.zone.now.to_date; e.send(:update_without_callbacks)}
      puts "---Deleting Matter Billing"
      m.matter_billings.each {|e| e.destroy}
      puts "---Deleting Matter Retainer"
      m.matter_retainers.each {|e| e.destroy}
      puts "---Deleting Matter Time Entry"
      m.time_entries.each {|e| e.deleted_at = Time.zone.now.to_date; e.send(:update_without_callbacks)}
      puts "---Deleting Matter Expense"
      m.expense_entries.each {|e| e.deleted_at = Time.zone.now.to_date; e.send(:update_without_callbacks)}
      puts "---Deleting Matter Children"
      m.children.each {|e| e.deleted_at = Time.zone.now.to_date; e.send(:update_without_callbacks)}
      puts "---Deleting Matter"
      m.deleted_at = Time.zone.now.to_date; m.send(:update_without_callbacks)

    end

  end

  task :fix_matter_people_matter_lead_lawyer => :environment do
    # Run this task if any matter don't have any Legal Team Members.    
    Matter.find(:all).each do |matter|
      matter_peoples= MatterPeople.count(:conditions => ["employee_user_id=? and matter_id=? AND company_id=?",matter.employee_user_id,matter.id,matter.company_id])
       if matter_peoples == 0
        client = matter.matter_peoples.new({
            :is_active => true,
            :people_type => 'client',
            :matter_team_role_id => matter.company.client_roles.array_hash_value('lvalue','Lead Lawyer','id'),
            :matter_id => matter.id,
            :start_date => matter.created_at,
            :created_by_user_id => matter.created_by_user_id,
            :employee_user_id=> matter.employee_user_id,
            :company_id => matter.company_id
          })
        client.save
        p"Matter People Inserted for Matter_id",matter.id       
      end
    end
  end
end

