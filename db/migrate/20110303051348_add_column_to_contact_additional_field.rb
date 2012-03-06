class AddColumnToContactAdditionalField < ActiveRecord::Migration
  def self.up
    add_column :contact_additional_fields, :business_phone1_type, :integer
    add_column :contact_additional_fields, :business_phone2_type, :integer
  end

  def self.down
    remove_column :contact_additional_fields, :business_phone2_type
    remove_column :contact_additional_fields, :business_phone1_type
  end
end
