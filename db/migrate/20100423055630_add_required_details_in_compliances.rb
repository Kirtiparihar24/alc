class AddRequiredDetailsInCompliances < ActiveRecord::Migration
  def self.up
    add_column :compliances , :required_for_items, :string, :limit=>10
  end

  def self.down
    remove_column :compliances, :required_for_items
  end
end
