class AddMatterPeopleIdToTAndE < ActiveRecord::Migration
  def self.up
    add_column :time_entries, :matter_people_id, :integer
    add_column :expense_entries, :matter_people_id, :integer
    add_column :tne_invoice_time_entries, :matter_people_id, :integer
    add_column :tne_invoice_expense_entries, :matter_people_id, :integer

    add_column :matter_peoples, :allow_time_entry, :boolean, :default => false

  end

  def self.down
    remove_column :time_entries, :matter_people_id
    remove_column :expense_entries, :matter_people_id
    remove_column :tne_invoice_time_entries, :matter_people_id
    remove_column :tne_invoice_expense_entries, :matter_people_id
    
    remove_column :matter_peoples, :allow_time_entry
  end
end
