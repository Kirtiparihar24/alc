class AlterRemarkMatterBilling < ActiveRecord::Migration
  def self.up
    change_table :matter_billings do |t|
      t.change :remarks, :text
    end
  end

  def self.down
    change_table :matter_billings do |t|
      t.change :remarks, :varchar, :limit => 255
    end
  end
end
