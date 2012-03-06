class CreateTneInvoiceExpenseEntries < ActiveRecord::Migration
  def self.up
    create_table :tne_invoice_expense_entries do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "employee_user_id"
    t.integer  "created_by_user_id"
    t.integer  "expense_type"
    t.integer  "time_entry_id"
    t.text     "description",                                                          :null => false
    t.date     "expense_entry_date",                                                   :null => false
    t.integer  "billing_method_type"
    t.decimal  "billing_percent",      :precision => 14, :scale => 2
    t.decimal  "expense_amount",       :precision => 14, :scale => 2,                  :null => false
    t.decimal  "final_expense_amount", :precision => 14, :scale => 2
    t.integer  "contact_id"
    t.integer  "matter_id"
    t.integer  "company_id",                                          :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "updated_by_user_id"
    t.string  "status", :default=>'Open'
    t.integer "matter_task_id"
    t.boolean "is_billable", :default => false
    t.boolean :is_internal, :default => true
    t.integer :tne_invoice_id
    t.integer :tne_invoice_detail_id
    t.string "status"
    end
  end

  def self.down
    drop_table :tne_invoice_expense_entries
  end
end
