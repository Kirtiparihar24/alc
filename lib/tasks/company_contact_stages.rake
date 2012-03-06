namespace :contact_stages do
  task :company_contact_stages => :environment do
    contact_stages
  end
  task :set_alias_value_for_companylookup => :environment do
    add_value_for_companylookup()
  end
  task :setvalue_contact_stage => :environment do
    add_value_to_contact_stage_id
  end
  task :opportunity_stage_types_to_us_sales => :environment do
    us_sales_opportunity_stage_type_change
  end
end

def contact_stages
  companies = Company.all
  companies.each do |company|
    if company.contact_stages && company.contact_stages.size <=0
      company.contact_stages << ContactStage.new({:lvalue=>'Lead',:alvalue=>'Lead'})
      company.contact_stages << ContactStage.new({:lvalue=>'Prospect',:alvalue=>'Prospect'})
      company.contact_stages << ContactStage.new({:lvalue=>'Client',:alvalue=>'Client'})
      company.contact_stages << ContactStage.new({:lvalue=>'Others',:alvalue=>'Others'})
    end
  end
end

def add_value_to_contact_stage_id
  file = File.new("#{RAILS_ROOT}/public/contact_status.txt",'w+')
  companies = Company.all
  companies.each do |company|
    file.write("The Contact status according to company\n")
    file.write("____________________________________________________________________________________________________\n")
    h = Hash.new
    contact_stages = company.contact_stages
    contact_stages.each do |cnt_st|
      h.merge!(cnt_st.lvalue=>cnt_st.id)
    end
    contacts = company.contacts.find_by_sql("select c.*,lvalue from contacts c inner join lookups l on c.status = l.id where company_id=#{company.id}")
    contacts.each do |contact|
      file.write('Company Name : ' + company.name + " \n")
      file.write("Contact Person name : " + contact.name + "\n")
      file.write("Contact status from lookup table : " + Lookup.find(contact.status).lvalue + "\n")
      contact.contact_stage_id = h[contact.lvalue]
      contact.save(false)
      file.write("Contact status after save  : " + contact.contact_stage.alvalue + "\n")
    end
  end
  file.close
  puts "rake is finished "
end

def add_value_for_companylookup()
  contact_stages = ContactStage.all
  contact_stages.each do |stage|
    stage.alvalue = stage.lvalue
    stage.save
  end
  puts "rake finished"
end

def us_sales_opportunity_stage_type_change
  opps = OpportunityStageType.find_all_by_company_id(32)
  proposel_id = OpportunityStageType.find_by_company_id_and_lvalue(32,'Proposal').id
  prospecting_id = OpportunityStageType.find_by_company_id_and_lvalue(32,'Prospecting').id
  file = File.new("#{RAILS_ROOT}/public/us_sales_oppr_stages.txt",'w+')
  company = opps[0].company
  file.write("..............................#{company.name}\n")
  file.write("____________________________________________________________________________________________________\n")
  opps.each do |op|
    op.opportunities.each do |opport|
      file.write("Opportunity Name:                         #{opport.name}             Oppertunity ID: #{opport.id}              \n")
      file.write("Opportunity Stage ID:-                    #{op.id}           |           Stage Name: #{op.alvalue}\n")
    end
  end
  file.close
  new_stage_id=0
  company.opportunity_stage_types.create(:lvalue=>"Final Review",:alvalue=>"Lead")
  company.opportunity_stage_types.create(:lvalue=>"Negotiation",:alvalue=>"Prospect")
  
  opps.each do |op|
    if(op.alvalue=='Client Decision On-Hold')
      op.alvalue='Closed - No Interest'
#      op.lvalue='Closed - No Interest'
    elsif(op.alvalue=='Contract Executed')
      op.alvalue='Closed - Won'
#      op.lvalue='Closed - Won'
#    elsif(op.alvalue=='Demo')
#      op.lvalue='Demo'
    elsif(op.alvalue=='Closed/Lost')
      op.alvalue='Closed - Lost'
#      op.lvalue='Closed - Lost'
    elsif(op.alvalue=='Contract Preparation')
          op.alvalue='Contract'
    elsif(op.alvalue=='Discovery')

    elsif(op.alvalue=='Demo')

    else
#      if(op.alvalue=='Contract Modifications')
#            op.alvalue='Contract'
#      elsif(op.alvalue=='In for Signature')
#            op.alvalue='Contract'
#      elsif(op.alvalue=='Out for Signature')
#            op.alvalue='Contract'
#      elsif(op.alvalue=='Deal Negotiation')
#            op.alvalue='Contract'
#      elsif(op.alvalue=='Contract Review')
#            op.alvalue='Contract'
        if(op.alvalue=='Proposal')
          Opportunity.update_all("stage=#{prospecting_id}", ["company_id=32 and stage = ?", op.id])
        else
          Opportunity.update_all("stage=#{proposel_id}", ["company_id=32 and stage = ?", op.id])
        end
         op.destroy!
        next
    end
    puts op.alvalue
    op.save
  end
  opps = OpportunityStageType.find_all_by_company_id(32)
  opps.each do |op|
    if(op.alvalue=='Lead')
      op.percentage = 0
    elsif(op.alvalue=='Prospect')
      op.percentage = 25
    elsif(op.alvalue=='Discovery')
      op.percentage = 50
    elsif(op.alvalue=='Demo')
      op.percentage = 75
    elsif(op.alvalue=='Contract')
      op.percentage = 90
    elsif(op.alvalue=='Closed - Won')
      op.percentage = 100
    elsif(op.alvalue=='Closed - Lost')
      op.percentage = 0
    elsif(op.alvalue=='Closed - No Interest')
      op.percentage = 0
    end
    op.save
  end
  file = File.new("#{RAILS_ROOT}/public/us_sales_oppr_new_stages.txt",'w+')
  company = opps[0].company
  file.write("..............................#{company.name}\n")
  file.write("____________________________________________________________________________________________________\n")
  opps = OpportunityStageType.find_all_by_company_id(32)
  opps.each do |op|
    op.opportunities.each do |opport|
      file.write("Opportunity Name:                         #{opport.name}             Oppertunity ID: #{opport.id}              \n")
      file.write("Opportunity Stage ID:-                    #{op.id}           |           Stage Name: #{op.alvalue}\n")
    end
  end
  file.close
end