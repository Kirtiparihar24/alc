class CreateBudgetPeriods < ActiveRecord::Migration
  def self.up
    create_table :budget_periods,:force=>true do |t|
      t.date "from_period"
      t.date "to_period"
      t.integer "budget_amt"
      t.integer "cgc_company_id"
      t.timestamps
    end
     add_index :budget_periods, :cgc_company_id
  end

  def self.down
    drop_table :budget_periods
  end
end
