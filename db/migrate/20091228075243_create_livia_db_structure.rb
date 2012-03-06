class CreateLiviaDbStructure < ActiveRecord::Migration
create_table "access_controls", :force => true do |t|
    t.integer  "document_home_id"
    t.integer  "matter_people_id"
    t.string   "access_right"
    t.boolean  "is_edit"
    t.boolean  "is_view"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "contact_id"
    t.integer  "employee_user_id"
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "account_contacts", :force => true do |t|
    t.integer  "account_id"
    t.integer  "contact_id"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "priority"
    t.integer  "company_id",         :default => 100
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
    t.integer  "company_id",                                 :default => 100,       :null => false
    t.datetime "permanent_deleted_at"
    t.datetime "deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  add_index "accounts", ["assigned_to_employee_user_id"], :name => "index_accounts_on_assigned_to"

  create_table "activities", :force => true do |t|
    t.integer  "user_id"
    t.integer  "subject_id"
    t.string   "subject_type"
    t.string   "action",               :limit => 32, :default => "created"
    t.string   "info",                               :default => ""
    t.boolean  "private",                            :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_id",                         :default => 100,       :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  add_index "activities", ["created_at"], :name => "index_activities_on_created_at"
  add_index "activities", ["user_id"], :name => "index_activities_on_user_id"

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
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "assets", :force => true do |t|
    t.string   "data_file_name"
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.integer  "document_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.integer  "attachable_id"
    t.string   "attachable_type"
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  create_table "campaign_mails", :force => true do |t|
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at"
    t.integer  "created_by_user_id"
    t.boolean  "deleted",              :default => false
    t.integer  "owning_org_id"
    t.integer  "campaign_id"
    t.text     "content"
    t.text     "subject"
    t.text     "signature"
    t.text     "mail_type"
    t.integer  "company_id",           :default => 100,   :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "updated_by_user_id"
  end

  create_table "campaign_members", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deleted",                                                       :default => false
    t.integer  "owning_org_id"
    t.integer  "campaign_id"
    t.integer  "contact_id"
    t.integer  "campaign_member_status_type_id"
    t.decimal  "pledged_amount",                 :precision => 12, :scale => 2
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
    t.integer  "company_id",                                                    :default => 100,   :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "updated_by_user_id"
  end

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
    t.text     "objectives"
    t.datetime "deleted_at"
    t.string   "identifier",              :limit => 200
    t.boolean  "delta",                                  :default => true, :null => false
    t.integer  "company_id",                             :default => 100,  :null => false
    t.datetime "permanent_deleted_at"
    t.integer  "updated_by_user_id"
    t.integer  "created_by_user_id"
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
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "companies", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                 :limit => 200, :null => false
    t.text     "about"
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  add_index "companies", ["name"], :name => "companies_name_key", :unique => true

  create_table "company_activity_rates", :force => true do |t|
    t.integer  "activity_id"
    t.decimal  "billing_rate",         :precision => 10, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_id",                                          :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "company_lookups", :force => true do |t|
    t.string   "type"
    t.string   "lvalue"
    t.integer  "company_id",           :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "company_role_rates", :force => true do |t|
    t.integer  "role_id"
    t.decimal  "billing_rate",         :precision => 10, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_id",                                          :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "contacts", :force => true do |t|
    t.integer  "campaign_id"
    t.integer  "assigned_to_employee_user_id"
    t.string   "first_name",                   :limit => 64,  :default => ""
    t.string   "last_name",                    :limit => 64,  :default => ""
    t.string   "access",                       :limit => 8,   :default => "Private"
    t.string   "title",                        :limit => 64
    t.string   "company",                      :limit => 64
    t.integer  "source"
    t.integer  "status"
    t.string   "email",                        :limit => 64
    t.string   "alt_email",                    :limit => 64
    t.string   "phone",                        :limit => 32
    t.string   "mobile",                       :limit => 32
    t.string   "website",                      :limit => 128
    t.integer  "rating",                                      :default => 0,         :null => false
    t.boolean  "do_not_call",                                 :default => false,     :null => false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status_type"
    t.text     "department"
    t.integer  "fax"
    t.string   "preference"
    t.string   "nickname"
    t.boolean  "delta",                                       :default => true,      :null => false
    t.integer  "company_id",                                  :default => 100,       :null => false
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
    t.integer  "employee_user_id"
  end

  add_index "contacts", ["assigned_to_employee_user_id"], :name => "index_leads_on_assigned_to"

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
    t.integer  "upload_by"
    t.boolean  "delta",                :default => true, :null => false
    t.integer  "company_id",           :default => 100,  :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  create_table "document_homes_matter_facts", :id => false, :force => true do |t|
    t.integer  "document_home_id"
    t.integer  "matter_fact_id"
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "document_homes_matter_issues", :id => false, :force => true do |t|
    t.integer  "document_home_id"
    t.integer  "matter_issue_id"
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "document_homes_matter_researches", :id => false, :force => true do |t|
    t.integer  "document_home_id"
    t.integer  "matter_research_id"
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "document_homes_matter_risks", :id => false, :force => true do |t|
    t.integer  "document_home_id"
    t.integer  "matter_risk_id"
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "document_homes_matter_tasks", :id => false, :force => true do |t|
    t.integer  "document_home_id"
    t.integer  "matter_task_id"
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "documents", :force => true do |t|
    t.string   "name"
    t.string   "phase"
    t.boolean  "bookmark"
    t.string   "type"
    t.text     "description"
    t.string   "author"
    t.string   "recipient"
    t.string   "brief"
    t.string   "source"
    t.integer  "linked_issue_id"
    t.integer  "linked_facts_id"
    t.string   "privilege"
    t.integer  "document_rights"
    t.string   "data_file_name"
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.integer  "documentable_id"
    t.string   "documentable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "employee_user_id"
    t.integer  "document_home_id"
    t.boolean  "delta",                :default => true, :null => false
    t.integer  "company_id",           :default => 100,  :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  create_table "employee_activity_rates", :force => true do |t|
    t.integer  "employee_user_id"
    t.integer  "activity_id"
    t.decimal  "billing_rate"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "employee_sessions", :force => true do |t|
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at"
    t.boolean  "deleted",              :default => false
    t.integer  "company_id",           :default => 100
    t.integer  "employee_id"
    t.datetime "session_start"
    t.datetime "session_end"
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "employees", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deleted",                           :default => false
    t.integer  "salutation"
    t.date     "birthdate"
    t.text     "description"
    t.integer  "user_id"
    t.text     "security_question"
    t.integer  "billing_rate"
    t.string   "security_answer"
    t.integer  "role_id"
    t.string   "designation",          :limit => 1
    t.integer  "company_id",                        :default => 100,   :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "expense_entries", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "employee_user_id"
    t.integer  "created_by_user_id"
    t.integer  "expense_type"
    t.integer  "related_time_entry"
    t.text     "description",                                                          :null => false
    t.integer  "billable_type"
    t.date     "expense_entry_date",                                                   :null => false
    t.integer  "billing_method_type"
    t.decimal  "billing_percent",      :precision => 14, :scale => 2
    t.decimal  "billing_amount",       :precision => 14, :scale => 2
    t.decimal  "expense_amount",       :precision => 14, :scale => 2,                  :null => false
    t.decimal  "final_expense_amount", :precision => 14, :scale => 2
    t.integer  "accounted_for_type"
    t.integer  "contact_id"
    t.integer  "matter_id"
    t.integer  "company_id",                                          :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "updated_by_user_id"
  end

  create_table "lookups", :force => true do |t|
    t.string   "type"
    t.string   "lvalue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
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
    t.integer  "status"
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  create_table "matter_facts_matter_issues", :id => false, :force => true do |t|
    t.integer  "matter_fact_id"
    t.integer  "matter_issue_id"
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "matter_facts_matter_researches", :id => false, :force => true do |t|
    t.integer  "matter_fact_id"
    t.integer  "matter_research_id"
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
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
    t.integer  "company_id",                   :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  create_table "matter_issues_matter_researches", :id => false, :force => true do |t|
    t.integer  "matter_issue_id"
    t.integer  "matter_research_id"
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "matter_issues_matter_risks", :id => false, :force => true do |t|
    t.integer  "matter_issue_id"
    t.integer  "matter_risk_id"
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "matter_issues_matter_tasks", :id => false, :force => true do |t|
    t.integer  "matter_issue_id"
    t.integer  "matter_task_id"
    t.integer  "company_id",           :default => 100, :null => false
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
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  create_table "matter_peoples", :force => true do |t|
    t.integer  "employee_user_id"
    t.string   "type"
    t.string   "people_type"
    t.string   "name"
    t.string   "email"
    t.text     "address"
    t.string   "fax"
    t.string   "phone"
    t.boolean  "is_active"
    t.date     "start_date"
    t.date     "end_date"
    t.string   "practice_area"
    t.boolean  "primary_contact"
    t.string   "law_firm"
    t.integer  "matter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "access"
    t.integer  "role"
    t.integer  "contact_id"
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
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
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  create_table "matter_researches_matter_risks", :id => false, :force => true do |t|
    t.integer  "matter_research_id"
    t.integer  "matter_risk_id"
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "matter_researches_matter_tasks", :id => false, :force => true do |t|
    t.integer  "matter_task_id"
    t.integer  "matter_research_id"
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "matter_risks", :force => true do |t|
    t.text     "name"
    t.text     "details"
    t.boolean  "is_material"
    t.integer  "matter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  create_table "matter_tasks", :force => true do |t|
    t.text     "name"
    t.integer  "parent_id"
    t.integer  "phase"
    t.text     "description"
    t.date     "complete_by"
    t.integer  "assigned_to_matter_people_id"
    t.boolean  "completed"
    t.date     "completed_at"
    t.string   "actual_hour_spent"
    t.integer  "document_id"
    t.boolean  "is_milestone"
    t.string   "expected_hours"
    t.string   "assoc_as"
    t.integer  "matter_id"
    t.string   "billable_hours"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "critical"
    t.boolean  "client_task"
    t.integer  "company_id",                   :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
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
    t.integer  "company_id",                 :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  create_table "matters", :force => true do |t|
    t.text     "name"
    t.integer  "parent_id"
    t.text     "brief"
    t.boolean  "is_internal"
    t.integer  "contact_id"
    t.string   "auto_generated_matter_id"
    t.string   "ref_id"
    t.string   "primary_matter_id"
    t.text     "description"
    t.string   "litigation_type"
    t.integer  "matter_type"
    t.integer  "employee_user_id"
    t.boolean  "conflict_checked"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "estimated_hours"
    t.integer  "opportunity_id"
    t.boolean  "delta",                    :default => true, :null => false
    t.integer  "phase_id"
    t.integer  "access_rights"
    t.string   "status"
    t.integer  "company_id",               :default => 100,  :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
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
  end

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
    t.integer  "estimated_hours"
    t.boolean  "delta",                                                                     :default => true, :null => false
    t.integer  "company_id",                                                                :default => 100,  :null => false
    t.datetime "permanent_deleted_at"
    t.integer  "created_by_user_id"
    t.integer  "updated_by_user_id"
  end

  add_index "opportunities", ["assigned_to_employee_user_id"], :name => "index_opportunities_on_assigned_to"
  add_index "opportunities", ["employee_user_id", "name", "deleted_at"], :name => "index_opportunities_on_user_id_and_name_and_deleted_at", :unique => true

  create_table "service_assignments", :force => true do |t|
    t.integer  "service_provider_id",                   :null => false
    t.integer  "employee_user_id",                      :null => false
    t.datetime "service_start"
    t.datetime "service_end"
    t.integer  "status"
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "service_provider_sessions", :force => true do |t|
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at"
    t.boolean  "deleted",              :default => false
    t.integer  "service_provider_id"
    t.datetime "session_start"
    t.datetime "session_end"
    t.integer  "company_id",           :default => 100,   :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "service_provider_skills", :force => true do |t|
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at"
    t.boolean  "deleted",              :default => false
    t.integer  "skill_type_id"
    t.integer  "service_provider_id",                     :null => false
    t.integer  "company_id",           :default => 100,   :null => false
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
    t.integer  "user_id"
    t.integer  "company_id",           :default => 100,   :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "service_sessions", :force => true do |t|
    t.text     "description"
    t.integer  "provider_session_id",                    :null => false
    t.integer  "service_assignment_id"
    t.integer  "type_of_service"
    t.integer  "communication_status"
    t.datetime "session_start"
    t.datetime "session_end"
    t.integer  "company_id",            :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "permanent_deleted_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id",                            :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_id",           :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "tasks", :force => true do |t|
    t.integer  "assigned_to_user_id"
    t.integer  "completed_by_user_id"
    t.string   "name",                                       :default => "", :null => false
    t.integer  "asset_id"
    t.string   "asset_type"
    t.string   "priority",                     :limit => 32
    t.datetime "completed_at"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status"
    t.integer  "task_of_type"
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
    t.integer  "employee_user_id",                                                     :null => false
    t.integer  "created_by_user_id"
    t.integer  "activity_type",                                                        :null => false
    t.text     "description",                                                          :null => false
    t.date     "time_entry_date",                                                      :null => false
    t.datetime "start_time"
    t.datetime "end_time"
    t.decimal  "actual_duration",      :precision => 14, :scale => 2,                  :null => false
    t.integer  "billable_type"
    t.integer  "billing_method_type"
    t.decimal  "billing_percent",      :precision => 14, :scale => 2
    t.decimal  "billing_amount",       :precision => 14, :scale => 2
    t.decimal  "std_bill_rate",        :precision => 14, :scale => 2
    t.decimal  "actual_bill_rate",     :precision => 14, :scale => 2
    t.decimal  "final_billed_amount",  :precision => 14, :scale => 2
    t.integer  "accounted_for_type"
    t.integer  "contact_id"
    t.integer  "matter_id"
    t.integer  "company_id",                                          :default => 100, :null => false
    t.datetime "deleted_at"
    t.datetime "permanent_deleted_at"
    t.integer  "updated_by_user_id"
  end

  create_table "users", :force => true do |t|
    t.string   "username",             :limit => 32, :default => "",  :null => false
    t.string   "email",                :limit => 64, :default => "",  :null => false
    t.string   "first_name",           :limit => 32
    t.string   "last_name",            :limit => 32
    t.string   "title",                :limit => 64
    t.string   "company",              :limit => 64
    t.string   "alt_email",            :limit => 64
    t.string   "phone",                :limit => 32
    t.string   "mobile",               :limit => 32
    t.string   "user_type"
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
    t.integer  "contact_id"
    t.integer  "company_id",                         :default => 100, :null => false
    t.datetime "permanent_deleted_at"
  end

  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["last_request_at"], :name => "index_users_on_last_request_at"
  add_index "users", ["perishable_token"], :name => "index_users_on_perishable_token"
  add_index "users", ["persistence_token"], :name => "index_users_on_remember_token"
  add_index "users", ["username", "deleted_at"], :name => "index_users_on_username_and_deleted_at", :unique => true

  
  execute "CREATE OR REPLACE VIEW communication_tasks AS
 SELECT t.id, t.priority, t.company_id, c.assigned_by_employee_user_id, c.created_at AS notes_creation, t.task_of_type, t.assigned_to_user_id, t.status, t.name, t.created_at
   FROM tasks t, notes c
  WHERE t.asset_type = 'Communication' AND t.asset_id = c.id
  ORDER BY c.created_at, t.priority DESC;"


end
