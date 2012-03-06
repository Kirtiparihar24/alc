class CheckInCheckOut < ActiveRecord::Migration
  def self.up
      add_column :document_homes, :checked_in_by_employee_user_id, :integer
      add_column :document_homes, :checked_in_at, :datetime
   end

  def self.down
      remove_column :document_homes, :checked_in_by_employee_user_id
      remove_column :document_homes, :checked_in_at
  end
end
