class AddLastMessageReadColumns < ActiveRecord::Migration
  def self.up
     add_column(:last_message_read, :company_id, :integer)
  end

  def self.down
    remove_column(:last_message_read, :company_id, :integer)
  end
end
