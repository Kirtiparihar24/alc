namespace :company_additional_associations do
  task :company_resources => :environment do
    company_sources()
  end
  task :company_phases => :environment do
    phases()
  end
  task :set_source_value => :environment do
    set_source_value_for_contacts()
  end
  task :liti_types => :environment do
    liti_types()
  end
  task :nonliti_types => :environment do
    nonliti_types()
  end
  task :doc_sources => :environment do
    doc_sources()
  end
  task :document_source_value => :environment do
    set_document_source_value
  end
  task :matter_fact_source_value => :environment do
    set_doc_source_value_in_matter_fact
  end
  task :time_activity_type => :environment do
    set_time_activity_type
  end
  task :time_expense_type => :environment do
    set_time_expense_type
  end
  task :research_type => :environment do
    set_research_type()
  end
  task :rating_type => :environment do
    rating_type()
  end
  task :deactivate_contacts_source => :environment do
    set_source_value_for_deactivate_contact()
  end
  task :matter_people_roles => :environment do
    matter_people_roles
  end
  task :company_roles => :environment do
    company_roles
  end
  task :company_matter_status => :environment do
    company_matter_status
  end
end

def company_sources
  companies = Company.all
  companies.each do |company|
    if company.company_sources && company.company_sources.size <= 0
      sources = LeadSource.all
      sources.each do |source|
        company.company_sources << CompanySource.new({:lvalue=>source.lvalue})
      end
      p 'sources is created for each company'
    end
  end
end
def phases
  companies = Company.all
  companies.each do |company|
    if company.phases && company.phases.size <= 0
      matter_phases = MatterPhase.all
      matter_phases.each do |matter_phase|
        company.phases << Phase.new({:lvalue=>matter_phase.lvalue})
      end
      p 'phases created for each company'
    end
  end
  matters = Matter.all
  matters.each do |matter|
    company = Company.find matter.company_id
    if matter.phase_id
      lvalue = MatterPhases.find(matter.phase_id).lvalue
      phase_h = company.phases.array_to_hash('lvalue')
      p "phase id " + lvalue
      p " Phase lvalue from company lookup " + phase_h[lvalue].lvalue
      matter.phase_id = phase_h[lvalue].id
      matter.save false
    end
  end
  matter_tasks = MatterTask.all
  matter_tasks.each do |matter_task|
    company = Company.find matter_task.company_id
    if matter_task.phase_id
      lvalue = MatterPhases.find(matter_task.phase_id).lvalue
      phase_h = company.phases.array_to_hash('lvalue')
      p "phase id " + lvalue
      p " Phase lvalue from company lookup " +  phase_h[lvalue].lvalue
      matter_task.phase_id = phase_h[lvalue].id
      matter_task.save false
    end
  end
end

def set_source_value_for_contacts()
  companies = Company.all
  f = File.new("#{RAILS_ROOT}/public/source_result.txt", 'w+')
  f.write("The comparsion value after the rake task \n \n")
  companies.each do |company|
    f.write(company.name + "\n \n")
    sources_hash = company.company_sources.array_to_hash('lvalue')
    contacts = company.contacts.find :all,:conditions=>"source is not null"
    contacts.each do |contact|
      f.write("-----------------------------------------------------------------------------------------------\n")
      f.write("contact source id " + contact.source.to_s + "\n")
      l = LeadSource.find contact.source
      f.write("leadSource id and value from lookup table :" + l.id.to_s + " lvalue " + l.lvalue + "\n")
      f.write("Now source id set from company_lookup table \n")
      f.write(" source id and lvalue from company_lookup table :" + sources_hash[l.lvalue].id .to_s + " " + sources_hash[l.lvalue].lvalue + "\n")
      #        contact.company_source_id = sources_hash[l.lvalue].id
      contact.source = sources_hash[l.lvalue].id
      contact.save false
      f.write("After save the source value in the contact table : " + contact.company_source.lvalue + "\n")
    end
    opportunities = company.opportunities.find :all,:conditions => "source is not null"
    opportunities.each do |opportunity|
      f.write("-----------------------------------------------------------------------------------------------\n")
      f.write("opportunity source id " + opportunity.source.to_s + "\n")
      l = LeadSource.find opportunity.source
      f.write("leadSource id and value from lookup table :" + l.id.to_s + " lvalue " + l.lvalue + "\n")
      f.write("Now source id set from company_lookup table \n")
      f.write(" source id and lvalue from company_lookup table :" + sources_hash[l.lvalue].id .to_s + " " + sources_hash[l.lvalue].lvalue + "\n")
      #        opportunity.company_source_id = sources_hash[l.lvalue].id
      opportunity.source = sources_hash[l.lvalue].id
      opportunity.save false
      f.write("After save the source value in the opportunities table : " + opportunity.company_source.lvalue + "\n")
    end
    f.write("------------------------------------------------------------------------------------------------------\n \n")
  end
  f.close
