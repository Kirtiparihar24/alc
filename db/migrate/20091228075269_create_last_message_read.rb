 class CreateLastMessageRead < ActiveRecord::Migration
  def self.up
      create_table :last_message_read do |t|
          t.string :message
       end
  end

  def self.down
    drop_table :last_message_read
  end
end
