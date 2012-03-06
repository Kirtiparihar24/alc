class NormalizeMatterPeople < ActiveRecord::Migration
  def self.up
    # remove unused columns
    remove_column(:matter_peoples, :type)
    remove_column(:matter_peoples, :practice_area)
    remove_column(:matter_peoples, :law_firm)
    remove_column(:matter_peoples, :access)
    remove_column(:matter_peoples, :billing_by)
    remove_column(:matter_peoples, :retainer_amount)
    remove_column(:matter_peoples, :not_to_exceed_amount)
    remove_column(:matter_peoples, :min_trigger_amount)
    remove_column(:matter_peoples, :fixed_rate_amount)
    remove_column(:matter_peoples, :additional_details)
    
    # rename role, role is comming from company_lookup
    rename_column(:matter_peoples, :role, :matter_team_role_id)
    
  end

  def self.down
    # add removed columns
    add_column(:matter_peoples,:type,:string) 
    add_column(:matter_peoples,:practice_area,:string) 
    add_column(:matter_peoples,:law_firm,:string) 
    add_column(:matter_peoples,:access,:boolean) 
    add_column(:matter_peoples,:billing_by,:string) 
    add_column(:matter_peoples,:retainer_amount,:string) 
    add_column(:matter_peoples,:not_to_exceed_amount,:string) 
    add_column(:matter_peoples,:min_trigger_amount,:string) 
    add_column(:matter_peoples,:fixed_rate_amount,:string) 
    add_column(:matter_peoples,:additional_details,:string) 
    
    rename_column(:matter_peoples, :matter_team_role_id, :role)
  end
end
