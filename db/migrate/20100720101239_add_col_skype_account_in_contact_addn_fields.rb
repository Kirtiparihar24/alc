class AddColSkypeAccountInContactAddnFields < ActiveRecord::Migration
  def self.up
     add_column :contact_additional_fields, :skype_account, :string, :limit => 64
  end

  def self.down
    remove_column :contact_additional_fields, :skype_account
  end
  
end
