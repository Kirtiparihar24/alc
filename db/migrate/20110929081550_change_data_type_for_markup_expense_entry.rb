class ChangeDataTypeForMarkupExpenseEntry < ActiveRecord::Migration
  def self.up
    change_table :expense_entries do |t|
      t.change :markup, :float
    end
  end

  def self.down
    change_table :expense_entries do |t|
      t.change :markup, :integer
    end
  end
end
