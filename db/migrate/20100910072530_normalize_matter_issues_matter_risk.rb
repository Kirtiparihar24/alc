class NormalizeMatterIssuesMatterRisk < ActiveRecord::Migration
  def self.up
    # remove unused columns
    remove_column(:matter_issues_matter_risks, :company_id)
    remove_column(:matter_issues_matter_risks, :updated_at)
    remove_column(:matter_issues_matter_risks, :created_at)
    remove_column(:matter_issues_matter_risks, :deleted_at)
    remove_column(:matter_issues_matter_risks, :permanent_deleted_at)    
  end

  def self.down
    # add removed columns
    add_column(:matter_issues_matter_risks, :company_id,:integer) 
    add_column(:matter_issues_matter_risks, :updated_at,:timestamp) 
    add_column(:matter_issues_matter_risks, :created_at,:timestamp) 
    add_column(:matter_issues_matter_risks, :deleted_at,:timestamp) 
    add_column(:matter_issues_matter_risks, :permanent_deleted_at,:timestamp)     
  end
end
