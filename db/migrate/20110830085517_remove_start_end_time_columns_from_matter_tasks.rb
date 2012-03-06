class RemoveStartEndTimeColumnsFromMatterTasks < ActiveRecord::Migration
  def self.up
    remove_column :matter_tasks, :start_time
    remove_column :matter_tasks, :end_time
  end

  def self.down
    add_column :matter_tasks, :start_time, :time 
    add_column :matter_tasks, :end_time, :time 
    MatterTask.all.each do|mt|
      time_zone = mt.assigned_to_user.time_zone || "UTC"
      stime = mt.start_date.in_time_zone(time_zone).strftime("%H:%M:%S")
      etime = mt.end_date.in_time_zone(time_zone).strftime("%H:%M:%S")
      ActiveRecord::Base.connection.execute "UPDATE matter_tasks SET start_time = '#{stime}', end_time = '#{etime}' WHERE id = #{mt.id}"
    end
  end
end

