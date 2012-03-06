class UpdateMatterRetainerDateColumn < ActiveRecord::Migration
  def self.up
    change_column :matter_retainers,	:date, :datetime
  end

  def self.down
    change_column :matter_retainers,	:datetime, :date
  end
end
