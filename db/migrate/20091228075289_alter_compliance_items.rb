class AlterComplianceItems < ActiveRecord::Migration
  def self.up
    add_column :compliance_items, :time_before_due, :string
  end

  def self.down
    remove_column :compliance_items, :time_before_due
  end
end