end

def liti_types()
  companies = Company.all
  companies.each do |company|
    if (company.liti_types && company.liti_types.size <= 0)
      company.liti_types << TypesLiti.new(:lvalue=>"Civil")
      company.liti_types << TypesLiti.new(:lvalue=>"Appeals")
      company.liti_types << TypesLiti.new(:lvalue=>"Criminal")
    end
  end
end
def nonliti_types()
  companies = Company.all
  non_types = TypesNonLiti.find(:all,  :conditions => {:company_id => Company.find_by_name("Livia").id})
  companies.each do |company|
    if (company.nonliti_types && company.nonliti_types.size <= 0)
      non_types.each do |non_type|
        company.nonliti_types << TypesNonLiti.new(:lvalue=>non_type.lvalue)
      end
    end
  end
end
def doc_sources()
  companies = Company.all
  companies.each do |company|
    sources = company.doc_sources
    if (sources && sources.size <= 0)
      company.doc_sources << DocSource.new(:lvalue=>"Email")
      company.doc_sources << DocSource.new(:lvalue=>"Letter")
      company.doc_sources << DocSource.new(:lvalue=>"Fax")
      company.doc_sources << DocSource.new(:lvalue=>"Client")
      company.doc_sources << DocSource.new(:lvalue=>"Other")
    end
  end
end
def set_document_source_value()
  docs = Document.all
  f = File.new("#{RAILS_ROOT}/public/doc.txt",'w+')
  f.write("Document source rake task \n")
  i = 1
  docs.each do |doc|
    begin
      doc_source_hash = doc.company.doc_sources.array_to_hash('lvalue')
      h_key = (!doc.source.nil? && !doc.source.blank?) ? doc.source : "Other"
      doc.doc_source_id = doc_source_hash[h_key].id
      doc.save false
      f.write(doc.company.name + "'s source value saved \n")
    rescue
      f.write(doc.name + " has been deleted because the company is nil \n")
      i +=1
    end
  end
  f.write("No of document's company is null = " + i.to_s)
  f.close
end

def set_doc_source_value_in_matter_fact
  matter_facts = MatterFact.all
  matter_facts.each do |matter_fact|
    doc_source_hash = matter_fact.company.doc_sources.array_to_hash('lvalue')
    if matter_fact.source.blank?
      matter_fact.doc_source_id = doc_source_hash['Other'].id
    else
      matter_fact.doc_source_id = doc_source_hash[matter_fact.source].id
    end
    matter_fact.save false
  end
end
def set_time_activity_type()
  activity_types = Lookup.find_all_by_type('Physical::Timeandexpenses::ActivityType')
  companies = Company.all
  companies.each do |company|
    if company.activity_types && company.activity_types.size <= 0
      activity_types.each do |type|
        company.activity_types << Physical::Timeandexpenses::ActivityType.new(:lvalue=>type.lvalue)
      end
    end
  end
  tms = Physical::Timeandexpenses::TimeEntry.all
  tms.each do |tm|
    v_hash = tm.company.activity_types.array_to_hash('lvalue')
    lvalue =Lookup.find(tm.activity_type).lvalue
    p "value from lookup table " + lvalue
    tm.activity_type = v_hash[lvalue].id
    tm.save false
    p "activity_type #{v_hash[lvalue].lvalue} and id is" + tm.activity_type.to_s
  end
