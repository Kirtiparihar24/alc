class AddColoumnZimbraTimezone < ActiveRecord::Migration
  def self.up
    add_column(:users, :zimbra_time_zone, :string)
  end

  def self.down
    remove_column(:users, :zimbra_time_zone)
  end
end
