class ContactAdditionalFields < ActiveRecord::Migration
  def self.up
    create_table    :contact_additional_fields,:force=>true do |t|
      t.string      :business_street              ,:limit => 64
      t.string      :business_city                ,:limit => 64
      t.string      :business_state               ,:limit => 64
      t.string      :business_country             ,:limit => 64
      t.string      :business_postal_code         ,:limit => 64
      t.string      :business_fax                 ,:limit => 32
      t.string      :business_phone               ,:limit => 32
      t.string      :businessphone2               ,:limit => 32
      t.string      :assistants_name              ,:limit => 64
      t.string      :assistants_phone             ,:limit => 32
      t.string      :professional_expertise       ,:limit => 64
      t.string      :partners_name                ,:limit => 64
      t.datetime    :partners_birthday
      t.string      :undergraduate_schools        ,:limit => 64
      t.string      :graduate_school              ,:limit => 64
      t.integer    :year_graduated
      t.string      :graduate_degree              ,:limit => 64
      t.string      :supervisors_title            ,:limit => 64
      t.string      :supervisors_email            ,:limit => 64
      t.string     :supervisors_phone_number      ,:limit => 32
      t.string      :religion                     ,:limit => 64
      t.datetime    :birthday
      t.string      :birth_country                ,:limit => 64
      t.string      :children                     ,:limit => 64
      t.string      :gender                       ,:limit => 32
      t.string      :hobby                        ,:limit => 64
      t.datetime    :first_contact
      t.datetime    :date_of_first_deal
      t.string      :current_service_provider     ,:limit => 64
      t.datetime    :next_call_back_date
      t.string      :referred_by                  ,:limit => 64
      t.string      :spouse_name                  ,:limit => 64
      t.datetime    :spouse_birthday
      t.string      :linked_in_account            ,:limit => 64
      t.string      :twitter_account              ,:limit => 64
      t.string      :facebook_account             ,:limit => 64
      t.string      :association_1                ,:limit => 64
      t.string      :association_2                ,:limit => 64
      t.integer     :contact_id                   ,:limit => 64
      t.integer     :company_id                   ,:null => false
      t.datetime    :permanent_deleted_at
      t.integer     :created_by_user_id
      t.integer     :updated_by_user_id
      t.datetime    :deleted_at
      t.timestamps
    end
  end

  def self.down
    drop_table :contact_additional_fields
  end
  
end
