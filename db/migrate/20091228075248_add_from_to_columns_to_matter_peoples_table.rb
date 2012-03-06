class AddFromToColumnsToMatterPeoplesTable < ActiveRecord::Migration
  def self.up
    add_column :matter_peoples, :member_start_date, :date
    add_column :matter_peoples, :member_end_date, :date
  end

  def self.down
    remove_column :matter_peoples, :member_start_date
    remove_column :matter_peoples, :member_end_date
  end
end
