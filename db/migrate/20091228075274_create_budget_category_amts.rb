class CreateBudgetCategoryAmts < ActiveRecord::Migration
  def self.up
    create_table :budget_category_amts,:force=>true do |t|
      t.integer 'matter_budget_category_id'
      t.integer 'budget_period_id'
      t.integer 'estimated_amt'
      t.timestamps
   
    end
  end

  def self.down
    drop_table :budget_category_amts
  end
end
