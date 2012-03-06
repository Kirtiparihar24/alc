class DynamicLabels < ActiveRecord::Migration
  def self.up
    create_table :dynamic_labels do |t|
      t.integer 'company_id'
      t.string 'file_name'
    end
  end

  def self.down
    drop_table :dynamic_labels
  end
end
