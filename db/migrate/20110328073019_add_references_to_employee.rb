class AddReferencesToEmployee < ActiveRecord::Migration
  def self.up
    add_column :employees, :reference1, :string
    add_column :employees, :reference2, :string
  end

  def self.down
    remove_column :employees, :reference1
    remove_column :employees, :reference2
  end
end
