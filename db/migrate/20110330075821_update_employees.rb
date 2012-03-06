class UpdateEmployees < ActiveRecord::Migration
  def self.up
     change_column :employees, :email ,:string,:limit => 255
  end

  def self.down
    change_column :employees, :email ,:string ,:limit => 32
  end
end
