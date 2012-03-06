class AlterAttachments < ActiveRecord::Migration
  def self.up
    add_column :attachments, :active, :boolean, :default=>true    
  end

  def self.down
    remove_column :attachments, :active
  end
end
