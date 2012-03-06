class AddBusinessContactFieldsToMatterPeoplesTable < ActiveRecord::Migration
  def self.up
    add_column :matter_peoples, :salutation, :string, :limit => 16
    add_column :matter_peoples, :last_name, :string, :limit => 32
    add_column :matter_peoples, :notes, :string, :limit => 255
    add_column :matter_peoples, :city, :string, :limit => 64
    add_column :matter_peoples, :state, :string, :limit => 64
    add_column :matter_peoples, :zip, :string, :limit => 16
    add_column :matter_peoples, :country, :string, :limit => 64
    add_column :matter_peoples, :alternate_email, :string, :limit => 64    
    add_column :matter_peoples, :mobile, :string, :limit => 16
    add_column :matter_peoples, :role_text, :string, :limit => 64
    add_column :matter_peoples, :billing_by, :string, :limit => 64
    add_column :matter_peoples, :retainer_amount, :string, :limit => 64
    add_column :matter_peoples, :not_to_exceed_amount, :string, :limit => 64
    add_column :matter_peoples, :min_trigger_amount, :string, :limit => 64
    add_column :matter_peoples, :fixed_rate_amount, :string, :limit => 64
    add_column :matter_peoples, :additional_details, :string
    add_column :matter_peoples, :added_to_contact, :boolean    
  end

  def self.down
    remove_column :matter_peoples, :salutation
    remove_column :matter_peoples, :last_name
    remove_column :matter_peoples, :notes
    remove_column :matter_peoples, :city
    remove_column :matter_peoples, :state
    remove_column :matter_peoples, :zip
    remove_column :matter_peoples, :country
    remove_column :matter_peoples, :alternate_email
    remove_column :matter_peoples, :mobile
    remove_column :matter_peoples, :role_text
    remove_column :matter_peoples, :billing_by
    remove_column :matter_peoples, :retainer_amount
    remove_column :matter_peoples, :not_to_exceed_amount
    remove_column :matter_peoples, :min_trigger_amount
    remove_column :matter_peoples, :fixed_rate_amount
    remove_column :matter_peoples, :additional_details
    remove_column :matter_peoples, :added_to_contact
  end
end
