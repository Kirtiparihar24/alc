class NormalizeDocumentHomesMatterIssue < ActiveRecord::Migration
  def self.up
    # remove unused columns
    remove_column(:document_homes_matter_issues, :company_id)
    remove_column(:document_homes_matter_issues, :updated_at)
    remove_column(:document_homes_matter_issues, :created_at)
    remove_column(:document_homes_matter_issues, :deleted_at)
    remove_column(:document_homes_matter_issues, :permanent_deleted_at)    
  end

  def self.down
    # add removed columns
    add_column(:document_homes_matter_issues, :company_id,:integer) 
    add_column(:document_homes_matter_issues, :updated_at,:timestamp) 
    add_column(:document_homes_matter_issues, :created_at,:timestamp) 
    add_column(:document_homes_matter_issues, :deleted_at,:timestamp) 
    add_column(:document_homes_matter_issues, :permanent_deleted_at,:timestamp)     
  end
end
