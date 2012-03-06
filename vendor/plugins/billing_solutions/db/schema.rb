# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110328150106) do

  create_table "Employees", :id => false, :force => true do |t|
    t.integer  "ID"
    t.string   "FirstName",          :limit => 50
    t.string   "LastName",           :limit => 50
    t.string   "Email",              :limit => 100
    t.string   "Phone",              :limit => 32
    t.string   "Mobile",             :limit => 32
    t.string   "RegisteredNumber",   :limit => 32
    t.integer  "ParentID"
    t.integer  "DepartmentID"
    t.datetime "CreatedAt"
    t.datetime "UpdatedAt"
    t.integer  "salutation"
    t.date     "Birthdate"
    t.text     "Description"
    t.integer  "UsersID"
    t.integer  "BillingRate"
    t.integer  "RoleID"
    t.integer  "CompanyID",                         :default => 100, :null => false
    t.datetime "DeletedAt"
    t.datetime "PermanentDeletedAt"
    t.integer  "DesignationID"
    t.integer  "CreatedByUserID"
    t.string   "AccessCode",         :limit => 32
  end

  create_table "Role", :id => false, :force => true do |t|
    t.integer "ID"
    t.integer "UserID"
    t.integer "RoleID"
  end

  create_table "Roles", :id => false, :force => true do |t|
    t.integer "ID"
    t.string  "Name"
  end

  create_table "ServiceProviderEmployeeMappings", :id => false, :force => true do |t|
    t.integer  "ID"
    t.integer  "ServiceProvidersID"
    t.integer  "EmployeeUserID"
    t.integer  "Priority"
    t.integer  "Status"
    t.datetime "DeletedAt"
    t.datetime "CreatedAt"
    t.datetime "UpdatedAt"
    t.datetime "PermanentDeletedAt"
    t.integer  "CreatedByUserID"
  end

  create_table "ServiceProviders", :id => false, :force => true do |t|
    t.integer  "ID"
    t.datetime "CreatedAt"
    t.datetime "UpdatedAt"
    t.boolean  "Deleted",         :default => false
    t.date     "Birthdate"
    t.text     "Description"
    t.integer  "UserID",                             :null => false
    t.integer  "CompanyID",       :default => 100,   :null => false
    t.datetime "DeletedAt"
    t.integer  "CreatedByUserID"
  end

  create_table "Users", :id => false, :force => true do |t|
    t.integer "ID"
    t.string  "FirstName", :limit => 50
    t.string  "LastName",  :limit => 50
    t.string  "UserName",  :limit => 100
    t.string  "Password"
    t.integer "Priority"
  end

  create_table "account_contacts", :force => true do |t|
    t.integer  "account_id"
    t.integer  "contact_id"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "priority"
    t.integer  "company_id"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  create_table "accounts", :force => true do |t|
    t.integer  "employee_user_id"
    t.integer  "assigned_to_employee_user_id"
    t.string   "name",                         :limit => 64, :default => "",        :null => false
    t.string   "access",                       :limit => 8,  :default => "Private"
    t.string   "website",                      :limit => 64
    t.string   "toll_free_phone",              :limit => 32
    t.string   "phone",                        :limit => 32
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "email"
    t.boolean  "delta",                                      :default => true,      :null => false
    t.integer  "company_id",                                                        :null => false
    t.datetime "permanent_deleted_at"
    t.datetime "deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.integer  "parent_id"
    t.integer  "primary_contact_id"
  end

  add_index "accounts", ["assigned_to_employee_user_id"], :name => "index_accounts_on_assigned_to"

  create_table "addresses", :force => true do |t|
    t.string   "street"
    t.string   "city"
    t.string   "country"
    t.string   "zipcode"
    t.string   "state"
    t.string   "address_type"
    t.integer  "contact_id"
    t.integer  "account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_id",           :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "assets", :force => true do |t|
    t.string   "data_file_name"
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "attachable_id"
    t.string   "attachable_type"
    t.integer  "company_id",           :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  create_table "attachments", :force => true do |t|
    t.integer  "attachable_id"
    t.string   "attachable_type"
    t.string   "type"
    t.string   "data_file_name"
    t.string   "data_content_type"
    t.string   "data_file_size"
    t.string   "data_name"
    t.string   "data_description"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",            :default => true
  end

  add_index "attachments", ["attachable_type", "attachable_id"], :name => "index_attachments_on_attaachable_type_and_attachable_id"

  create_table "authorities", :force => true do |t|
    t.string   "name",        :limit => 64
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "budget_category_amts", :force => true do |t|
    t.integer  "matter_budget_category_id"
    t.integer  "budget_period_id"
    t.integer  "estimated_amt"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "budget_periods", :force => true do |t|
    t.date     "from_period"
    t.date     "to_period"
    t.integer  "budget_amt"
    t.integer  "cgc_company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "budget_periods", ["cgc_company_id"], :name => "index_budget_periods_on_cgc_company_id"

  create_table "campaign_mails", :force => true do |t|
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at"
    t.integer  "created_by_user_id"
    t.boolean  "deleted",              :default => false
    t.integer  "campaign_id"
    t.text     "content"
    t.text     "subject"
    t.text     "signature"
    t.text     "mail_type"
    t.integer  "company_id",                              :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "updated_by_user_id"
  end

  create_table "campaign_members", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "campaign_id"
    t.integer  "contact_id"
    t.integer  "campaign_member_status_type_id"
    t.text     "response"
    t.date     "first_mailed_date"
    t.date     "responded_date"
    t.date     "reminder_date"
    t.integer  "opportunity_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "phone"
    t.string   "mobile"
    t.string   "fax"
    t.string   "website"
    t.string   "title"
    t.string   "nickname"
    t.integer  "employee_user_id"
    t.integer  "created_by_user_id"
    t.integer  "company_id",                     :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "updated_by_user_id"
    t.string   "bounce_code"
    t.text     "bounce_reason"
  end

  add_index "campaign_members", ["campaign_id"], :name => "index_campaign_members_on_campaign_id"

  create_table "campaigns", :force => true do |t|
    t.datetime "created_at",                                               :null => false
    t.datetime "updated_at"
    t.string   "name",                    :limit => 200,                   :null => false
    t.text     "details"
    t.integer  "campaign_status_type_id"
    t.integer  "parent_id"
    t.integer  "owner_employee_user_id"
    t.integer  "employee_user_id"
    t.integer  "opportunities_count"
    t.date     "starts_on"
    t.date     "ends_on"
    t.datetime "deleted_at"
    t.boolean  "delta",                                  :default => true, :null => false
    t.integer  "company_id",                                               :null => false
    t.datetime "permanent_deleted_at"
    t.integer  "updated_by_user_id"
    t.integer  "created_by_user_id"
  end

  add_index "campaigns", ["campaign_status_type_id"], :name => "index_campaigns_on_campaign_status_type_id"

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "has_complexity", :default => false
  end

  create_table "categories_roles", :id => false, :force => true do |t|
    t.integer "category_id"
    t.integer "role_id"
  end

  create_table "cgc_company_accounts", :force => true do |t|
    t.integer  "cgc_company_id"
    t.integer  "company_id"
    t.integer  "account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cgc_company_accounts", ["cgc_company_id"], :name => "index_cgc_company_accounts_on_cgc_company_id"

  create_table "cluster_users", :force => true do |t|
    t.integer  "user_id"
    t.integer  "cluster_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "clusters", :force => true do |t|
    t.string "name",        :limit => 15
    t.text   "description"
  end

  create_table "comments", :force => true do |t|
    t.integer  "created_by_user_id"
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.boolean  "private"
    t.string   "title",                :default => ""
    t.text     "comment",              :default => ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_id",                           :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.boolean  "is_read"
  end

  create_table "companies", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                       :limit => 200,                     :null => false
    t.text     "about"
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.string   "zimbra_admin_account_email"
    t.string   "zimbra_admin_account_id"
    t.integer  "zimbra_contact_folder_id"
    t.boolean  "is_cgc"
    t.datetime "billingdate"
    t.string   "sales_rep"
    t.string   "sales_rep_type"
    t.boolean  "comm_payable"
    t.integer  "temp_licence_limit",                         :default => 10
    t.string   "notes",                      :limit => 2000
    t.boolean  "last_name_first",                            :default => false, :null => false
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.string   "parent_company"
    t.string   "subsidiary"
    t.text     "general_info"
    t.text     "write_up"
  end

  add_index "companies", ["name"], :name => "companies_name_key", :unique => true

  create_table "company_activity_rates", :force => true do |t|
    t.integer  "activity_type_id"
    t.decimal  "billing_rate",         :precision => 10, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_id",                                          :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "company_dashboards", :force => true do |t|
    t.integer  "dashboard_chart_id"
    t.string   "parameters"
    t.integer  "employee_user_id"
    t.integer  "company_id"
    t.string   "thresholds"
    t.string   "rag"
    t.boolean  "show_on_home_page"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_cgc"
    t.boolean  "is_favorite"
    t.string   "favorite_title"
  end

  create_table "company_email_settings", :force => true do |t|
    t.string   "setting_type"
    t.text     "address"
    t.integer  "port"
    t.text     "domain"
    t.text     "user_name"
    t.string   "password"
    t.integer  "company_id"
    t.boolean  "enable_ssl",           :default => false, :null => false
    t.boolean  "enable_starttls_auto", :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "company_lookups", :force => true do |t|
    t.string   "type"
    t.string   "lvalue"
    t.integer  "company_id",           :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.string   "alvalue"
    t.integer  "category_id"
  end

  create_table "company_reports", :force => true do |t|
    t.string   "report_type"
    t.string   "report_name"
    t.string   "controller_name"
    t.string   "action_name"
    t.integer  "company_id"
    t.integer  "employee_user_id"
    t.string   "get_records"
    t.boolean  "date_selected"
    t.date     "date_start"
    t.date     "date_end"
    t.string   "selected_options"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  create_table "company_role_rates", :force => true do |t|
    t.integer  "role_id"
    t.decimal  "billing_rate",         :precision => 10, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_id",                                          :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "company_temp_licences", :force => true do |t|
    t.integer  "company_id"
    t.integer  "licence_limit"
    t.integer  "created_by_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "compliance_departments", :force => true do |t|
    t.string   "name",             :limit => 256
    t.integer  "company_id"
    t.string   "owner_first_name", :limit => 256
    t.string   "owner_last_name",  :limit => 256
    t.string   "owner_email",      :limit => 256
    t.integer  "user_id"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "compliance_items", :force => true do |t|
    t.integer  "compliance_id"
    t.date     "due_date"
    t.string   "primary_status",      :limit => 64
    t.string   "secondary_status",    :limit => 64
    t.date     "filed_date"
    t.text     "filed_remarks"
    t.date     "completed_date"
    t.text     "completed_remarks"
    t.date     "reminder_start_date"
    t.string   "reminder_frequency"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "time_before_due"
    t.datetime "deleted_at"
    t.boolean  "delta",                             :default => true, :null => false
  end

  add_index "compliance_items", ["compliance_id"], :name => "index_compliance_items_on_compliance_id"

  create_table "compliance_trails", :force => true do |t|
    t.integer  "compliance_id"
    t.integer  "compliance_item_id"
    t.integer  "user_id"
    t.string   "email"
    t.string   "org_status"
    t.string   "new_status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "compliance_trails", ["compliance_item_id"], :name => "index_compliance_trails_on_compliance_item_id"

  create_table "compliance_types", :force => true do |t|
    t.integer  "company_id"
    t.integer  "parent_id"
    t.string   "lvalue",     :limit => 128
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "compliance_types", ["company_id"], :name => "index_compliances_types_on_company_id"

  create_table "compliances", :force => true do |t|
    t.integer  "company_id"
    t.text     "definition"
    t.integer  "type_id"
    t.integer  "subtype_id"
    t.string   "authority"
    t.string   "frequency",                :limit => 32
    t.string   "custom_freq",              :limit => 32
    t.date     "start_date"
    t.date     "end_date"
    t.text     "emails"
    t.integer  "create_by_user_id"
    t.integer  "assigned_to_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status",                   :limit => 32
    t.string   "required_for_items",       :limit => 10
    t.datetime "deleted_at"
    t.integer  "authority_id"
    t.integer  "compliance_department_id"
    t.string   "compliance_department",    :limit => 128
    t.text     "reference"
    t.date     "reminder_start_date"
    t.string   "time_before_due"
    t.string   "reminder_frequency"
    t.boolean  "delta",                                   :default => true, :null => false
  end

  add_index "compliances", ["company_id"], :name => "index_compliances_on_company_id"
  add_index "compliances", ["create_by_user_id"], :name => "index_compliances_on_create_by_user_id"

  create_table "contact_additional_fields", :force => true do |t|
    t.string   "business_street",          :limit => 64
    t.string   "business_city",            :limit => 64
    t.string   "business_state",           :limit => 64
    t.string   "business_country",         :limit => 64
    t.string   "business_postal_code",     :limit => 64
    t.string   "business_fax",             :limit => 32
    t.string   "business_phone",           :limit => 32
    t.string   "businessphone2",           :limit => 32
    t.string   "assistants_name",          :limit => 64
    t.string   "assistants_phone",         :limit => 32
    t.string   "professional_expertise",   :limit => 64
    t.string   "partners_name",            :limit => 64
    t.datetime "partners_birthday"
    t.string   "undergraduate_schools",    :limit => 64
    t.string   "graduate_school",          :limit => 64
    t.integer  "year_graduated"
    t.string   "graduate_degree",          :limit => 64
    t.string   "supervisors_title",        :limit => 64
    t.string   "supervisors_email",        :limit => 64
    t.string   "supervisors_phone_number", :limit => 32
    t.string   "religion",                 :limit => 64
    t.datetime "birthday"
    t.string   "birth_country",            :limit => 64
    t.string   "children",                 :limit => 64
    t.string   "gender",                   :limit => 32
    t.string   "hobby",                    :limit => 64
    t.datetime "first_contact"
    t.datetime "date_of_first_deal"
    t.string   "current_service_provider", :limit => 64
    t.datetime "next_call_back_date"
    t.string   "referred_by",              :limit => 64
    t.string   "spouse_name",              :limit => 64
    t.datetime "spouse_birthday"
    t.string   "linked_in_account",        :limit => 64
    t.string   "twitter_account",          :limit => 64
    t.string   "facebook_account",         :limit => 64
    t.string   "association_1",            :limit => 64
    t.string   "association_2",            :limit => 64
    t.integer  "contact_id"
    t.integer  "company_id",                             :null => false
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "skype_account",            :limit => 64
    t.integer  "business_phone1_type"
    t.integer  "business_phone2_type"
  end

  create_table "contacts", :force => true do |t|
    t.integer  "campaign_id"
    t.integer  "assigned_to_employee_user_id"
    t.string   "first_name",                   :limit => 64,  :default => ""
    t.string   "last_name",                    :limit => 64,  :default => ""
    t.string   "title",                        :limit => 64
    t.string   "organization",                 :limit => 64
    t.integer  "source"
    t.integer  "status"
    t.string   "email",                        :limit => 64
    t.string   "alt_email",                    :limit => 64
    t.string   "phone",                        :limit => 32
    t.string   "mobile",                       :limit => 32
    t.string   "website",                      :limit => 128
    t.integer  "rating",                                      :default => 0,     :null => false
    t.boolean  "do_not_call",                                 :default => false, :null => false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status_type"
    t.text     "department"
    t.text     "fax"
    t.string   "preference"
    t.string   "nickname"
    t.boolean  "delta",                                       :default => true,  :null => false
    t.integer  "company_id",                                                     :null => false
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.integer  "employee_user_id"
    t.string   "reports_to"
    t.integer  "zimbra_contact_id"
    t.boolean  "zimbra_contact_status"
    t.integer  "user_id"
    t.integer  "contact_stage_id"
    t.string   "salutation"
  end

  add_index "contacts", ["assigned_to_employee_user_id"], :name => "index_leads_on_assigned_to"

  create_table "dashboard_charts", :force => true do |t|
    t.string  "chart_name"
    t.string  "type_of_chart"
    t.string  "xml_builder_name"
    t.string  "template_name"
    t.string  "colors"
    t.string  "defult_thresholds"
    t.string  "parameters"
    t.boolean "default_on_home_page"
    t.boolean "is_cgc"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["locked_by"], :name => "index_delayed_jobs_on_locked_by"

  create_table "departments", :force => true do |t|
    t.integer  "parent_id"
    t.string   "name",       :null => false
    t.string   "location"
    t.integer  "company_id", :null => false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "document_access_controls", :force => true do |t|
    t.integer  "document_home_id"
    t.integer  "matter_people_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "contact_id"
    t.integer  "employee_user_id"
    t.integer  "company_id",           :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "document_bookmarks", :force => true do |t|
    t.integer "document_home_id"
    t.integer "document_id"
    t.integer "user_id"
  end

  create_table "document_homes", :force => true do |t|
    t.string   "mapable_type"
    t.integer  "mapable_id"
    t.integer  "access_rights"
    t.integer  "latest"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sub_type"
    t.integer  "sub_type_id"
    t.integer  "upload_stage"
    t.integer  "converted_by_user_id"
    t.boolean  "delta",                          :default => true, :null => false
    t.integer  "company_id",                                       :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.integer  "folder_id"
    t.integer  "parent_id"
    t.integer  "checked_in_by_employee_user_id"
    t.datetime "checked_in_at"
    t.boolean  "repo_update"
    t.boolean  "enforce_version_change"
    t.integer  "wip_doc"
    t.integer  "employee_user_id"
  end

  create_table "document_homes_matter_facts", :id => false, :force => true do |t|
    t.integer "document_home_id"
    t.integer "matter_fact_id"
  end

  create_table "document_homes_matter_issues", :id => false, :force => true do |t|
    t.integer "document_home_id"
    t.integer "matter_issue_id"
  end

  create_table "document_homes_matter_researches", :id => false, :force => true do |t|
    t.integer "document_home_id"
    t.integer "matter_research_id"
  end

  create_table "document_homes_matter_risks", :id => false, :force => true do |t|
    t.integer "document_home_id"
    t.integer "matter_risk_id"
  end

  create_table "document_homes_matter_tasks", :id => false, :force => true do |t|
    t.integer "document_home_id"
    t.integer "matter_task_id"
  end

  create_table "documents", :force => true do |t|
    t.string   "name"
    t.string   "phase"
    t.boolean  "bookmark"
    t.text     "description"
    t.string   "author"
    t.string   "source"
    t.string   "privilege"
    t.string   "data_file_name"
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "employee_user_id"
    t.integer  "document_home_id"
    t.boolean  "delta",                :default => true, :null => false
    t.integer  "company_id",                             :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.integer  "category_id"
    t.integer  "sub_category_id"
    t.integer  "doc_source_id"
  end

  create_table "dynamic_labels", :force => true do |t|
    t.integer "company_id"
    t.string  "file_name"
  end

  create_table "employee_activity_rates", :force => true do |t|
    t.integer  "employee_user_id"
    t.integer  "activity_type_id"
    t.decimal  "billing_rate"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_id",           :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "employee_favorites", :force => true do |t|
    t.string   "fav_type"
    t.string   "name"
    t.text     "url"
    t.string   "controller_name"
    t.string   "action_name"
    t.integer  "company_id"
    t.integer  "employee_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "employee_sessions", :force => true do |t|
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at"
    t.boolean  "deleted",              :default => false
    t.integer  "company_id"
    t.integer  "employee_id"
    t.datetime "session_start"
    t.datetime "session_end"
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "employees", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "salutation"
    t.date     "birthdate"
    t.text     "description"
    t.integer  "user_id"
    t.integer  "billing_rate"
    t.integer  "role_id"
    t.integer  "company_id",                                            :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.string   "first_name",           :limit => 32
    t.string   "last_name",            :limit => 32
    t.string   "email",                :limit => 64
    t.string   "phone",                :limit => 32
    t.string   "mobile",               :limit => 32
    t.integer  "parent_id"
    t.integer  "department_id"
    t.integer  "designation_id"
    t.string   "registered_number1"
    t.string   "registered_number2"
    t.string   "registered_number3"
    t.string   "access_code"
    t.boolean  "my_contacts",                        :default => false
    t.boolean  "my_campaign",                        :default => false
    t.boolean  "my_opportunities",                   :default => false
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.string   "reference1"
    t.string   "reference2"
  end

  create_table "expense_entries", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "employee_user_id"
    t.integer  "created_by_user_id"
    t.integer  "expense_type"
    t.integer  "time_entry_id"
    t.text     "description",                                                             :null => false
    t.date     "expense_entry_date",                                                      :null => false
    t.integer  "billing_method_type"
    t.decimal  "billing_percent",      :precision => 14, :scale => 2
    t.decimal  "expense_amount",       :precision => 14, :scale => 2,                     :null => false
    t.decimal  "final_expense_amount", :precision => 16, :scale => 2
    t.integer  "contact_id"
    t.integer  "matter_id"
    t.integer  "company_id",                                                              :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "updated_by_user_id"
    t.string   "status",                                              :default => "Open"
    t.integer  "matter_task_id"
    t.boolean  "is_billable",                                         :default => false
    t.boolean  "is_internal",                                         :default => true
    t.integer  "tne_invoice_id"
  end

  create_table "folders", :force => true do |t|
    t.string   "name"
    t.integer  "company_id",           :null => false
    t.integer  "parent_id"
    t.datetime "deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "employee_user_id"
    t.integer  "updated_by_user_id"
    t.datetime "permanent_deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "dotted_ids"
    t.boolean  "livian_access"
    t.boolean  "for_workspace"
  end

  create_table "invoice_details", :force => true do |t|
    t.integer  "company_id",                                                             :null => false
    t.integer  "invoice_id",                                                             :null => false
    t.integer  "licence_id",                                                             :null => false
    t.integer  "product_id",                                                             :null => false
    t.datetime "billing_from_date",                                                      :null => false
    t.datetime "billing_to_date",                                                        :null => false
    t.decimal  "total_amount",          :precision => 12, :scale => 2,                   :null => false
    t.decimal  "cost",                  :precision => 12, :scale => 2,                   :null => false
    t.decimal  "count",                 :precision => 12, :scale => 2,                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "delta",                                                :default => true, :null => false
    t.datetime "permanent_deleted_at"
    t.datetime "deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.integer  "status"
    t.datetime "product_purchase_date"
  end

  create_table "invoices", :force => true do |t|
    t.integer  "company_id",                                                            :null => false
    t.datetime "invoice_date",                                                          :null => false
    t.datetime "invoice_from_date"
    t.datetime "invoice_to_date"
    t.decimal  "invoice_amount",       :precision => 12, :scale => 2,                   :null => false
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "delta",                                               :default => true, :null => false
    t.datetime "permanent_deleted_at"
    t.datetime "deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  create_table "last_message_read", :force => true do |t|
    t.string  "message"
    t.integer "company_id"
  end

  create_table "licences", :force => true do |t|
    t.integer  "company_id",    :null => false
    t.integer  "product_id",    :null => false
    t.integer  "licence_count", :null => false
    t.integer  "cost",          :null => false
    t.datetime "start_date",    :null => false
    t.datetime "expired_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "links", :force => true do |t|
    t.integer  "company_id"
    t.text     "description"
    t.string   "name"
    t.integer  "mapable_id"
    t.string   "mapable_type"
    t.integer  "category_id"
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.text     "url"
    t.integer  "created_by_user_id"
    t.integer  "created_by_employee_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "delta",                       :default => true
    t.integer  "sub_category_id"
    t.integer  "folder_id"
  end

  create_table "logged_exceptions", :force => true do |t|
    t.string   "exception_class"
    t.string   "controller_name"
    t.string   "action_name"
    t.text     "message"
    t.text     "backtrace"
    t.text     "environment"
    t.text     "request"
    t.datetime "created_at"
  end

  create_table "lookups", :force => true do |t|
    t.string   "type"
    t.string   "lvalue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "matter_billings", :force => true do |t|
    t.string   "bill_no"
    t.date     "bill_issue_date"
    t.date     "bill_pay_date"
    t.integer  "bill_amount"
    t.integer  "bill_amount_paid"
    t.string   "bill_status"
    t.integer  "matter_id"
    t.string   "remarks"
    t.integer  "bill_id"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "matter_budgets", :force => true do |t|
    t.integer  "matter_id"
    t.integer  "company_id"
    t.string   "month"
    t.integer  "duration"
    t.integer  "matter_budget_category_id"
    t.integer  "estimated"
    t.integer  "cgc_company_id"
    t.integer  "budget_period_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "matter_facts", :force => true do |t|
    t.text     "name"
    t.integer  "parent_id"
    t.text     "details"
    t.string   "source"
    t.integer  "material"
    t.integer  "matter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status_id"
    t.integer  "company_id",           :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.integer  "doc_source_id"
  end

  create_table "matter_facts_matter_issues", :id => false, :force => true do |t|
    t.integer "matter_fact_id"
    t.integer "matter_issue_id"
  end

  create_table "matter_facts_matter_researches", :id => false, :force => true do |t|
    t.integer "matter_fact_id"
    t.integer "matter_research_id"
  end

  create_table "matter_issues", :force => true do |t|
    t.text     "name"
    t.integer  "parent_id"
    t.boolean  "is_primary"
    t.boolean  "is_key_issue"
    t.text     "description"
    t.date     "target_resolution_date"
    t.integer  "assigned_to_matter_people_id"
    t.integer  "matter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "resolved"
    t.text     "resolution"
    t.boolean  "active"
    t.boolean  "client_issue"
    t.date     "resolved_at"
    t.integer  "company_id",                   :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  create_table "matter_issues_matter_researches", :id => false, :force => true do |t|
    t.integer "matter_issue_id"
    t.integer "matter_research_id"
  end

  create_table "matter_issues_matter_risks", :id => false, :force => true do |t|
    t.integer "matter_issue_id"
    t.integer "matter_risk_id"
  end

  create_table "matter_issues_matter_tasks", :id => false, :force => true do |t|
    t.integer  "matter_issue_id"
    t.integer  "matter_task_id"
    t.integer  "company_id",           :null => false
    t.datetime "created_at"
    t.datetime "deleted_at"
    t.datetime "updated_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "matter_litigations", :force => true do |t|
    t.boolean  "plaintiff"
    t.string   "case_number"
    t.string   "hearing_before"
    t.string   "forum"
    t.integer  "matter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_id",           :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  create_table "matter_peoples", :force => true do |t|
    t.integer  "employee_user_id"
    t.string   "people_type"
    t.string   "name"
    t.string   "email"
    t.text     "address"
    t.string   "fax"
    t.string   "phone"
    t.boolean  "is_active"
    t.date     "start_date"
    t.date     "end_date"
    t.boolean  "primary_contact"
    t.integer  "matter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "matter_team_role_id"
    t.integer  "contact_id"
    t.integer  "company_id",                         :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.date     "member_start_date"
    t.date     "member_end_date"
    t.string   "salutation",           :limit => 16
    t.string   "last_name",            :limit => 32
    t.string   "notes"
    t.string   "city",                 :limit => 64
    t.string   "state",                :limit => 64
    t.string   "zip",                  :limit => 16
    t.string   "country",              :limit => 64
    t.string   "alternate_email",      :limit => 64
    t.string   "mobile",               :limit => 16
    t.string   "role_text",            :limit => 64
    t.boolean  "added_to_contact"
    t.integer  "additional_priv"
    t.boolean  "can_access_matter"
  end

  create_table "matter_peoples_document_homes", :id => false, :force => true do |t|
    t.integer  "matter_people_id"
    t.integer  "document_home_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "matter_peoples_matter_tasks", :id => false, :force => true do |t|
    t.integer  "matter_people_id"
    t.integer  "matter_task_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "matter_researches", :force => true do |t|
    t.text     "name"
    t.integer  "parent_id"
    t.integer  "research_type"
    t.string   "citation"
    t.text     "description"
    t.integer  "matter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_internal"
    t.integer  "company_id",           :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  create_table "matter_researches_matter_risks", :id => false, :force => true do |t|
    t.integer  "matter_research_id"
    t.integer  "matter_risk_id"
    t.integer  "company_id",           :null => false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "matter_researches_matter_tasks", :id => false, :force => true do |t|
    t.integer "matter_task_id"
    t.integer "matter_research_id"
  end

  create_table "matter_retainers", :force => true do |t|
    t.date     "date"
    t.integer  "amount"
    t.string   "remarks"
    t.integer  "matter_id"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "matter_risks", :force => true do |t|
    t.text     "name"
    t.text     "details"
    t.boolean  "is_material"
    t.integer  "matter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_id",           :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  create_table "matter_tasks", :force => true do |t|
    t.text     "name"
    t.integer  "parent_id"
    t.integer  "phase_id"
    t.text     "description"
    t.integer  "assigned_to_matter_people_id"
    t.boolean  "completed"
    t.date     "completed_at"
    t.string   "assoc_as"
    t.integer  "matter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "critical"
    t.boolean  "client_task"
    t.integer  "company_id",                                        :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.string   "category"
    t.string   "location"
    t.string   "priority"
    t.string   "progress"
    t.string   "progress_percentage"
    t.string   "show_as"
    t.string   "mark_as"
    t.boolean  "all_day_event"
    t.time     "start_time"
    t.time     "end_time"
    t.string   "repeat"
    t.string   "reminder"
    t.text     "attendees_emails"
    t.string   "zimbra_task_id"
    t.boolean  "zimbra_task_status"
    t.string   "lawyer_name"
    t.string   "lawyer_email"
    t.string   "client_task_type"
    t.string   "client_task_doc_name"
    t.string   "client_task_doc_desc"
    t.string   "occurrence_type",              :default => "count"
    t.integer  "count"
    t.date     "until"
    t.boolean  "exception_status"
    t.date     "exception_start_date"
    t.time     "exception_start_time"
    t.integer  "task_id"
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer  "assigned_to_user_id"
  end

  create_table "matter_termconditions", :force => true do |t|
    t.text     "scope_of_work"
    t.text     "billing_rates_details"
    t.text     "terms_of_payment"
    t.text     "retainer_fee_detail"
    t.text     "client_obligations_impacts"
    t.text     "disclaimers"
    t.text     "account_details"
    t.string   "billing_type"
    t.string   "billing_value"
    t.integer  "matter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "highlights"
    t.integer  "company_id",                               :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.string   "billing_by",                 :limit => 64
    t.string   "retainer_amount",            :limit => 64
    t.string   "not_to_exceed_amount",       :limit => 64
    t.string   "min_trigger_amount",         :limit => 64
    t.string   "fixed_rate_amount",          :limit => 64
    t.string   "additional_details"
  end

  create_table "matters", :force => true do |t|
    t.text     "name"
    t.integer  "parent_id"
    t.text     "brief"
    t.boolean  "is_internal"
    t.integer  "contact_id"
    t.string   "matter_no"
    t.string   "ref_no"
    t.text     "description"
    t.string   "matter_category"
    t.integer  "matter_type_id"
    t.integer  "employee_user_id"
    t.boolean  "conflict_checked"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "estimated_hours"
    t.integer  "opportunity_id"
    t.boolean  "delta",                :default => true,  :null => false
    t.integer  "phase_id"
    t.integer  "company_id",                              :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.datetime "closed_on"
    t.integer  "retainer_fee"
    t.integer  "min_retainer_fee"
    t.date     "matter_date"
    t.boolean  "client_access",        :default => false
    t.integer  "status_id"
  end

  create_table "notes", :force => true do |t|
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at"
    t.integer  "assigned_by_employee_user_id",                    :null => false
    t.integer  "created_by_user_id",                              :null => false
    t.text     "description",                                     :null => false
    t.integer  "note_priority"
    t.boolean  "is_actionable",                :default => false
    t.boolean  "more_action",                  :default => false
    t.integer  "matter_id"
    t.integer  "assigned_to_user_id"
    t.datetime "deleted_at"
    t.text     "status"
    t.integer  "contact_id"
    t.integer  "company_id"
    t.integer  "updated_by_user_id"
    t.time     "permanent_deleted_at"
    t.string   "call_id"
  end

  create_table "old_users", :force => true do |t|
    t.string   "username",             :limit => 32, :default => "",  :null => false
    t.string   "email",                :limit => 64, :default => "",  :null => false
    t.string   "first_name",           :limit => 32
    t.string   "last_name",            :limit => 32
    t.string   "title",                :limit => 64
    t.string   "alt_email",            :limit => 64
    t.string   "phone",                :limit => 32
    t.string   "mobile",               :limit => 32
    t.string   "password_hash",                      :default => "",  :null => false
    t.string   "password_salt",                      :default => "",  :null => false
    t.string   "persistence_token",                  :default => "",  :null => false
    t.string   "perishable_token",                   :default => "",  :null => false
    t.datetime "last_request_at"
    t.datetime "last_login_at"
    t.datetime "current_login_at"
    t.string   "last_login_ip"
    t.string   "current_login_ip"
    t.integer  "login_count",                        :default => 0,   :null => false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "time_zone"
    t.integer  "company_id",                         :default => 100, :null => false
    t.datetime "permanent_deleted_at"
    t.string   "session_key"
    t.integer  "parent_id"
    t.integer  "department_id"
    t.text     "security_question"
    t.text     "security_answer"
  end

  add_index "old_users", ["email"], :name => "index_users_on_email"
  add_index "old_users", ["last_request_at"], :name => "index_users_on_last_request_at"
  add_index "old_users", ["perishable_token"], :name => "index_users_on_perishable_token"
  add_index "old_users", ["persistence_token"], :name => "index_users_on_remember_token"
  add_index "old_users", ["username", "deleted_at"], :name => "index_users_on_username_and_deleted_at", :unique => true

  create_table "opportunities", :force => true do |t|
    t.integer  "employee_user_id"
    t.integer  "campaign_id"
    t.integer  "assigned_to_employee_user_id"
    t.string   "name",                         :limit => 64,                                :default => "",   :null => false
    t.integer  "source"
    t.integer  "stage"
    t.integer  "probability"
    t.decimal  "amount",                                     :precision => 12, :scale => 2
    t.decimal  "discount",                                   :precision => 12, :scale => 2
    t.date     "closes_on"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.integer  "contact_id"
    t.decimal  "estimated_hours",                            :precision => 12, :scale => 2
    t.boolean  "delta",                                                                     :default => true, :null => false
    t.integer  "company_id",                                                                                  :null => false
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.datetime "closed_on"
    t.datetime "follow_up"
    t.datetime "status_updated_on"
  end

  add_index "opportunities", ["assigned_to_employee_user_id"], :name => "index_opportunities_on_assigned_to"
  add_index "opportunities", ["campaign_id"], :name => "index_opportunities_on_campaign_id"
  add_index "opportunities", ["employee_user_id", "name", "deleted_at"], :name => "index_opportunities_on_user_id_and_name_and_deleted_at", :unique => true

  create_table "payments", :force => true do |t|
    t.integer  "invoice_id",                             :null => false
    t.string   "payment_mode",                           :null => false
    t.integer  "amount",                                 :null => false
    t.string   "cheque_no"
    t.datetime "cheque_date"
    t.string   "bank_name"
    t.string   "branch_name"
    t.string   "paypal_account_id"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "delta",                :default => true, :null => false
    t.datetime "permanent_deleted_at"
    t.datetime "deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.datetime "payment_date",                           :null => false
  end

  create_table "product_dependents", :force => true do |t|
    t.integer  "product_id", :null => false
    t.integer  "parent_id",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "product_licence_details", :force => true do |t|
    t.integer  "product_licence_id", :null => false
    t.datetime "start_date",         :null => false
    t.datetime "expired_date"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",            :null => false
    t.datetime "deleted_at"
  end

  create_table "product_licences", :force => true do |t|
    t.integer  "product_id",                        :null => false
    t.integer  "company_id"
    t.string   "licence_key",                       :null => false
    t.float    "licence_cost",                      :null => false
    t.datetime "start_at",                          :null => false
    t.datetime "end_at"
    t.datetime "deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",             :default => 0
    t.integer  "licence_id",                        :null => false
    t.integer  "licence_type",       :default => 0, :null => false
  end

  create_table "product_subproducts", :force => true do |t|
    t.integer  "product_id",           :null => false
    t.integer  "subproduct_id",        :null => false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  create_table "products", :force => true do |t|
    t.string   "name",                 :limit => 64, :default => "",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "delta",                              :default => true, :null => false
    t.datetime "permanent_deleted_at"
    t.datetime "deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.integer  "cost",                                                 :null => false
    t.string   "description"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "for_wfm",    :default => false
  end

  create_table "service_provider_employee_mappings", :force => true do |t|
    t.integer  "service_provider_id",  :null => false
    t.integer  "employee_user_id",     :null => false
    t.integer  "status"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "priority"
  end

  create_table "service_provider_sessions", :force => true do |t|
    t.datetime "created_at",           :null => false
    t.datetime "updated_at"
    t.integer  "service_provider_id"
    t.datetime "session_start"
    t.datetime "session_end"
    t.integer  "company_id",           :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "service_provider_skills", :force => true do |t|
    t.datetime "created_at",           :null => false
    t.datetime "updated_at"
    t.integer  "skill_type_id"
    t.integer  "service_provider_id",  :null => false
    t.integer  "company_id",           :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "service_providers", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deleted",              :default => false
    t.integer  "salutation"
    t.date     "birthdate"
    t.text     "description"
    t.integer  "user_id",                                 :null => false
    t.integer  "company_id",                              :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
  end

  create_table "service_sessions", :force => true do |t|
    t.integer  "provider_session_id",   :null => false
    t.integer  "service_assignment_id"
    t.datetime "session_start"
    t.datetime "session_end"
    t.integer  "company_id",            :null => false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "permanent_deleted_at"
    t.integer  "employee_user_id"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id",           :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_id"
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "sticky_notes", :force => true do |t|
    t.datetime "created_at",          :null => false
    t.datetime "updated_at"
    t.integer  "created_by_user_id",  :null => false
    t.text     "description",         :null => false
    t.integer  "company_id"
    t.integer  "assigned_to_user_id"
  end

  create_table "subproduct_assignments", :force => true do |t|
    t.integer  "user_id",            :null => false
    t.integer  "subproduct_id",      :null => false
    t.integer  "employee_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "product_licence_id", :null => false
    t.integer  "company_id",         :null => false
    t.datetime "deleted_at"
  end

  create_table "subproducts", :force => true do |t|
    t.string   "name",                 :limit => 64, :default => "",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "delta",                              :default => true, :null => false
    t.datetime "permanent_deleted_at"
    t.datetime "deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "taggable_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "tasks", :force => true do |t|
    t.integer  "assigned_to_user_id"
    t.integer  "completed_by_user_id"
    t.string   "name",                                       :default => "", :null => false
    t.integer  "note_id"
    t.string   "priority",                     :limit => 32
    t.datetime "completed_at"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status"
    t.integer  "tasktype"
    t.string   "bucket",                       :limit => 32
    t.datetime "due_at"
    t.integer  "company_id"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.time     "permanent_deleted_at"
    t.integer  "assigned_by_employee_user_id"
  end

  add_index "tasks", ["assigned_to_user_id"], :name => "index_tasks_on_assigned_to"

  create_table "time_entries", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "employee_user_id",                                                        :null => false
    t.integer  "created_by_user_id"
    t.integer  "activity_type",                                                           :null => false
    t.text     "description",                                                             :null => false
    t.date     "time_entry_date",                                                         :null => false
    t.datetime "start_time"
    t.datetime "end_time"
    t.decimal  "actual_duration",      :precision => 14, :scale => 2,                     :null => false
    t.integer  "billing_method_type"
    t.decimal  "billing_percent",      :precision => 14, :scale => 2
    t.decimal  "activity_rate",        :precision => 12, :scale => 2
    t.decimal  "actual_activity_rate", :precision => 14, :scale => 2
    t.decimal  "final_billed_amount",  :precision => 16, :scale => 2
    t.integer  "contact_id"
    t.integer  "matter_id"
    t.integer  "company_id",                                                              :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "updated_by_user_id"
    t.string   "status",                                              :default => "Open"
    t.integer  "matter_task_id"
    t.boolean  "is_billable",                                         :default => false
    t.boolean  "is_internal",                                         :default => true
    t.integer  "tne_invoice_id"
  end

  create_table "tmp", :force => true do |t|
    t.string   "username",             :limit => 32,  :default => "",  :null => false
    t.string   "email",                               :default => "",  :null => false
    t.string   "first_name",           :limit => 32
    t.string   "last_name",            :limit => 32
    t.string   "alt_email",            :limit => 64
    t.string   "phone",                :limit => 32
    t.string   "mobile",               :limit => 32
    t.integer  "company_id",                          :default => 100, :null => false
    t.integer  "department_id"
    t.integer  "parent_id"
    t.datetime "deleted_at"
    t.string   "encrypted_password",   :limit => 128, :default => "",  :null => false
    t.string   "password_salt",                       :default => "",  :null => false
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tne_invoice_details", :force => true do |t|
    t.integer  "tne_invoice_id"
    t.string   "entry_type"
    t.integer  "matter_id"
    t.integer  "contact_id"
    t.date     "tne_entry_date"
    t.string   "lawyer_designation"
    t.string   "lawyer_name"
    t.float    "duration"
    t.integer  "rate"
    t.string   "activity"
    t.text     "description"
    t.float    "amount"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "tne_invoice_expense_entries", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "employee_user_id"
    t.integer  "created_by_user_id"
    t.integer  "expense_type"
    t.integer  "time_entry_id"
    t.text     "description",                                                             :null => false
    t.date     "expense_entry_date",                                                      :null => false
    t.integer  "billing_method_type"
    t.decimal  "billing_percent",       :precision => 14, :scale => 2
    t.decimal  "expense_amount",        :precision => 14, :scale => 2,                    :null => false
    t.decimal  "final_expense_amount",  :precision => 14, :scale => 2
    t.integer  "contact_id"
    t.integer  "matter_id"
    t.integer  "company_id",                                           :default => 100,   :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "updated_by_user_id"
    t.string   "status"
    t.integer  "matter_task_id"
    t.boolean  "is_billable",                                          :default => false
    t.boolean  "is_internal",                                          :default => true
    t.integer  "tne_invoice_id"
    t.integer  "tne_invoice_detail_id"
    t.integer  "tne_expense_entry_id"
  end

  create_table "tne_invoice_settings", :force => true do |t|
    t.integer  "currency_type_id"
    t.string   "primary_tax_name"
    t.integer  "primary_tax_rate"
    t.string   "secondary_tax_name"
    t.integer  "secondary_tax_rate"
    t.boolean  "secondary_tax_rule", :default => false, :null => false
    t.integer  "payment_terms"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tne_invoice_time_entries", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "employee_user_id",                                                        :null => false
    t.integer  "created_by_user_id"
    t.integer  "activity_type",                                                           :null => false
    t.text     "description",                                                             :null => false
    t.date     "time_entry_date",                                                         :null => false
    t.datetime "start_time"
    t.datetime "end_time"
    t.decimal  "actual_duration",       :precision => 14, :scale => 2,                    :null => false
    t.boolean  "is_billable",                                          :default => false
    t.integer  "billing_method_type"
    t.decimal  "billing_percent",       :precision => 14, :scale => 2
    t.decimal  "billing_amount",        :precision => 14, :scale => 2
    t.decimal  "activity_rate",         :precision => 14, :scale => 2
    t.decimal  "actual_activity_rate",  :precision => 14, :scale => 2
    t.decimal  "final_billed_amount",   :precision => 14, :scale => 2
    t.boolean  "is_internal",                                          :default => false
    t.integer  "contact_id"
    t.integer  "matter_id"
    t.integer  "company_id",                                           :default => 100,   :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "updated_by_user_id"
    t.integer  "matter_task_id"
    t.integer  "tne_invoice_id"
    t.integer  "tne_invoice_detail_id"
    t.string   "status"
    t.integer  "tne_time_entry_id"
  end

  create_table "tne_invoices", :force => true do |t|
    t.string   "invoice_no"
    t.date     "invoice_date"
    t.date     "invoice_due_date"
    t.float    "invoice_amt"
    t.integer  "primary_tax_rate"
    t.integer  "secondary_tax_rate"
    t.integer  "discount",              :default => 0,     :null => false
    t.text     "invoice_notes"
    t.float    "final_invoice_amt"
    t.integer  "company_id"
    t.boolean  "secondary_tax_rule",    :default => false, :null => false
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.integer  "matter_id"
    t.integer  "contact_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "view_by"
    t.string   "status_reason"
    t.integer  "tne_invoice_status_id"
    t.datetime "deleted_at"
    t.string   "primary_tax_name"
    t.string   "secondary_tax_name"
    t.string   "consolidated_by"
    t.string   "view"
  end

  create_table "user_roles", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "role_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "user_settings", :force => true do |t|
    t.integer  "user_id"
    t.string   "setting_type"
    t.string   "setting_value"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_work_subtypes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "work_subtype_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "username",             :limit => 32,  :default => "",    :null => false
    t.string   "email",                               :default => "",    :null => false
    t.string   "first_name",           :limit => 32
    t.string   "last_name",            :limit => 32
    t.string   "alt_email",            :limit => 64
    t.string   "phone",                :limit => 32
    t.string   "mobile",               :limit => 32
    t.integer  "company_id",                                             :null => false
    t.integer  "department_id"
    t.integer  "parent_id"
    t.datetime "deleted_at"
    t.string   "encrypted_password",   :limit => 128, :default => "",    :null => false
    t.string   "password_salt",                       :default => "",    :null => false
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "change_password"
    t.integer  "failed_attempts"
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.text     "security_question"
    t.text     "security_answer"
    t.string   "time_zone"
    t.boolean  "is_signedin",                         :default => false
    t.string   "zimbra_time_zone"
    t.integer  "priority"
    t.integer  "cluster_id"
    t.string   "reset_tpin_token"
    t.string   "single_signon_id"
    t.string   "p_token"
    t.string   "nick_name"
  end

  create_table "work_subtype_complexities", :force => true do |t|
    t.integer  "work_subtype_id"
    t.integer  "complexity_level"
    t.integer  "stt"
    t.integer  "tat"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "work_subtypes", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "work_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "work_types", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "zimbra_activities", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "category"
    t.integer  "zimbra_folder_location"
    t.integer  "assigned_to_user_id"
    t.string   "zimbra_task_id"
    t.boolean  "zimbra_status"
    t.integer  "reminder"
    t.string   "repeat"
    t.text     "location"
    t.text     "attendees_emails"
    t.boolean  "response"
    t.boolean  "notification"
    t.string   "show_as"
    t.string   "mark_as"
    t.datetime "start_date"
    t.datetime "end_date"
    t.boolean  "all_day_event"
    t.boolean  "exception_status"
    t.integer  "task_id"
    t.datetime "exception_start_date"
    t.string   "occurrence_type"
    t.integer  "count"
    t.date     "until"
    t.string   "progress_percentage"
    t.string   "progress"
    t.string   "priority"
    t.datetime "deleted_at"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "completed_at"
    t.string   "user_name"
  end

end
