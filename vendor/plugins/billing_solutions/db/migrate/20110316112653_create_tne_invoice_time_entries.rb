class CreateTneInvoiceTimeEntries < ActiveRecord::Migration
  def self.up
    create_table :tne_invoice_time_entries do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "employee_user_id",                                                     :null => false
    t.integer  "created_by_user_id"
    t.integer  "activity_type",                                                        :null => false
    t.text     "description",                                                          :null => false
    t.date     "time_entry_date",                                                      :null => false
    t.datetime "start_time"
    t.datetime "end_time"
    t.decimal  "actual_duration",      :precision => 14, :scale => 2,                  :null => false
    t.boolean  "is_billable",:default=>false
    t.integer  "billing_method_type"
    t.decimal  "billing_percent",      :precision => 14, :scale => 2
    t.decimal  "billing_amount",       :precision => 14, :scale => 2
    t.decimal  "activity_rate",        :precision => 14, :scale => 2
    t.decimal  "actual_activity_rate",     :precision => 14, :scale => 2
    t.decimal  "final_billed_amount",  :precision => 14, :scale => 2
    t.boolean  "is_internal",:default=>false
    t.integer  "contact_id"
    t.integer  "matter_id"
    t.integer  "company_id",                                          :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "updated_by_user_id"
    t.integer  "matter_task_id"
    t.integer  "tne_invoice_id"
    t.integer  "tne_invoice_detail_id"
    t.string "status"
    end
  end

  def self.down
    drop_table :tne_invoice_time_entries
  end
end

