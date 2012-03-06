class AddEmployeeUserIdInDocumentHomes < ActiveRecord::Migration
  def self.up
    add_column :document_homes, :employee_user_id, :integer
  end

  def self.down
    remove_column :document_homes, :employee_user_id
  end
end
