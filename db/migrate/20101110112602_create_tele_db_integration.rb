class CreateTeleDbIntegration < ActiveRecord::Migration
 def self.up
  create_table "Users", :force => true ,:id=>false do |t|
    t.integer  :ID
    t.string   :FirstName,           :limit => 50
    t.string   :LastName,            :limit => 50
    t.string   :UserName,            :limit => 100
    t.string   :Password
    t.integer  :Priority
  end

  #add_index "users", ["email"], :name => "index_users_on_email"
  #add_index "users", ["last_request_at"], :name => "index_users_on_last_request_at"
  #add_index "users", ["perishable_token"], :name => "index_users_on_perishable_token"
  #add_index "users", ["persistence_token"], :name => "index_users_on_remember_token"
  #add_index "users", ["username", "deleted_at"], :name => "index_users_on_username_and_deleted_at", :unique => true



#
  create_table "Employees", :force => true, :id=>false do |t|
    t.integer  :ID
    t.string "FirstName", :limit => 50
    t.string "LastName", :limit => 50
    t.string "Email", :limit => 100
    t.string "Phone", :limit => 32
    t.string  "Mobile", :limit => 32
    t.string  "RegisteredNumber", :limit => 32
    t.integer "ParentID"
    t.integer "DepartmentID"
    t.datetime "CreatedAt"
    t.datetime "UpdatedAt"
    t.integer  "salutation"
    t.date     "Birthdate"
    t.text     "Description"
    t.integer  "UsersID"
    t.integer  "BillingRate"
    t.integer  "RoleID"
    t.integer  "CompanyID",                        :default => 100,   :null => false
    t.datetime "DeletedAt"
    t.datetime "PermanentDeletedAt"
    t.integer "DesignationID"
    t.integer "CreatedByUserID"
    t.string  "AccessCode", :limit => 32
  end

  create_table "Roles", :force => true, :id=>false do |t|
    t.integer  :ID
    t.string "Name"
  end

  create_table "Role", :force => true, :id=>false do |t|
    t.integer  :ID
    t.integer "UserID"
    t.integer "RoleID"
  end

  create_table "ServiceProviders", :force => true, :id=>false do |t|
    t.integer  :ID
    t.datetime "CreatedAt"
    t.datetime "UpdatedAt"
    t.boolean  "Deleted",              :default => false
    t.date     "Birthdate"
    t.text     "Description"
    t.integer  "UserID", :null => false
    t.integer  "CompanyID",           :default => 100,   :null => false
    t.datetime "DeletedAt"
    t.integer "CreatedByUserID"
  end


  create_table "ServiceProviderEmployeeMappings", :force => true, :id=>false do |t|
    t.integer  :ID
    t.integer  "ServiceProvidersID"
    t.integer  "EmployeeUserID"
    t.integer  "Priority"
    t.integer  "Status"
    t.datetime "DeletedAt"
    t.datetime "CreatedAt"
    t.datetime "UpdatedAt"
    t.datetime "PermanentDeletedAt"
    t.integer "CreatedByUserID"
  end
#
#
#  create_table :clusters, :force => true do |t|
#      t.string 'cluster_no',:limit=>15
#      t.text 'description'
#      #t.timestamps
#    end
 end

 def self.down
   drop_table :Users
   drop_table :Employees
   drop_table :Roles
   drop_table :Role
   drop_table :ServiceProviders
   drop_table :ServiceProviderEmployeeMappings
 end
end