end
def set_time_expense_type()
  expense_types = Lookup.find_all_by_type('Physical::Timeandexpenses::ExpenseType')
  companies = Company.all
  companies.each do |company|
    if company.expense_types && company.expense_types.size <= 0
      expense_types.each do |type|
        company.expense_types << Physical::Timeandexpenses::ExpenseType.new(:lvalue=>type.lvalue)
      end
    end
  end
  expenses = Physical::Timeandexpenses::ExpenseEntry.all
  expenses.each do |expense|
    v_hash = expense.company.expense_types.array_to_hash('lvalue')
    lvalue =Lookup.find(expense.expense_type).lvalue
    p "value from lookup table " + lvalue
    expense.expense_type = v_hash[lvalue].id
    expense.save false
    p "activity_type #{v_hash[lvalue].lvalue} and id is " + expense.expense_type.to_s
  end
end

def set_research_type()
  research_types = MatterResearchType.all
  companies = Company.all
  companies.each do |company|
    if company.research_types && company.research_types.size <= 0
      research_types.each do |type|
        company.research_types << ResearchType.new(:lvalue=>type.lvalue)
      end
    end
  end
  matter_researches = MatterResearch.all
  matter_researches.each do |matter_research|
    v_hash = matter_research.company.research_types.array_to_hash('lvalue')
    lvalue = MatterResearchType.find(matter_research.research_type).lvalue
    p "value from lookup table " + lvalue
    matter_research.research_type = v_hash[lvalue].id
    matter_research.save false
    p "activity_type #{v_hash[lvalue].lvalue} and id is " + matter_research.research_type.to_s
  end
end

def rating_type
  companies = Company.all
  companies.each do |company|
    if company.rating_type.nil?
      company.rating_type = RatingType.new(:lvalue=>"*")
    end
  end
end

def set_source_value_for_deactivate_contact
  companies = Company.all
  f = File.new("#{RAILS_ROOT}/public/deact_contact_source_result.txt", 'w+')
  f.write("The comparsion value after the rake task \n \n")
  companies.each do |company|
    f.write(company.name + "\n \n")
    sources_hash = company.company_sources.array_to_hash('lvalue')
    contacts = company.contacts.find_only_deleted :all,:conditions=>"source is not null"
    contacts.each do |contact|
      begin
        f.write("-----------------------------------------------------------------------------------------------\n")
        f.write("contact source id " + contact.source.to_s + "\n")
        l = LeadSource.find contact.source
        f.write("leadSource id and value from lookup table :" + l.id.to_s + " lvalue " + l.lvalue + "\n")
        f.write("Now source id set from company_lookup table \n")
        f.write(" source id and lvalue from company_lookup table :" + sources_hash[l.lvalue].id .to_s + " " + sources_hash[l.lvalue].lvalue + "\n")
        #        contact.company_source_id = sources_hash[l.lvalue].id
        contact.source = sources_hash[l.lvalue].id
        contact.save false
        f.write("After save the source value in the contact table : " + contact.company_source.lvalue + "\n")
      rescue
        p " error source id #{contact.source}"
      end
    end
  end
  f.close

end

def company_roles
  load("lookup.rb")
  team_roles = TeamRoles.all
  client_roles = Lookup.find(:all,  :conditions => { :type => 'TeamRoles', :lvalue => ["Senior Counsel","Lead Lawyer","Matter Client","Junior Counsel","Associate","Senior Associate","Paralegal"]})
  other_roles = OtherRoles.all
  client_rep_roles = ClientRepRoles.all
  companines = Company.all
  companines.each do |company|
    team_roles.each {|team_role| company.team_roles << TeamRole.new(:lvalue=>team_role.lvalue)}
    p "Team role rake is finished \n"
    client_roles.each {|client_role| company.client_roles << ClientRole.new(:lvalue =>client_role.lvalue)}
    p "Client role rake is finished \n"
    other_roles.each {|other_role| company.other_roles << OtherRole.new(:lvalue =>other_role.lvalue)}
    p "Other role rake is finished \n"
    client_rep_roles.each {|rep_role| company.client_rep_roles << ClientRepRole.new(:lvalue =>rep_role.lvalue)}
    p "client rep role rake is finished \n"
  end
