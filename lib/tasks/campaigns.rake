# Author Mandeep
# Task to create access control entries for old ToE documents for all the matters.

namespace :campaigns do
  task :lookups_update=> :environment do
    campaign_statuses =Physical::Crm::Campaign::CampaignStatusType.all
    campaign_statuses.each do |campaign_status|
    #  if lookup.type=='Physical::Crm::Campaign::CampaignMemberStatusType'
      campaign_status.update_attribute(:type,'CampaignStatusType')
    end
   member_statuses =Physical::Crm::Campaign::CampaignMemberStatusType.all
     member_statuses.each do |member_status|
    #  if lookup.type=='Physical::Crm::Campaign::CampaignMemberStatusType'
        member_status.update_attribute(:type,'CampaignMemberStatusType')

    end
  end

  task :change_campaign_source => :environment do
    change_campaign_source_with_company_lookup
  end

  desc "Create company wise campaignstatustype in company lookups table"
  task :company_lookup_campaignstatustype=> :environment do
    companies = Company.all
    lookups   = Lookup.find(:all,:conditions => { :type => 'CampaignStatusType'})
    companies.each do |company|
      lookups.each do |lookup|
        company.campaign_status_types.create(:type=>lookup.type,:lvalue=>lookup.lvalue,:alvalue=>lookup.lvalue)
      end
    end
  end

  desc "Create company wise campaignmemberstatustype in company lookups table"
  task :company_lookup_campaignmemberstatustype=> :environment do
    companies = Company.all
    lookups = Lookup.find(:all,:conditions => {:type => 'CampaignMemberStatusType'})
    companies.each do |company|
      lookups.each do |lookup|
        company.campaign_member_status_types.create(:type=>lookup.type,:lvalue=>lookup.lvalue,:alvalue=>lookup.lvalue)
      end
    end
  end


  desc "Update campaign table:campaign_status_type_id from company_lookups table"
  task :campaign_status_type_id_update_from_companylookups => :environment do
    # Below code loop will find campaign_status_type_id value in lookup table
    # And then depending on the look up table value will try find same value in companylookups table and update campaign tables campaign_status_type_id.
    # By Ajay Arsud om 24th Sept 2010
    campaign = Campaign.find_with_deleted(:all)
    campaign.each do |campaign|
      unless campaign.campaign_status_type_id.nil?
        lookup_value = Lookup.find(campaign.campaign_status_type_id)
        companylookp_value = CompanyLookup.find(:first,:conditions=>["type IN (?) AND lvalue IN (?) AND company_id =?",lookup_value[:type],lookup_value[:lvalue],campaign.company_id])
        Campaign.skip_callback(:check_status_change) do
         campaign.update_attribute(:campaign_status_type_id, companylookp_value[:id])
        end
      end
    end    
  end

  desc "Update campaign table:campaign_member_status_type_id from company_lookups table"
  task :campaign_member_status_type_id_update_from_companylookups => :environment do
    # Below code loop will find campaign_member_status_type_id value in lookup table
    # And then depending on the look up table value will try find same value in companylookups table and update campaign_members tables ampaign_member_status_type_id.
    # By Ajay Arsud om 24th Sept 2010
    campaign_members = CampaignMember.find_with_deleted(:all, :order => 'id asc')
    campaign_members.each do |campaign_member|
      unless campaign_member.campaign_member_status_type_id.nil?
        lookup_value = Lookup.find(campaign_member.campaign_member_status_type_id) rescue nil
        unless lookup_value.nil?
          companylookp_value= CompanyLookup.find(:first,:conditions=>["type = (?) AND lvalue IN (?) AND company_id = ?",lookup_value[:type],lookup_value[:lvalue],campaign_member.company_id])
          CampaignMember.skip_callback(:update_campaign_for_search) do
            campaign_member.update_attribute(:campaign_member_status_type_id, companylookp_value[:id])
          end
        end
      end
    end
  end

  # Below mentioned task is executed by rake campaigns:check_set_campaign_member_id[30]
  # Here 30 is company_id for which campaign_member_status_type_id is missing.
  # Added by Ajay Arsud on 27 th Sept 2010.
  desc "Check campaign members tables campaign_member_status_type_id is empty or not "
  task :check_set_campaign_member_id => :environment do
    CampaignMember.find_with_deleted(:all,:conditions => ["campaign_member_status_type_id is null"]) do |comp|
     company_id = comp.company_id
     CampaignMember.skip_callback(:update_campaign_for_search) do
      company_look_up_id = CompanyLookup.find(:first,:conditions=>["type = ? and lvalue = ? and company_id = ?",'CampaignMemberStatusType','New',company_id.to_s]).id
      comp.update_attribute(:campaign_member_status_type_id, company_look_up_id)
     end
   end
  end  

  def change_campaign_source_with_company_lookup
    opp=Opportunity.find_all_by_source(20)
      opp.each do |obj|
       obj.source=CompanySource.find_by_lvalue_and_company_id("Campaign",obj.company_id).id
       obj.send(:update_without_callbacks)
      end
  end  


  task :update_campaign_status_with_company_lookup_id => :environment do
    CampaignMember.find_with_deleted(:all).each do |comp|
     company_id = comp.company_id
     com_look = CompanyLookup.find(comp.campaign_member_status_type_id) rescue nil #Get present status
     if com_look.nil?
       company_look_up_id = CompanyLookup.find(:first,:conditions=>["type = ? and lvalue = ? and company_id = ?",'CampaignMemberStatusType', 'New', company_id.to_s]).id
     else
      company_look_up_id = CompanyLookup.find(:first,:conditions=>["type = ? and lvalue = ? and company_id = ?",'CampaignMemberStatusType', com_look.lvalue, company_id.to_s]).id
     end     
     CampaignMember.skip_callback(:update_campaign_for_search) do
      comp.update_attribute(:campaign_member_status_type_id, company_look_up_id) if com_look != company_look_up_id
     end
   end
  end

  task :campaign_member_data_correction => :environment do
    # Select id from company_lookups where  company_id = 3  and type = 'CampaignMemberStatusType'and lvalue = 'Responded'
    responded_id= CompanyLookup.first(:conditions=>['company_id = ?  and type = ? and lvalue = ?',3,'CampaignMemberStatusType','Responded'])
    #campaign_member = CampaignMember.find(:all,:conditions=>["campaign_member_status_type_id = ? and company_id =? ",1687,3])
    CampaignMember.update_all ['campaign_member_status_type_id = ?', responded_id.id], ["campaign_member_status_type_id = ? and company_id =? ",1687,3]
  end

end
