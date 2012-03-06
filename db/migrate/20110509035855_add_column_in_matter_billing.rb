class AddColumnInMatterBilling < ActiveRecord::Migration
  def self.up
    add_column :matter_billings, :tne_invoice_id, :integer
    add_column :matter_billings, :automate_entry, :boolean, :default=>false
    MatterBilling.update_all("automate_entry= false")
  end

  def self.down
    remove_column :matter_billings, :tne_invoice_id
    remove_column :matter_billings, :automate_entry
  end
end
