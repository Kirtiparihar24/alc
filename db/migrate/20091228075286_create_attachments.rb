class CreateAttachments < ActiveRecord::Migration
  def self.up
    create_table :attachments do |t|
      t.integer 'attachable_id'
      t.string 'attachable_type'
      t.string 'type'
      t.string 'data_file_name'
      t.string 'data_content_type'
      t.string 'data_file_size'
      t.string 'data_name'
      t.string 'data_description'      
      t.timestamp 'deleted_at'
      t.timestamps
    end
  end

  def self.down
    drop_table :attachments
  end
end
