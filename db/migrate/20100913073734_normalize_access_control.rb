class NormalizeAccessControl < ActiveRecord::Migration
  def self.up
    # remove unused columns
    remove_column(:access_controls, :access_right)
    remove_column(:access_controls, :is_edit)
    remove_column(:access_controls, :is_view)
    
    rename_table(:access_controls, :document_access_controls)
  end

  def self.down
    # add removed columns
    add_column(:document_access_controls, :access_right ,:string)
    add_column(:document_access_controls, :is_edit , :boolean)
    add_column(:document_access_controls, :is_view , :boolean)
    
    # rename table with old name
    rename_table(:document_access_controls, :access_controls)
  end
end
