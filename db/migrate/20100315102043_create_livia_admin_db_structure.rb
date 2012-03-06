class CreateLiviaAdminDbStructure < ActiveRecord::Migration

  def self.up
 
      create_table "assignments", :force => true do |t|
        t.integer "user_id"
        t.integer "role_id"
        t.datetime "created_at"
        t.datetime "updated_at"
        t.datetime "deleted_at"
      end

      create_table "bdrb_job_queues", :force => true do |t|
        t.text "args"
        t.string "worker_name"
        t.string "worker_method"
        t.string "job_key"
        t.integer "taken"
        t.integer "finished"
        t.integer "timeout"
        t.integer "priority"
        t.datetime "submitted_at"
        t.datetime "started_at"
        t.datetime "finished_at"
        t.datetime "archived_at"
        t.string "tag"
        t.string "submitter_info"
        t.string "runner_info"
        t.string "worker_key"
        t.datetime "scheduled_at"
      end

      create_table "company_temp_licences", :force => true do |t|
        t.integer "company_id"
        t.integer "licence_limit"
        t.integer "created_by_user_id"
        t.datetime "created_at"
        t.datetime "updated_at"
      end

      create_table "departments", :force => true do |t|
        t.integer "parent_id"
        t.string "name"
        t.string "location"
        t.integer "company_id"
        t.datetime "deleted_at"
        t.datetime "created_at"
        t.datetime "updated_at"
      end


      create_table "invoice_details", :force => true do |t|
        t.integer  "company_id", :null => false
        t.integer "invoice_id", :null => false
        t.integer "licence_id", :null => false
        t.integer "product_id", :null => false
        t.datetime "billing_from_date", :null => false
        t.datetime "billing_to_date", :null => false
        t.decimal "total_amount", :precision => 12, :scale => 2, :null => false
        t.decimal "cost", :precision => 12, :scale => 2, :null => false
        t.decimal "count", :precision => 12, :scale => 2, :null => false
        t.datetime "created_at"
        t.datetime "updated_at"
        t.boolean "delta", :default => true, :null => false
        t.datetime "permanent_deleted_at"
        t.datetime "deleted_at"
        t.integer "created_by_user_id"
        t.integer "updated_by_user_id"
        t.integer "status"
        t.datetime "product_purchase_date"
      end

      create_table "invoices", :force => true do |t|
        t.integer "company_id", :null => false
        t.datetime "invoice_date", :null => false
        t.datetime "invoice_from_date"
        t.datetime "invoice_to_date"
        t.decimal "invoice_amount", :precision => 12, :scale => 2, :null => false
        t.string "status"
        t.datetime "created_at"
        t.datetime "updated_at"
        t.boolean "delta", :default => true, :null => false
        t.datetime "permanent_deleted_at"
        t.datetime "deleted_at"
        t.integer "created_by_user_id"
        t.integer "updated_by_user_id"
      end

      create_table "licences", :force => true do |t|
        t.integer "company_id"
        t.integer "product_id"
        t.integer "licence_count"
        t.integer "cost"
        t.datetime "start_date"
        t.datetime "expired_date"
        t.datetime "created_at"
        t.datetime "updated_at"
      end

      create_table "payments", :force => true do |t|
        t.integer "invoice_id", :null => false
        t.string "payment_mode", :null => false
        t.integer "amount", :null => false
        t.string "cheque_no"
        t.datetime "cheque_date"
        t.string "bank_name"
        t.string "branch_name"
        t.string "paypal_account_id"
        t.string "status"
        t.datetime "created_at"
        t.datetime "updated_at"
        t.boolean "delta", :default => true, :null => false
        t.datetime "permanent_deleted_at"
        t.datetime "deleted_at"
        t.integer "created_by_user_id"
        t.integer "updated_by_user_id"
        t.datetime "payment_date", :null => false
      end

      create_table "product_dependents", :force => true do |t|
        t.integer "product_id"
        t.integer "parent_id"
        t.datetime "created_at"
        t.datetime "updated_at"
        t.datetime "deleted_at"
      end

      create_table "product_licence_details", :force => true do |t|
        t.integer "lawyers_id"
        t.integer "product_licence_id"
        t.datetime "start_date"
        t.datetime "expired_date"
        t.integer "status"
        t.datetime "created_at"
        t.datetime "updated_at"
        t.integer "user_id"
        t.datetime "deleted_at"
      end

      create_table "product_licences", :force => true do |t|
        t.integer "product_id"
        t.integer "company_id"
        t.string "licence_key"
        t.float "licence_cost"
        t.datetime "start_at"
        t.datetime "end_at"
        t.datetime "deleted_at"
        t.integer "created_by_user_id"
        t.integer "updated_by_user_id"
        t.datetime "created_at"
        t.datetime "updated_at"
        t.integer "status", :default => 0
        t.integer "licence_id"
        t.integer "licence_type", :default => 0
      end

      create_table "product_subproducts", :force => true do |t|
        t.integer "product_id"
        t.integer "subproduct_id"
        t.datetime "deleted_at"
        t.datetime "created_at"
        t.datetime "updated_at"
        t.datetime "permanent_deleted_at"
        t.integer "created_by_user_id"
        t.integer "updated_by_user_id"
      end

      create_table "products", :force => true do |t|
        t.string "name",:limit => 64, :default => "",   :null => false
        t.datetime "created_at"
        t.datetime "updated_at"
        t.boolean "delta", :default => true, :null => false
        t.datetime "permanent_deleted_at"
        t.datetime "deleted_at"
        t.integer "created_by_user_id"
        t.integer "updated_by_user_id"
        t.integer "cost", :null => false
        t.string "description"
      end

      create_table "roles", :force => true do |t|
        t.string "name"
        t.datetime "created_at"
        t.datetime "updated_at"
        t.integer "company_id", :default => 100
        t.datetime "deleted_at"
      end

      create_table "subproduct_assignments", :force => true do |t|
        t.integer "user_id"
        t.integer "subproduct_id"
        t.integer "employee_user_id"
        t.datetime "created_at"
        t.datetime "updated_at"
        t.integer "product_licence_id"
        t.integer "company_id"
        t.datetime "deleted_at"
      end

      create_table "subproducts", :force => true do |t|
        t.string "name", :limit => 64, :default => "",   :null => false
        t.datetime "created_at"
        t.datetime "updated_at"
        t.boolean "delta", :default => true, :null => false
        t.datetime "permanent_deleted_at"
        t.datetime "deleted_at"
        t.integer "created_by_user_id"
        t.integer "updated_by_user_id"
      end  

      add_column :companies, :billingdate, :datetime
      add_column :companies, :sales_rep, :string
      add_column :companies, :sales_rep_type, :string
      add_column :companies, :comm_payable, :boolean
      add_column :companies, :temp_licence_limit, :integer, :default => 10
      add_column :companies, :notes, :string, :limit => 2000

      add_column :users, :parent_id, :integer
      add_column :users, :department_id, :integer
      add_column :users, :security_question, :text
      add_column :users, :security_answer, :text

      execute "ALTER TABLE employees drop column designation"

      add_column :employees, :first_name, :string, :limit => 32
      add_column :employees, :last_name, :string, :limit => 32
      add_column :employees, :email, :string, :limit => 64
      add_column :employees, :phone, :string, :limit => 32
      add_column :employees, :mobile, :string, :limit => 32
      add_column :employees, :parent_id, :integer
      add_column :employees, :department_id, :integer
      add_column :employees, :designation, :string, :limit => 64

      execute "SELECT setval('company_lookups_id_seq', (SELECT MAX(id) FROM company_lookups)+1);"

  end
  
  def self.down
    
      drop_table "assignments"
      drop_table "bdrb_job_queues"
      drop_table "company_temp_licences"
      drop_table "invoice_details"
      drop_table "invoices"
      drop_table "licences"
      drop_table "payments"
      drop_table "product_dependents"
      drop_table "product_licence_details"
      drop_table "product_licences"
      drop_table "product_subproducts"
      drop_table "products"
      drop_table "roles"
      drop_table "subproduct_assignments"
      drop_table "subproducts"

      remove_column :companies, :billingdate
      remove_column :companies, :sales_rep
      remove_column :companies, :sales_rep_type
      remove_column :companies, :comm_payable
      remove_column :companies, :temp_licence_limit
      remove_column :companies, :notes

      remove_column :users, :parent_id
      remove_column :users, :department_id
      remove_column :users, :security_question
      remove_column :users, :security_answer


      remove_column :employees, :first_name
      remove_column :employees, :last_name
      remove_column :employees, :email
      remove_column :employees, :phone
      remove_column :employees, :mobile
      remove_column :employees, :parent_id
      remove_column :employees, :department_id
      remove_column :employees, :designation

      add_column :employees, :designation, :string, :limit => 1

  end
end