end

def matter_people_roles
  f = File.new("#{RAILS_ROOT}/public/reset_matter_people_role.txt", 'w+')
  companies = Company.all
  companies.each do |company|
    f.write("\n  Company Name :  #{company.name}")
    team_roles_hash = company.team_roles.array_to_hash('lvalue')
    client_roles_hash = company.client_roles.array_to_hash('lvalue')
    other_roles_hash = company.other_roles.array_to_hash('lvalue')
    client_rep_roles_hash = company.client_rep_roles.array_to_hash('lvalue')
    matter_peoples = MatterPeople.find(:all,:conditions=>"company_id=#{company.id}")
    i = 1
    matter_peoples.each do |m|
      role = Lookup.find_by_id m.role
      if(role)
        p "---------------------------------------------#{role.id} value #{role.lvalue}"
        f.write("\n \t Matter People #{i} \n")
        if(role.type.to_s.eql?("TeamRoles"))
          if m.employee_user_id.nil?
            f.write("\t TeamRole value from lookup table :  " + role.lvalue)
            m.role = team_roles_hash[role.lvalue].id
          else
            f.write("\t Client Role value from lookup table :  " + role.lvalue)
            m.role = client_roles_hash[role.lvalue].id
          end
        elsif(role.type.to_s.eql?("OtherRoles"))
          f.write("\t OtherRoles value from lookup table :  " + role.lvalue)
          m.role = other_roles_hash[role.lvalue].id
        elsif(role.type.to_s.eql?("ClientRepRoles"))
          f.write("\t ClientRepRoles value from lookup table :  " + role.lvalue)
          m.role = client_rep_roles_hash[role.lvalue].id
        end
      end
      i +=1
      m.save
      f.write("\t Current value from company look : " + m.people_role.lvalue )
    end
  end
  f.write("\n ----------------------------------------------------------------------------end of file -------------------------------------------------------------------")
end

def company_role_rates
  f = File.new("#{RAILS_ROOT}/public/company_role_rate.txt", 'w+')
  CompanyRoleRate.all.each do |comp_role|
    company = Company.find_by_id(comp_role.company_id)
    roles_hash = {}
    roles_hash.merge!({"TeamRoles"=>company.team_roles.array_to_hash('lvalue')})
    lookup = Lookup.find_by_id(comp_role.role_id)
    unless lookup.nil?
      f.write("\n The type and value from lookup #{lookup.type.to_s} :  #{lookup.lvalue}")
      comp_role.role_id = roles_hash[lookup.type.to_s][lookup.lvalue].id
      f.write("\n The type and value from company lookup #{roles_hash[lookup.type.to_s][lookup.lvalue].type.to_s} :  #{roles_hash[lookup.type.to_s][lookup.lvalue].lvalue}")
      comp_role.save
    end
  end
  p "rake is finished successfully"
  f.close
end
def company_matter_status
  companies = Company.all
  companies.each do |company|
    if(company.matter_statuses.size <= 0)
      if(company.name =="Dickinson Law Offices")
        company.matter_statuses << MatterStatus.new(:lvalue=>"Open")
        company.matter_statuses << MatterStatus.new(:lvalue=>"Completed")
        company.matter_statuses << MatterStatus.new(:lvalue=>"Abandoned")
        company.matter_statuses << MatterStatus.new(:lvalue=>"Expired")
      else
        company.matter_statuses << MatterStatus.new(:lvalue=>"Open")
        company.matter_statuses << MatterStatus.new(:lvalue=>"Completed")
      end
    end
  end
  p "company matter status rake is finished successfully"
  matters = Matter.all
  matters.each do |matter|
    matter.status = matter.company.matter_statuses.array_hash_value('lvalue', matter.temp_status, 'id')
    matter.save
    p "matte previous status #{matter.temp_status} -------> afte updating === #{matter.matter_status.lvalue}"
  end
end