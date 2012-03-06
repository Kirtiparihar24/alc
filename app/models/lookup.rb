class Lookup < ActiveRecord::Base
  def self.contact_status
    Lookup.all(:conditions => { :type => 'ContactStatus'})
  end

  def self.opportunity_contact_status
    Lookup.all(:conditions => {:type => 'ContactStatus', :lvalue => ['Prospect', 'Client']})
  end

#  def self.opportunity_stage_type
#    Lookup.find(:all,  :conditions => {:type => 'OpportunityStageType'})
#  end

  def self.matter_contact_status
    Lookup.all(:conditions => {:type => 'ContactStatus', :lvalue => ['Client']})
  end


#  def self.prospect_status_type
#    Lookup.find(:all,  :conditions => { :type => 'ProspectStatusType'},:order=>'id ASC')
#  end

#  def self.lead_status_type
#    Lookup.find(:all,  :conditions => { :type => 'LeadStatusType'},:order=>'id ASC')
#  end

  def self.lead_source
    Lookup.all(:conditions => { :type => 'LeadSource'})
  end

  def self.campaign_status_type
    Lookup.all(:conditions => { :type => 'CampaignStatusType'})
  end

  def self.types_liti
    Lookup.all(:conditions => { :type => 'TYPES_LITI'})
  end
  
  def self.matter_phases
    Lookup.all(:conditions => { :type => 'MatterPhases'})
  end
  def self.fact_matter
    Lookup.all(:conditions => { :type => 'FactMatter'})
  end

  def self.team_roles
    Lookup.all(:conditions => { :type => 'TeamRoles'})
  end

  def self.client_team_roles
    Lookup.all(:conditions => { :type => 'TeamRoles', :lvalue => ["Senior Counsel","Junior Counsel","Associate","Senior Associate","Paralegal"]})
  end

  def self.other_roles
    Lookup.all(:conditions => { :type => 'OtherRoles'})
  end
  def self.client_rep_roles
    Lookup.all(:conditions => { :type => 'ClientRepRoles'})
  end
  def self.matter_research_type
    Lookup.all(:conditions => { :type => 'MatterResearchType'})
  end
  def self.matter_phase
    Lookup.all(:conditions => { :type => 'MatterPhase'})
  end
  def self.matter_privileges
    Lookup.all(:conditions => { :type => 'MatterPrivileges'})
  end

  def self.payment_mode_type
    Lookup.all(:conditions => { :type => 'PaymentModeType'})
  end

  def self.payment_mode_from_lookup(id)
    Lookup.find_by_id(id).lvalue
  end

  def self.all_status_types(order_str='id ASC')
    self.all(:order=>order_str)
  end

  def self.get_status_type(val_str)
    find_by_lvalue(val_str)
  end

# As LeadStatusType moved into company lookups so no need of this fucntion in this plase
# also It is not using any where.
#  def self.rejected_contact
#    find(:all,:select=>['id'],:conditions=>['lvalue=? and type in (?)','Rejected',['LeadStatusType','ProspectStatusType']])
#  end
  
#  def self.company_default_roles
#    Lookup.find(:all,  :conditions => { :type => 'CompanyDefaultRoles'})
#  end

#  def self.opportunity_stage_type
#    Lookup.find(:all,  :conditions => { :type => 'OpportunityStageType'})
#  end

end


class ContactStatus < Lookup
end



#class LeadStatusType < Lookup
#  
#end

#class ProspectStatusType < Lookup
#end

# It is already in Company_lookup and replaced with CompanySource
# Should be Remove from here
class LeadSource < Lookup
end

# It is duplicate of MatterPhase
# Should be Remove from here
class MatterPhases < Lookup
end

class FactMatter < Lookup
end
#class MatterFactType < Lookup
#end

# It is already in Company_lookup
# Should be Remove from here
class TeamRoles < Lookup
  def self.role_from_name(name)
    Lookup.first(:conditions => {:type => "TeamRoles", :lvalue => name}).id
  end
end

# It is already in Company_lookup
# Should be Remove from here
class OtherRoles < Lookup
end

# It is already in Company_lookup
# Should be Remove from here
class ClientRepRoles < Lookup
end

class MatterResearchType < Lookup
end

# It is already in Company_lookup and renamed with Phase
# Should be Remove from here
class MatterPhase < Lookup
end

# It is already in Company_lookup
# Should be Remove from here
class MatterPrivileges < Lookup
end

#It is use only for livia_admin - No need to move on company_lookup
class PaymentModeType < Lookup
end

# It is Not used any more in the code
# Should be Remove from here
class PaymentModeFromLookup < Lookup
end

# It is Not used any more in the code
# Should be Remove from here
class CompanyDefaultRoles < Lookup
end


# == Schema Information
#
# Table name: lookups
#
#  id                   :integer         not null, primary key
#  type                 :string(255)
#  lvalue               :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#

