class NormalizeDocumentHomesMatterFact < ActiveRecord::Migration
  def self.up
    # remove unused columns
    remove_column(:document_homes_matter_facts, :company_id)
    remove_column(:document_homes_matter_facts, :updated_at)
    remove_column(:document_homes_matter_facts, :created_at)
    remove_column(:document_homes_matter_facts, :deleted_at)
    remove_column(:document_homes_matter_facts, :permanent_deleted_at)    
  end

  def self.down
    # add removed columns
    add_column(:document_homes_matter_facts, :company_id,:integer) 
    add_column(:document_homes_matter_facts, :updated_at,:timestamp) 
    add_column(:document_homes_matter_facts, :created_at,:timestamp) 
    add_column(:document_homes_matter_facts, :deleted_at,:timestamp) 
    add_column(:document_homes_matter_facts, :permanent_deleted_at,:timestamp)     
  end
end
