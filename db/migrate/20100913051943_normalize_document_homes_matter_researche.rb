class NormalizeDocumentHomesMatterResearche < ActiveRecord::Migration
  def self.up
    # remove unused columns
    remove_column(:document_homes_matter_researches, :company_id)
    remove_column(:document_homes_matter_researches, :updated_at)
    remove_column(:document_homes_matter_researches, :created_at)
    remove_column(:document_homes_matter_researches, :deleted_at)
    remove_column(:document_homes_matter_researches, :permanent_deleted_at)    
  end

  def self.down
    # add removed columns
    add_column(:document_homes_matter_researches, :company_id,:integer) 
    add_column(:document_homes_matter_researches, :updated_at,:timestamp) 
    add_column(:document_homes_matter_researches, :created_at,:timestamp) 
    add_column(:document_homes_matter_researches, :deleted_at,:timestamp) 
    add_column(:document_homes_matter_researches, :permanent_deleted_at,:timestamp)     
  end
end
