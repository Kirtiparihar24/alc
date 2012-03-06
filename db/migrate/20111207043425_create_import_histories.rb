class CreateImportHistories < ActiveRecord::Migration
  def self.up
    create_table :import_histories do |t|
      t.string :original_filename
      t.string :error_filename
      t.text :valid_record_ids
      t.string :module_type
      t.integer :valid_records
      t.integer :invalid_records
      t.integer :parent_id
      t.integer :company_id
      t.integer :employee_user_id
      t.integer :owner_id

      t.timestamps
    end
  end

  def self.down
    drop_table :import_histories
  end
end
