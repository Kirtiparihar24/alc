class AddColumnToContactAdditionalFields < ActiveRecord::Migration
  def self.up
    add_column :contact_additional_fields, :others_1, :string
    add_column :contact_additional_fields, :others_2, :string
    add_column :contact_additional_fields, :others_3, :string
    add_column :contact_additional_fields, :others_4, :string
    add_column :contact_additional_fields, :others_5, :string
    add_column :contact_additional_fields, :others_6, :string
  end

  def self.down
    remove_column :contact_additional_fields, :others_1
    remove_column :contact_additional_fields, :others_2
    remove_column :contact_additional_fields, :others_3
    remove_column :contact_additional_fields, :others_4
    remove_column :contact_additional_fields, :others_5
    remove_column :contact_additional_fields, :others_6
  end
end
