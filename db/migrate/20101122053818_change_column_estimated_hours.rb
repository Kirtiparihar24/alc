class ChangeColumnEstimatedHours < ActiveRecord::Migration
  def self.up
    #change_column :opportunities, :estimated_hours, :decimal, :precision => 6, :scale => 2
	add_column :opportunities, :temp_estimated_hrs,:numeric,:decimal,:precision =>6, :scale =>2

	execute "update opportunities a set temp_estimated_hrs=(select estimated_hours from opportunities b where a.id=b.id)"

	remove_column :opportunities , :estimated_hours

	add_column :opportunities, :estimated_hours, :decimal, :precision=> 6, :scale =>2

	execute "update opportunities a set estimated_hours =(select temp_estimated_hrs from opportunities b where a.id=b.id)"

	remove_column :opportunities, :temp_estimated_hrs
  end

  def self.down
    #change_column :opportunities, :estimated_hours, :integer
  end
end
