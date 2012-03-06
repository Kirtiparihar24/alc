class AddMatterDateToMatters < ActiveRecord::Migration
  def self.up
    add_column :matters, :matter_date, :date
  end

  def self.down
    remove_column :matters, :matter_date
  end
end
