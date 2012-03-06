class AddContactStageIdColForContactTable < ActiveRecord::Migration
  def self.up
    add_column :contacts, :contact_stage_id, :integer
  end

  def self.down
    remove_column :contacts, :contact_stage_id
  end
end
