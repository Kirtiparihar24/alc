class ChangeDecimalFieldTandExpense < ActiveRecord::Migration
  def self.up
    change_column :time_entries, :actual_duration, :decimal,:precision => 14, :scale => 2,:null => false
    change_column :time_entries, :billing_percent, :decimal,:precision => 14, :scale => 2
    change_column :time_entries, :actual_activity_rate, :decimal,:precision => 14, :scale => 2
    change_column :time_entries, :final_billed_amount, :decimal,:precision => 16, :scale => 2

    #expense table
    change_column  :expense_entries, :billing_percent,   :decimal,   :precision => 14, :scale => 2
    change_column  :expense_entries, :expense_amount,    :decimal,   :precision => 14, :scale => 2, :null => false
    change_column  :expense_entries, :final_expense_amount, :decimal, :precision => 16, :scale => 2

  end

  def self.down
    change_column :time_entries, :actual_duration, :decimal,:precision => 12, :scale => 2, :null => false
    change_column :time_entries, :billing_percent, :decimal,:precision => 12, :scale => 2
    change_column :time_entries, :actual_activity_rate, :decimal,:precision => 12, :scale => 2
    change_column :time_entries, :final_billed_amount, :decimal,:precision => 12, :scale => 2

    #expense table
    change_column  :expense_entries, :billing_percent,  :decimal,    :precision => 12, :scale => 2
    change_column  :expense_entries, :expense_amount,   :decimal,   :precision => 12, :scale => 2, :null => false
    change_column  :expense_entries, :final_expense_amount, :decimal, :precision => 12, :scale => 2
  end
end
