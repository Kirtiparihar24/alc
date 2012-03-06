class NormalizeExpenseEntry < ActiveRecord::Migration
  def self.up
    rename_column(:expense_entries, :related_time_entry, :time_entry_id)
    add_column(:expense_entries, :is_billable, :boolean,:default => false)
    add_column(:expense_entries, :is_internal, :boolean,:default => true)
    @expenseentry = Physical::Timeandexpenses::ExpenseEntry.all 
    @expenseentry.each do |expenseentry|
      # set values for is_billable if billable_type is 1 then is_billable true else false
      if expenseentry.billable_type == 1
        expenseentry.is_billable = '1'
      else
        expenseentry.is_billable = '0'
      end
      
      # set values for is_internal if accounted_for_type is 8 then is_internal true else false
      if expenseentry.accounted_for_type == 8
        expenseentry.is_internal = '1'
      else  
        expenseentry.is_internal = '0'
      end
      expenseentry.save(false)
    end
    # remove old column
    remove_column(:expense_entries, :billable_type)
    remove_column(:expense_entries, :accounted_for_type)    
    #remove unrequired column
    remove_column(:expense_entries, :billing_amount)    
    
  end

  def self.down
    rename_column(:expense_entries, :time_entry_id, :related_time_entry)
    add_column(:expense_entries, :billable_type, :integer)
    add_column(:expense_entries, :accounted_for_type, :integer)
    # add removed column
    add_column(:expense_entries, :billing_amount, :decimal, :precision => 12)
    
    @expenseentry = Physical::Timeandexpenses::ExpenseEntry.all 
    @expenseentry.each do |expenseentry|
      # reset values for billable_type if is_billable is true then billable_type=1 else 2
      if expenseentry.is_billable
        expenseentry.billable_type = 1
      else
        expenseentry.billable_type = 2
      end
      
      # reset values for accounted_for_type if is_internal is true then accounted_for_type=8 else 7
      if expenseentry.is_internal
        expenseentry.accounted_for_type = 8
      else  
        expenseentry.accounted_for_type = 7
      end      
      expenseentry.save(false)
    end    

    # remove newly added column
    remove_column(:expense_entries, :is_billable)
    remove_column(:expense_entries, :is_internal)    

  end
  
end
