class AddWorkSubtypeComplexityIdToUserWorkSubtype < ActiveRecord::Migration
  def self.up
    add_column :user_work_subtypes, :work_subtype_complexity_id, :integer
  end

  def self.down
    remove_column :user_work_subtypes, :work_subtype_complexity_id
  end
end
