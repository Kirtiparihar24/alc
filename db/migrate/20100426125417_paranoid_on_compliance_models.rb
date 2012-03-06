class ParanoidOnComplianceModels < ActiveRecord::Migration
  def self.up
    add_column :compliances , :deleted_at, :timestamp
    add_column :compliance_items , :deleted_at, :timestamp
    add_column :compliance_trails , :deleted_at, :timestamp
    add_column :authorities , :deleted_at, :timestamp
    add_column :compliance_types , :deleted_at, :timestamp
  end

  def self.down
    remove_column :compliances, :deleted_at
    remove_column :compliance_items, :deleted_at
    remove_column :compliance_trails, :deleted_at
    remove_column :authorities, :deleted_at
    remove_column :compliance_types, :deleted_at
  end
end
