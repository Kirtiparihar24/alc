class NormalizeTimeEntry < ActiveRecord::Migration
  def self.up
    add_column(:time_entries, :is_billable, :boolean,:default => false)
    add_column(:time_entries, :is_internal, :boolean,:default => true)
    # retrive all time entries
    @timeentry = Physical::Timeandexpenses::TimeEntry.all 
    @timeentry.each do |timeentry|
      # set values for is_billable if billable_type is 1 then is_billable true else false
      if timeentry.billable_type == 1
        timeentry.is_billable = '1'
      else
        timeentry.is_billable = '0'
      end
      
      # set values for is_internal if accounted_for_type is 8 then is_internal true else false
      if timeentry.accounted_for_type == 8
        timeentry.is_internal = '1'
      else  
        timeentry.is_internal = '0'
      end
      timeentry.save(false)
    end
    # remove old column
    remove_column(:time_entries, :billable_type)
    remove_column(:time_entries, :accounted_for_type)
    #remove unrequired column
    remove_column(:time_entries, :billing_amount)
    rename_column(:time_entries, :std_bill_rate, :activity_rate)
    rename_column(:time_entries, :actual_bill_rate, :actual_activity_rate)
  end

  
  def self.down
    add_column(:time_entries, :billable_type, :integer)
    add_column(:time_entries, :accounted_for_type, :integer)
    @timeentry = Physical::Timeandexpenses::TimeEntry.all 
    @timeentry.each do |timeentry|
      # reset values for billable_type if is_billable is true then billable_type=1 else 2
      if timeentry.is_billable
        timeentry.billable_type = 1
      else
        timeentry.billable_type = 2
      end
      
      # reset values for accounted_for_type if is_internal is true then accounted_for_type=8 else 7
      if timeentry.is_internal
        timeentry.accounted_for_type = 8
      else  
        timeentry.accounted_for_type = 7
      end      
      timeentry.save(false)
    end
    
    add_column(:time_entries, :billing_amount,:decimal,:precision => 12,:scale=>2)
    rename_column(:time_entries, :activity_rate, :std_bill_rate)
    rename_column(:time_entries, :actual_activity_rate, :actual_bill_rate)    
    # remove newly added column
    remove_column(:time_entries, :is_billable)
    remove_column(:time_entries, :is_internal)
  end
end
