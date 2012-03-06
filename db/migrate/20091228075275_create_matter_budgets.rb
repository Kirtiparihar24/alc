class CreateMatterBudgets < ActiveRecord::Migration
  def self.up
    create_table :matter_budgets,:force=>true do |t|
      t.integer 'matter_id'
      t.integer 'company_id'
      t.string  'month'
      t.integer 'duration'
      t.integer 'matter_budget_category_id'
      t.integer 'estimated'
      t.integer 'cgc_company_id'
      t.integer 'budget_period_id'
      t.timestamps
    end
  end

  def self.down
    drop_table :matter_budgets
  end
end
