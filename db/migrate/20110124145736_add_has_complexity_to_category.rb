class AddHasComplexityToCategory < ActiveRecord::Migration
  def self.up
    add_column :categories, :has_complexity, :boolean,:default => false
  end

  def self.down
    remove_column :categories, :has_complexity
  end
end
