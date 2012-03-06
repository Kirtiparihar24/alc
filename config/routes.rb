ActionController::Routing::Routes.draw do |map|
  Jammit::Routes.draw(map)
  map.resources :document_managers, 
    :collection => {
    :get_folders_list_script => :get,
    :documents_list => :get,:folders_tree=>:get,
    :search_document => :get,
    :edit_folder => :get,
    :rename_folder=> :put
  }

  # Feature 6407 - Supriya Surve - 9th May 2011 - route - campaign_mailer_emails
  map.resources :campaign_mailer_emails 
  map.resources :duration_settings
  map.resources  :dynamic_i18ns,:collection=>{:add=>:get,:modify=>:post,:remove=>:get,:replace_word=>:post}
  map.resources :zimbra_configs,:collection=>{:modify=>:post}
  
  map.company_settings '/company_settings', :controller =>'company/utilities',:action=>'company_settings'  
  map.ftp_upload '/ftp_upload', :controller =>'company/utilities',:action=>'ftp_upload'  
  map.get_ftp_folder '/get_ftp_folder', :controller =>'company/utilities',:action=>'get_ftp_folder'  

  map.deactivate_item '/deactivate_item',:controller =>'company/utilities' ,:action=>'deactivate_item'
  map.update_item '/update_item',:controller =>'company/utilities' ,:action=>'update_item'
  map.open_deactivate_form '/open_deactivate_form',:controller =>'company/utilities' ,:action=>'open_deactivate_form'
  map.automate_matter_numbering '/automate_matter_numbering', :controller =>'company/utilities',:action=>'automate_matter_numbering'
  map.reset_sequence '/reset_sequence', :controller =>'company/utilities',:action=>'reset_sequence'
  #map.logo_upload '/logo_upload', :controller =>'companies',:action=>'logo_upload'
  map.upload_logos '/upload_logos', :controller =>'upload_logos'
  
  #map.upload_logo '/logo_upload', :controller =>'upload_logos',:action=>'logo_upload'

  map.resources :zimbra_activities
  map.connect '/assign_licence/assignuser', :controller => 'assign_licence' , :action => 'assignuser'
  map.resources :assign_licence
  map.connect '/assign_licence/index', :controller => 'assign_licence' , :action => 'index'
  map.connect '/assign_licence/populateemployees', :controller => 'assign_licence' , :action => 'populateemployees'

  map.resources :work_subtypes, :collection => {:get_category_work_types => :get, :check_tasks_on_work_complexities => :get}

  map.resources :work_types

  map.resources :categories

  map.resources :company_email_settings,:collection=>{:list=>:get,:edit_individual => :get, :update_individual => :put}

  map.resources :calendars, :collection => {
    :calendar_month => :get,
    :calendar_day => :get,
    :search_matter_people => :get,
    :calendar_by_matter => :get,
    :calendar_by_people => :get,
    :edit_matter_activity => :get,
    :search_assignees => :get,
    :create_activity => [:get, :put],
    :create_matter_activity => :get,
    :edit_activity => :any,
    :edit_zimbra_instance => :get,
    :create_zimbra_instance => :put,
    :instance_series => :get,
    :mark_as_done => [:get, :put],
    :synchronize_appointments => :post
  }
  

  map.resources :utilities, :member => {
    :update_docs => :post,
    :update_user => :post    
  },:collection => {:export_contacts => :get, :set_timer => :get, :fetch_timer => :get}

  map.devise_for :users, :path_names => { :sign_in => 'login', :sign_out => 'logout' }
  map.new_user_session 'login', :controller => 'sessions', :action => 'new', :conditions => { :method => :get }
  map.user_session 'login', :controller => 'sessions', :action => 'create', :conditions => { :method => :post }
  map.single_signon '/sessions/single_signon', :controller => 'sessions', :action => 'single_signon'
  map.destroy_user_session 'logout', :controller => 'sessions', :action => 'destroy', :conditions => { :method => :get }
  map.connect '/sessions/login_from_telephony', :controller => :sessions, :action => :login_from_telephony, :conditions => { :method => :post }
  map.connect '/sessions/check_session_validity', :controller => :sessions, :action => :check_session_validity
  map.resources :configurelookups, :collection=>{:list =>:get}

  map.resources :favourites

  #,:collection=>{:category=>:get,:add_category=>:get},:member=>{:edit_category=>:get}




  map.resources :authorities


  map.resources :designations,:collection=>{:list=>:get}

  map.resources :departments,
    :collection=>{
    :list=>:get,
    :user_list=>:get,
    :sub_department=>:get
  }

  map.resources :product_licence_details

  map.resources :product_licences
  map.view_within_date_range "/communications/view_within_date_range", :controller => 'communications', :action => "view_within_date_range", :method=>:get
  map.connect '/manage_secretary/assign_unassign_serviceprovider', :controller=>'/manage_secretary', :action=>'assign_unassign_serviceprovider'
  map.connect '/manage_secretary/assign_sec_to_emp', :controller=>'/manage_secretary', :action=>'assign_sec_to_emp'
  map.view_managers '/manage_secretary/view_managers', :controller => 'manage_secretary', :action => 'view_managers', :method=>:get
  
  map.connect '/manage_secretary', :controller => 'manage_secretary' , :action => 'index'

  map.resources :manage_secretary ,
    :collection=>{
    :manageprivilege =>:get,
    :livian_access => :get,
    :manager_list=>:get,
    :filter_livian_by_name => :get
  }
  map.secretary_detail '/manage_secretary/secretary_detail/:id', :controller => 'manage_secretary' , :action => 'secretary_detail'
  map.resources :roles
  map.connect '/roles/index', :controller => 'roles' , :action => 'index'
#  map.connect '/roles/populateemployees', :controller => 'roles' , :action => 'populateemployees'
  map.connect 'service_providers/view_deactivated_secretaries', :controller=>'service_providers', :action=>'view_deactivated_secretaries'
  map.connect 'service_providers/activate_secretary', :controller=>'service_providers', :action=>'activate_secretary'
  map.resources :service_providers
  map.get_work_subtupes 'service_providers/get_work_subtupes/:role_id', :controller=>'service_providers', :action=>'get_work_subtupes'
  map.resources :lawfirm_admins,
    :collection=>{
    :permission=>:get,
    :edit_access=>:get,
    :assign=>:put,
    :deactivated_users=>:get,
    :roleassign=>:post,
    :show_licences=>:get
  }
  map.resources:lawfirm_employees,
    :collection=>{
    :update_employee_law=>:put,
    :deactivated_users=>:get
  }
  map.resources :companies,
    :collection =>{
    :portal_usage_report_download => :get,
    :portal_usage_report_employee_list => :get,
    :portal_usage_report_form => :get,
    :portal_usage_report => :get,
    :showusers => :get,
    :deactivated_users => :get,
    :activate_user => :get,
    :clients =>:get,
    :new_client => :get,
    :create_client => :post,
    :matter_documents => :get,
    :company_licences => :get
  } do |company|
    company.resources :employees,
      :member => {
      :editaccess => :get,
      :adduser => :get,
      :deactivated_employees => :get,
      :activate_employee => :get,
      :employee_cluster_mapping => :get
    },
      :collection =>{
      :show_employee_with_cluster => :get
    }

    company.namespace :company do |comp|
      comp.resources :contact_stages
      comp.resources :company_sources
      comp.resources :phases
      comp.resources :liti_types
      comp.resources :nonliti_types
      comp.resources :doc_sources
      comp.resources :activity_types
      comp.resources :expense_types
      comp.resources :research_types
      comp.resources :rating_type
      comp.resources :team_roles
      comp.resources :client_roles
      comp.resources :other_roles
      comp.resources :client_rep_roles
      comp.resources :document_categories
      comp.resources :matter_statuses
      comp.resources :lead_status_types
      comp.resources :prospect_status_types
      comp.resources :matter_privileges
      comp.resources :opportunity_stage_types
      comp.resources :matter_fact_types
      comp.resources :campaign_status_types
      comp.resources :campaign_member_status_types
      comp.resources :document_types  #Added By Pratik.
      comp.resources :salutation_types  #Added By Rahul P.
      comp.resources :task_types
      comp.resources :appointment_types
      comp.resources :company_activity_types
      comp.resources :tne_invoice_statuses # Added By Beena S.
      comp.resources :financial_account_types
      comp.resources :transaction_statuses
      comp.resources :approval_statuses
    end
  end
  map.manage_company_utilities '/manage_company_utilities/:type', :controller =>'company/utilities',:action=>'utility'
  map.new_assignment '/livia_admins/new_assignment/:id', :controller => 'livia_admins', :action => 'new_assignment'
  map.remove_assignment '/livia_admins/remove_assignment/:id', :controller => 'livia_admins', :action => 'remove_assignment'
  map.resources :clusters, :collection => {:update_user_cluster => :get}
  map.resources :company_reports,
    :member => {
    :edit_report_name => :get,
    :update_report_name => :put
  },
    :collection => {:fav_reports => :get}

  map.resources :livia_admins,
    :collection => {
    :company_account_details => :get,
    :cgc_account_details => :get,
    :add_cgc_account=>:put
  },
    :member =>{:delete_association=>:get}

  map.resources :rate_cards
  map.resources :company_role_rates
  map.resources :company_activity_rates
  map.resources :employee_activity_rates
  map.resources :documents
  map.resources :litigations
  map.resources :workspaces,
    :member=>{:move_doc =>:get
  },
    :collection=>{:change_livian_access=>:get,#:search_document => :get, by Pratik 20-09-2011 for feature #8374- since advance seacrh is move to document manager and contextual search is done from document_homes controller.
    :folder_list => :get,
    :create_folder => :any,
    :upload_multi=> :any,
    :do_the_multi_upload=> :any,
    :get_children=>:get,
    :permanent_delete =>:any
  }
  map.resources :repositories,
    :collection=>{ #:search_document => :get, by Pratik 20-09-2011 for feature #8374- since advance seacrh is move to document manager and contextual search is done from document_homes controller.
    :remove_link=> :delete,
    :restore_link =>:get,
    :search_by=> :get,
    :get_sub_categories => :get,
    :create_folder => :any,
    :upload_multi=> :any,
    :do_the_multi_upload=> :any,
    :folder_list => :get,
    :get_children=>:get,
    :mass_upload => :get
  },
    :member=>{
    :add_tags=> :any,
    :move_doc =>:get,
    :move_folder => [:get,:post]
  }
  map.resources :zimbra_mail,
    :collection=>{:savefiletoportal=>:get,
    :business_contacts => :get
  }
  map.resources :product_dependents
  map.connect '/products/product_dropdown_list', :controller=>'/products', :action=>'product_dropdown_list'
  map.resources :products
  map.resources :invoices
  map.resources :subproducts
  map.resources :product_subproducts
  map.connect '/products', :controller => 'products', :action => 'index'
  map.connect '/payments', :controller => 'payments', :action => 'index'
  map.connect '/document_homes/edit_upload_stage', :controller => 'document_homes', :action => 'edit_upload_stage'
  map.connect '/matters/display_selected_matter', :controller => 'matters', :action => 'display_selected_matter'
  map.connect '/matters/search_matter', :controller => 'matters', :action => 'search_matter'
  map.connect '/comments/add_new_comment', :controller => 'comments', :action => 'add_new_comment'
  map.connect '/comments/order_rows', :controller => 'comments', :action => 'order_rows'
  map.connect '/comments/sort_rows', :controller => 'comments', :action => 'sort_rows'
  map.connect '/comments/comment_with_file', :controller => 'comments', :action => 'comment_with_file'
  map.connect '/matters/populatecontactfields', :controller => 'matters', :action => 'populatecontactfields'
  map.connect '/matters/populatecombo', :controller => 'matters', :action => 'populatecombo'
  map.connect "/matters/document_homes/get_document_home", :controller => 'document_homes', :action => 'get_document_home'
  #  map.connect '/zimbra/usersapi/zimbra_contacts/savetoportal', :controller => '/zimbra/usersapi/zimbra_contacts',:action=>'savetoportal'
  #  map.connect '/zimbra/usersapi/zimbra_contacts/getcontactstatus', :controller => '/zimbra/usersapi/zimbra_contacts',:action=>'getcontactstatus'

  map.connect '/set_time_zone/:tz', :controller => 'authentications', :action => 'set_sesssion_time_zone'

  #----------------------------------- contacts Routes---------------------------------

  map.resources :comments,
    :collection=>{:history=>:get,
    :add_comment_with_grid => :get
  }

  map.resources :contacts,:has_many => :comments,
    :collection => {
    :download_format=>:get,
    :download_xls_format=>:get,
    :new_user => :get,
    :create_user => :get,
    :create_matter_contact => :put,
    :upload=> :any,
    :search_contacts=>:get,
    :change_status =>:put,
    :common_contact_search=>:get,
    :display_selected_contact=>:get,
    :attendees_autocomplete => :get,
    :modal_new_form => :get,
    :get_company_contact_stages=>:any
  },
    :member=>{
    :get_contact_info=>:get,
    :create_opportunity=>[:get,:post],
    :deactivate_contact=>:get,
    :activate_contact=>:get,
    :change_status => :get,
    :comments=>:get,
    :download_format=>:get,
    :link_existing_or_created_account=>[:get,:post],
    :link_account=>[:get,:post],
    :ask_activate_account => :get 
  }
  # -------------------------------contacts Routes ends here-------------------------
  #
  # -------------------------------Accounts Routes starts here-------------------------

  # map.connect '/accounts/search_account', :controller => 'accounts', :action => 'search_account'
  #map.connect '/accounts/activate_account', :controller => 'accounts', :action => 'activate_account'
  # map.connect '/accounts/common_account_search', :controller => 'accounts', :action => 'common_account_search'
  # map.connect '/accounts/contacts_to_activate', :controller => 'accounts', :action => 'contacts_to_activate'
  # map.connect '/accounts/activate_contacts', :controller => 'accounts', :action => 'activate_contacts'
  map.resources :accounts, :has_many => :comments,
    :member=>{
    :activate_account=>:post,
    :account_notes=>:get,
    :select_contacts => :get,
    :matters_linked_to_account => :get
  },
    :collection => {
    :add_contact=>:get,
    :activate_account_with_primary =>[:get],
    :activate_contacts=>:put ,
    :display_selected_account=>:get,
    :common_account_search=>:get,
    :upload => :get,
    :populatecombo=>:get,
    :populatecontactfields=>:get, 
    :search_account=>:get,
    :contacts_to_activate=>:get,
    :change_primary_contact=>[:get,:put],
    :remove_contact=>:get,
    :create_new_contact =>:get,
    :validate_new_contact=>:put
  }
  #--------------------------------Accounts Routes ends here-------------------------

  # Matters, and sub module nesting.
  map.resources :matters,
    :member => {
    :comment_form => :get,
    :comments => :get,
    :get_filtered_tasks => :get,
    :save_retainer_fees => :put,
    :new_lead_lawyer => :get,
    :change_lead_lawyer => :post,
    :linked_issues => [:get,:put],
    :linked_facts => [:get,:put],
    :linked_risks => [:get,:put],
    :linked_tasks => [:get,:put],
    :linked_researches => [:get,:put],
    :matter_client_docs => :get,
    :matter_client_comments => :get,
    :delete_matter => :get
  },
    :collection=>{
    :common_matter_search=>:get,
    :populatecombo => :get,
    :all_matter_client_comments => :get,
    :all_matter_client_docs => :get,
    :new_client => :get,
    :get_client_contact => :get,
    :validate_email => :get,
    :get_account_contacts => :get,
    :get_contact_accounts => :get

  } do |matter|
    matter.resources :matter_issues,
      :member => {
      :comment_form => :get,
      :comments => :get,
      :get_tasks_risks_facts => :get,
      :get_issue_resolve => :get,
      :update_issue_resolve => :post,
      :assign_tasks_risks_facts => :post,
      :assign_tasks => :post,
      :show_issue_matter_risks => :get,
      :show_issue_matter_facts => :get,
      :show_issue_matter_tasks => :get,
      :show_issue_matter_researches => :get ###Added for the Feature #7512 - Link task risk issue fact - all to all 
    },
      :collection => {
      :modal_new => :get,
    }

    matter.resources :matter_billing_retainers,
      :collection => {
      :bill_retainers => :get,
      :new_bill_payment_details => :get,
      :create_bill_payment_details => :post,
      :new_retainer => :get,
      :create_retainer => :post,
      :new_bill => :get,
      :new_retainer => :get
    },
      :member => {
      :edit_bill_payment_details => :get,
      :update_bill_payment_details => :post,
      :edit_bill => :get,
      :update_bill => :put,
      :edit_retainer => :get,
      :update_retainer => :put,
      :billing_history => :get
    }

    matter.resources :matter_facts,
      :member => {
      :comment_form => :get,
      :comments => :get,
      :show_fact_matter_issues => :get,
      :get_tasks_risks_researches => :get, ###Added for the Feature #7512 - Link task risk issue fact - all to all
      :assign_tasks_risks_researches => :post ###Added for the Feature #7512 - Link task risk issue fact - all to all
    }
    matter.resources :matter_peoples,
      :member => {
      :access_update => :post,
      :edit_lawteam_member_form => :get,
      :edit_lawteam_member => :put,
      :edit_matter_people_form => :get,
      :edit_matter_people => :put,
      :edit_client_contact_form => :get,
      :edit_client_contact => :put,
      :assign_additional_access => :get,
      :add_to_business_contacts=>:get
    }, :collection => {
      :add_lawteam_member_form => :get,
      :add_lawteam_member => :post,
      :add_client_contact_form => :get,
      :add_client_contact => :post,
      :add_matter_people_form => :get,
      :add_matter_people => :post,
      :edit_matter_access_periods => :get
    }
    matter.resources :matter_risks,
      :member => {
      :comment_form => :get,
      :comments => :get,
      :show_risk_matter_issues => :get,
      :get_tasks_facts_researches => :get, ###Added for the Feature #7512 - Link task risk issue fact - all to all
      :assign_tasks_facts_researches => :post ###Added for the Feature #7512 - Link task risk issue fact - all to all
    }
    matter.resources :matter_tasks,
      :member => {
      :comment_form => :get,
      :show_task_matter_issues => :get,
      :time_expense_entry => :get,
      :new_matter_task => :get,
      :edit_instance => :get,
      :create_instance => :put,
      :complete_task=>:put,
      :comments => :get,
      :mark_as_done => :put,
      :mark_as_done_form => :get,
      :get_issues_facts_risks_researches => :get, ###Added for the Feature #7512 - Link task risk issue fact - all to all
      :assign_issues_facts_risks_researches => :post ###Added for the Feature #7512 - Link task risk issue fact - all to all
    },
      :collection => {
      :get_assignees => :get,
    }


    matter.resources :document_homes,
      :member => {
      :get_document_home => :get,
      :get_doc_history => :get,
      :supercede_document => :get,
      :show_doc_researches => :get,
      :show_doc_risks => :get,
      :show_doc_facts => :get,
      :show_doc_issues => :get,
      :show_doc_tasks => :get,
      :get_tasks_issues_risks_facts_researches => :get, ###Added for the Feature #7512 - Link task risk issue fact - all to all
      :assign_tasks_issues_risks_facts_researches => :post, ###Added for the Feature #7512 - Link task risk issue fact - all to all
      :document_access_control => :any,
      :change_client_access => :any,
      :change_privilege=> :any,
      :upload_interim=>:any
    },
      :collection=>{
      :new_document=>:any,
      :folder_list => :get,
      :create_folder => :any,
      :multi_documents_access_control => :any
    }
    matter.resources :matter_researches,
      :member => {
      :comment_form => :get,
      :comments => :get,
      :show_research_matter_issues=>:get,
      :show_research_matter_risks=>:get,
      :show_research_matter_facts=>:get,
      :show_research_matter_tasks=>:get
    }
    matter.resources :matter_termconditions,
      :member => {:supercede_or_replace_document_form => :get,
      :supercede_or_replace_document => :post,
      :toe_doc_history => :get,
      :toe_docs => :get
    },
      :collection => {
      :toe_multi_upload => :post,
      :toe_multi_upload_form => :get,
      :create_or_update => :post
    }
    matter.resources :matter_documents
    matter.resources :litigations
    matter.namespace(:time_and_expenses, :namespace => 'physical/') do  |time_and_expenses|
      time_and_expenses.matter_view "matter_view" ,:controller=>"time_and_expenses" ,:action => "matter_view"
      time_and_expenses.contact_view "contact_view" ,:controller=>"time_and_expenses" ,:action => "contact_view"
      time_and_expenses.internal "internal" ,:controller=>"time_and_expenses" ,:action => "internal"
    end
  end

  map.resources :matter_clients,
    :member => {
    :client_new_doc => :get,
    :billings =>:get,
    :download_all_client_matter_docs => :get
  }, :collection => {
    :get_tasks_by_date => :get,
    :client_comments => :get
  }

  map.toe_multi_upload "toe_multi_upload/:matter_id/matter", :controller => :matter_termconditions, :action => "toe_multi_upload" ,:method=> "post"
  map.resources :matter_tasks,
    :collection => {
    :create_matter_task_form => :get,
    :create_task_home => :post
  }

  map.matter_details "matter_details/:id",  :controller => :matter_clients,:action => :matter_details
  map.task_details "task_details/:id", :controller => :matter_clients, :action => "task_details"

  map.update_task_div "update_task_div/:id", :controller => :matter_clients, :action => "update_task_div"
  # The priority is based upon order of creation: first created -> highest priority.
  map.root      :controller => "home", :action => "index"
  map.resource  :authentication,:member=>{:password => :get}
  map.resources :users,
    :member => {
    :reset_password_form => :get,
    :reset_password => :post,
    :avatar => :get, :upload_avatar => :put, :change_password => [:get,:put]
  },
    :collection => {:check_exisitng => :get}
  map.resources :passwords
  map.resources :comments,
    :member => {
    :add_new_comment => :post,
    :mark_read => :post
  }
  map.resources :tasks, :has_many => :comments,
    :member => { :complete => :put }


  map.resources :company

  

  map.resources :campaigns, :has_many => :comments,
    :collection => {
    :search => :get,
    :auto_complete => :post,
    :options => :get,
    :redraw => :post,
    :common_campaign_search=>:get,
    :delete_attachment => :post, 
    :get_my_all_campaigns => :get,
    :search_campaign => :get,
    :sphinx_search_campaign=>:get,
    :display_selected_campaign => :get,
    :import_extra_members=>:get,
    :show_help=>:get,
    :show_xls_help=>:get,
    :show_reason=>:get
  },
    :member => {:show_response=>:get,
    :unattented_list => :get,
    :suspended_list => :get
  }
  map.connect '/campaigns/activate_camp',:controller=>'campaigns',:action=>'activate_camp'
  map.connect '/communications/search_contact', :controller => 'communications', :action => 'search_contact'
  map.connect '/communications/sort', :controller => 'communications', :action => 'sort'
  map.connect '/communications/eligible_secretaries', :controller => 'communications', :action => 'eligible_secretaries'

  #map.connect '/communications/named_views_contacts', :controller => 'communications', :action => 'named_views_contacts'
  map.named_views_contacts 'named_views_contacts/:sort_key/:sort_order', :controller => 'communications', :action => 'named_views_contacts'
  map.named_views_accounts 'named_views_accounts/:sort_key/:sort_order', :controller => 'communications', :action => 'named_views_accounts'
  map.named_views_opportunities 'named_views_opportunities/:sort_key/:sort_order', :controller => 'communications', :action => 'named_views_opportunities'
  map.named_views_matters 'named_views_matters/:sort_key/:sort_order', :controller => 'communications', :action => 'named_views_matters'
  map.named_views_secretarys_task 'named_views_secretarys_task', :controller => 'communications', :action => 'named_views_secretarys_task'
  map.named_views_my_task 'named_views_my_task', :controller => 'communications', :action => 'named_views_my_task'
  map.connect '/communications/add_new_record', :controller => 'communications', :action => 'add_new_record'
  map.get_call_recording '/communications/get_call_recording/:call_id', :controller => 'communications', :action => 'get_call_recording'
  
  #map.connect '/physical/liviaservices/livia_secretaries/search_lawyer', :controller => 'livia_secretaries', :action => 'search_lawyer'
   #map.connect '/communications/get_matter_info', :controller => 'communications', :action => 'get_matter_info'
   map.resources :communications,
     :collection=>{:get_matter_details => :get,
     :search_matters_contacts => :get}



  map.resources :document_homes,
    :member=>  {
    :supercede_document => :get,
    :supercede=>:any,
    :restore_document=>:get,
    :restore_folder=>:get,
    :supercede_or_replace_document => :get,
    :supercede_with_client_document=>:get,
    :get_doc_history=>:get,
    :check_uncheck_doc => :get,
    :temp_delete=> :delete,
    :temp_delete_folder=> :delete,
    :wip_doc_action => :any,
    :move_doc =>:get,
    :edit_doc_link => :get,
    :update_doc_link => :put
  },
    :collection=> {
    :check_out_all => :get,
    :upload_document => :get,
    :get_children => :get,
    :search_document => :get,
    :move_multiple_doc => :any,
  }

 
  map.connect '/opportunities/display_selected_opportunity', :controller => 'opportunities', :action => 'display_selected_opportunity'
  map.connect '/opportunities/search_opportunity', :controller => 'opportunities', :action => 'search_opportunity'
  map.connect '/opportunities/get_my_all_opportunities', :controller => 'opportunities', :action => 'get_my_all_opportunities'
  map.connect '/opportunities/populatecontactfields',:controller=>'opportunities',:action=>'populatecontactfields'
  map.connect '/opportunities/populatecombo',:controller=>'opportunities',:action=>'populatecombo'
  map.connect '/opportunities/activate_opp',:controller=>'opportunities',:action=>'activate_opp'
  map.imports_file '/import_data/imports_files', :controller => 'import_data', :action => 'imports_files'
  map.resources :opportunities, :has_many => :comments,
    :collection => {
    :display_selected_opportunity=>:get,
    :common_opportunity_search=>:get,
    :upload=> :get,
    :clear_follow_up_date=>:put,
    :sort_opportunities_columns => :any,
    :get_company_source_name=>:any
  },
    :member=>{
    :save_status=>:post
  }

  map.signup  "signup",  :controller => "users",           :action => "new"
  map.profile "profile", :controller => "users",           :action => "show"
  map.set_user_time_zone "/set_user_time_zone/:id", :controller => "users",           :action => "set_user_time_zone"
  #map.login   "login",   :controller => "sessions", :action => "new"
  #map.logout  "logout",  :controller => "sessions", :action => "destroy"
  #map.connect '/logout',:controller => "users", :action => "sign_out"
  map.import_leads "import_leads", :controller => "leads", :action => "import_leads_from_file"
  #  map.confirm_password "confirm_password", :controller => "authentications", :action => "confirm_password"
  #  map.authenticate "authenticate", :controller => "authentications", :action => "authenticate"

  map.support  "support",  :controller => "home",           :action => "support"
  map.resources :home , :collection=>{:get_suggestions=>:get, :get_ticket_sub_types=>:get, :get_sub_products => :get, :support=>:get, :helpdesk=>:get}
  map.helpdesk  "helpdesk",  :controller => "home",           :action => "helpdesk"
  map.connect '/physical/timeandexpenses/time_and_expenses/get_matters_contact',:controller =>'/physical/timeandexpenses/time_and_expenses', :action => 'get_matters_contact'
  map.connect '/physical/timeandexpenses/time_and_expenses/get_all_matters',:controller =>'/physical/timeandexpenses/time_and_expenses', :action => 'get_all_matters'
  map.connect '/physical/timeandexpenses/time_and_expenses/get_expense_matters_contact',:controller =>'/physical/timeandexpenses/time_and_expenses', :action => 'get_expense_matters_contact'
  map.connect '/physical/timeandexpenses/time_and_expenses/get_all_expense_matters',:controller =>'/physical/timeandexpenses/time_and_expenses', :action => 'get_all_expense_matters'
  map.time_entry_matter_search '/physical/timeandexpenses/time_and_expenses/time_entry_matter_search/:employee_id', :controller => '/physical/timeandexpenses/time_and_expenses', :action => 'time_entry_matter_search'
  map.connect '/physical/clientservices/home/search_result', :controller => '/physical/clientservices/home', :action => 'search_result'
  map.connect '/physical/clientservices/home/render_fusion_chart', :controller => '/physical/clientservices/home', :action => 'render_fusion_chart'
  map.connect '/physical/clientservices/home/display_full_view_of_dashboard', :controller => '/physical/clientservices/home', :action => 'display_full_view_of_dashboard'
  map.connect '/physical/clientservices/home/upload_documents', :controller => '/physical/clientservices/home', :action => 'upload_documents'
  map.connect "logged_exceptions/:action/:id", :controller => "logged_exceptions"
  map.connect 'get_opp_upcoming_setting_value',:controller => '/physical/clientservices/home', :action => 'get_opp_upcoming_setting_value',:method=>:get
  map.namespace :zimbra do |zm|
    zm.namespace :usersapi do|u|
      u.resources :zimbra_contacts,
        :collecton=>{:create_contact=>:post}
      u.resources :zimbra_attachment ,
        :collection=>{
        :upload_mail_attachment=>[:get,:put],
        :get_company_name=>:get
      }
    end
  end

  map.namespace :physical do |liv|
    #Mapping routes for Firms module
    liv.namespace(:clientservices, :namespace => 'physical/') do  |clientservice|
      clientservice.view_matter_tasks 'view_matter_tasks',  :controller => 'home', :action => 'view_matter_tasks'
      clientservice.livian_instruction 'livian_instruction',  :controller => 'home', :action => 'livian_instuction'
      clientservice.time_expense_entry 'time_expense_entry', :controller => 'home', :action => 'time_expense_entry'
      clientservice.new_matter_task 'new_matter_task', :controller => 'home', :action => 'new_matter_task'
      clientservice.new_opportunity 'new_opportunity', :controller => 'home', :action => 'new_opportunity'
      clientservice.resources :home, :collection => {:options => :get}
      clientservice.add_new_record 'add_new_record', :controller => 'home', :action => 'add_new_record'
      clientservice.get_opportunities_graph 'get_opportunities_graph', :controller => 'home', :action => 'get_opportunities_graph'
      clientservice.billing_amount_graph 'billing_amount_graph', :controller => 'home', :action => 'billing_amount_graph'
      clientservice.contact_graph 'contact_graph', :controller => 'home', :action => 'contact_graph'
      clientservice.matter_task_chart_graph 'matter_task_chart_graph', :controller => 'home', :action => 'matter_task_chart_graph'
      clientservice.show_favourites 'show_favourites', :controller => 'home', :action => 'show_favourites'
      clientservice.add_to_favourite 'add_to_favourite', :controller => 'home', :action => 'add_to_favourite'
      clientservice.delete_favourite 'delete_favourite', :controller => 'home', :action => 'delete_favourite'
      clientservice.show_rssfeed 'show_rssfeed', :controller => 'home', :action => 'show_rssfeed'
      clientservice.new_repository 'new_repository', :controller => 'home', :action => 'new_repository'
      clientservice.new_repository 'new_workspace', :controller => 'home', :action => 'new_workspace'
      clientservice.create_repository 'create_repository', :controller => 'home', :action => 'create_repository'
      clientservice.move_to_workspace_rss 'move_to_workspace_rss', :controller => 'home', :action => 'move_to_workspace_rss'
      clientservice.fav_form 'fav_form', :controller => 'home', :action => 'fav_form'
      clientservice.edit_favourite 'edit_favourite', :controller => 'home', :action => 'edit_favourite'
      clientservice.add_to_fav 'add_to_fav', :controller => 'home', :action => 'add_to_fav'
      clientservice.update_favourite 'update_favourite', :controller => 'home', :action => 'update_favourite'
      clientservice.create_contact 'create_contact', :controller => 'home', :action => 'create_contact'
      clientservice.create_opportuntiy 'create_opportuntiy', :controller => 'home', :action => 'create_opportuntiy'
      clientservice.about 'about', :controller => 'home', :action => 'about'
      clientservice.check_logout 'check_logout', :controller => 'home', :action => 'check_logout', :method => :get

    end

    #Mapping routes for the Time And Expense Module
    liv.namespace(:timeandexpenses ,:namespace => 'physical/') do |timeexpense|
      timeexpense.resources :time_and_expenses,:collection =>{ :new_time_entry_home => :get,:create_new_home => :post, :split_entries => :get, :split_entries_div => :get, :update_split_duration => :get}
      timeexpense.internal   "internal" ,:controller=>"time_and_expenses" ,:action => "internal"
      timeexpense.unexpired_matters   "unexpired_matters" ,:controller=>"time_and_expenses" ,:action => "unexpired_matters"
      timeexpense.matter_view   "matter_view" ,:controller=>"time_and_expenses" ,:action => "matter_view"
      timeexpense.contact_view   "contact_view" ,:controller=>"time_and_expenses" ,:action => "contact_view"
      timeexpense.calendar   "calendar" ,:controller=>"time_and_expenses" ,:action => "calendar"
      timeexpense.get_time_difference "get_time_difference",:controller => "time_and_expenses",:action =>"get_time_difference"
      timeexpense.get_all_matters "get_all_matters",:controller => "time_and_expenses",:action =>"get_all_matters"
      timeexpense.get_all_expense_matters "get_all_expense_matters",:controller => "time_and_expenses",:action =>"get_all_expense_matters"
      timeexpense.get_expense_matters_contact "get_expense_matters_contact",:controller => "time_and_expenses",:action =>"get_expense_matters_contact"
      timeexpense.get_all_new_matters "get_all_new_matters",:controller => "time_and_expenses",:action =>"get_all_new_matters"
      timeexpense.get_new_matters_contact "get_new_matters_contact",:controller => "time_and_expenses",:action =>"get_new_matters_contact"
      timeexpense.set_matters_contact "set_matters_contact",:controller => "time_and_expenses",:action =>"set_matters_contact"
      timeexpense.get_all_new_matters_for_expenses "get_all_new_matters_for_expenses",:controller => "time_and_expenses",:action =>"get_all_new_matters_for_expenses"
      timeexpense.get_new_matters_contact_for_expenses "get_new_matters_contact_for_expenses",:controller => "time_and_expenses",:action =>"get_new_matters_contact_for_expenses"      
      timeexpense.new_time_entry "new_time_entry",:controller =>"time_and_expenses",:action=>"new_time_entry"
      timeexpense.get_billing_percent "get_billing_percent",:controller =>"time_and_expenses",:action=>"get_billing_percent"
      timeexpense.calculate_billing_amount_per_duration "calculate_billing_amount_per_duration",:controller =>"time_and_expenses",:action =>"calculate_billing_amount_per_duration"
      timeexpense.save_and_add_expense "save_and_add_expense",:controller =>"time_and_expenses",:action => "save_and_add_expense"
      timeexpense.add_expense_entry "add_expense_entry",:controller => "time_and_expenses" ,:action=>"add_expense_entry"
      timeexpense.add_expense_entry_home "add_expense_entry_home",:controller => "time_and_expenses" ,:action=>"add_expense_entry_home"
      timeexpense.get_summary_header "get_summary_header",:controller =>"time_and_expenses",:action =>"get_summary_header"
      timeexpense.get_billing_activity_rate "get_billing_activity_rate",:controller =>"time_and_expenses",:action =>"get_billing_activity_rate"
      timeexpense.get_activity_rate "get_activity_rate",:controller =>"time_and_expenses",:action =>"get_activity_rate"
      timeexpense.set_expense_entry_status "set_expense_entry_status",:controller => "time_and_expenses",:action=>"set_expense_entry_status"
      timeexpense.set_time_entry_status "set_time_entry_status",:controller => "time_and_expenses",:action=>"set_time_entry_status"
      timeexpense.get_lawyers_matters_contacts "get_lawyers_matters_contacts",:controller => 'time_and_expenses',:action=>'get_lawyers_matters_contacts'
      timeexpense.approval_awaiting_entry "approval_awaiting_entry" ,:controller=>"time_and_expenses" ,:action => "approval_awaiting_entry"
      timeexpense.approve_entries "approve_entries" ,:controller=>"time_and_expenses" ,:action => "approve_entries"
    end

    liv.namespace(:expense_entries ,:namespace => 'physical/') do |expense_entries|
      expense_entries.calculate_discount_rate_for_expense_entry "calculate_discount_rate_for_expense_entry",:controller =>"expense_entries",:action =>"calculate_discount_rate_for_expense_entry"
      expense_entries.set_expense_is_billable "set_expense_is_billable",:controller =>"expense_entries",:action =>"set_expense_is_billable"
      expense_entries.set_expense_entry_description "set_expense_entry_description",:controller =>"expense_entries",:action =>"set_expense_entry_description"
      expense_entries.set_expense_entry_expense_type "set_expense_entry_expense_type",:controller =>"expense_entries",:action =>"set_expense_entry_expense_type"
      expense_entries.set_expense_entry_expense_amount "set_expense_entry_expense_amount",:controller =>"expense_entries",:action =>"set_expense_entry_expense_amount"
      expense_entries.set_expense_entry_billing_percent "set_expense_entry_billing_percent",:controller =>"expense_entries",:action =>"set_expense_entry_billing_percent"
      expense_entries.set_expense_entry_markup "set_expense_entry_markup",:controller =>"expense_entries",:action =>"set_expense_entry_markup"
      expense_entries.set_expense_entry_billing_amount "set_expense_entry_billing_amount",:controller =>"expense_entries",:action =>"set_expense_entry_billing_amount"
      expense_entries.set_expense_entry_full_amount "set_expense_entry_full_amount",:controller =>"expense_entries",:action =>"set_expense_entry_full_amount"
    end

    liv.namespace(:time_entries ,:namespace => 'physical/') do |time_entries|
      time_entries.set_is_billable "set_is_billable",:controller => "time_and_expenses",:action=>"set_is_billable"
      time_entries.set_time_entry_description "set_time_entry_description",:controller =>"time_and_expenses",:action =>"set_time_entry_description"
      time_entries.set_time_entry_actual_bill_rate "set_time_entry_actual_bill_rate",:controller =>"time_and_expenses",:action =>"set_time_entry_actual_bill_rate"
      time_entries.set_time_entry_activity_type "set_time_entry_activity_type",:controller =>"time_and_expenses",:action =>"set_time_entry_activity_type"
      time_entries.set_time_entry_billing_percent "set_time_entry_billing_percent",:controller =>"time_and_expenses",:action =>"set_time_entry_billing_percent"
      time_entries.set_time_entry_full_amount "set_time_entry_full_amount",:controller =>"time_and_expenses",:action =>"set_time_entry_full_amount"
      time_entries.set_time_entry_billing_amount "set_time_entry_billing_amount",:controller =>"time_and_expenses",:action =>"set_time_entry_billing_amount"
      time_entries.set_time_entry_actual_duration "set_time_entry_actual_duration",:controller =>"time_and_expenses",:action =>"set_time_entry_actual_duration"
    end

    liv.namespace(:liviaservices, :namespace => 'physical/') do  |liviaservice|
      liviaservice.assign_lawyer "livia_secretaries/assign_lawyer/:employee_id", :controller => 'livia_secretaries', :action => "assign_lawyer"
      liviaservice.show_lawyer_list "livia_secretaries/show_lawyer_list", :controller => 'livia_secretaries', :action => "show_lawyer_list"
      liviaservice.set_service_provider_id_by_telephony "livia_secretaries/set_service_provider_id_by_telephony", :controller => 'livia_secretaries', :action => "set_service_provider_id_by_telephony"
      liviaservice.search_lawyer "livia_secretaries/search_lawyer", :controller => 'livia_secretaries', :action => "search_lawyer"
      liviaservice.get_next_task "livia_secretaries/get_next_task", :controller => 'livia_secretaries', :action => 'get_next_task'
      liviaservice.assign_skill "liviaservices/assign_skill", :controller => 'liviaservices', :action => 'assign_skill'
      liviaservice.assign_skill "liviaservices/assign_skill2", :controller => 'liviaservices', :action => 'assign_skill2'
      liviaservice.pick_skills_for_lilly "liviaservices/pick_skills_for_lilly", :controller => 'liviaservices', :action => 'pick_skills_for_lilly'
      liviaservice.pick_skills_for_lilly2 "liviaservices/pick_skills_for_lilly2", :controller => 'liviaservices', :action => 'pick_skills_for_lilly2'
      liviaservice.assign_skills "liviaservices/assign_skills", :controller => 'liviaservices', :action => 'assign_skills'
      liviaservice.unassign_skills "liviaservices/unassign_skills", :controller => 'liviaservices', :action => 'unassign_skills'
      liviaservice.find_for_skill "liviaservices/find_for_skill", :controller => 'liviaservices', :action => 'find_for_skill'
      liviaservice.managers_portal "managers_portal", :controller => 'liviaservices', :action => "managers_portal"
      liviaservice.resources 'liviaservices'
      liviaservice.resources 'skill_types'
      liviaservice.resources 'service_providers', :active_scaffold => true
      liviaservice.resources 'service_provider_skills', :active_scaffold => true
      liviaservice.add_assignment "liviaservices/add_assignment/:id", :controller => 'liviaservices', :action => "add_assignment"
      liviaservice.secratary_details_task_list "secratary_details_task_list/:id", :controller => 'liviaservices', :action => "secratary_details_task_list"
      liviaservice.secratary_details_notes_list "secratary_details_notes_list/:id", :controller => 'liviaservices', :action => "secratary_details_notes_list"
      liviaservice.managers_select_option "managers_select_option/:id", :controller => 'liviaservices', :action => "managers_select_option"
      liviaservice.deactivate_assignment "liviaservices/deactivate_assignment/:id", :controller => 'liviaservices', :action => "deactivate_assignment"
      #liviaservice.connect "livia_secretaries/", :controller => 'livia_secretaries', :action => "index"
      liviaservice.resources :livia_secretaries, :collection => {:options => :get}
      liviaservice.connect "verification/:id", :controller => 'verification', :action => "index"
      liviaservice.connect "verification/:id/verify", :controller => 'verification', :action => "verify_lawyer"
      liviaservice.about 'about', :controller => 'liviaservices', :action => 'about'
    end
  end

  map.resources :attachments



  map.resources :import_data,:collection=>{:download_format_for_contact=>:get}

  map.resources :sticky_notes,:collection => {:set_flag_for_sticky_note=>:get}


  #routes for manage cluster
  map.resources :manage_cluster, :member => { :unassign_livian => :post, :unassign_lawfirm_user => :post },:collection =>{:show_assigned_cluster_employee_list=>:get}
  map.connect '/manage_cluster/assign_unassign_employee', :controller=>'/manage_cluster', :action=>'assign_unassign_employee'
  map.connect '/manage_cluster/assign_sec_to_cluster', :controller=>'/manage_cluster', :action=>'assign_sec_to_cluster'
  map.connect '/manage_cluster/update_priority', :controller=>'/manage_cluster', :action=>'update_priority'
  #  map.connect '/manage_cluster/unassign_lawfirm_user', :controller=>'/manage_cluster', :action=>'unassign_lawfirm_user', :method=> 'post'
  map.show_cluster_list '/manage_cluster/show_cluster_list/:id/:user_type', :controller=>'/manage_cluster', :action=>'show_cluster_list'


  map.resources :access_codes
  map.reset_tpin_form '/access_codes/reset_tpin_form/:id', :controller=>'access_codes', :action=>'reset_tpin_form'
  map.reset_tpin '/access_codes/reset_tpin/:id', :controller=>'access_codes', :action=>'reset_tpin'
  map.resources :security_questions

  #Financial Account Routes
  map.resources :financial_accounts,:collection => {:search => :get,:matters => :get,:client_view => :get}, :member => {:advanced_filter => [:get, :post]} do |financial_account|
    financial_account.resources :financial_transactions,:member=>{:update_payment => [:get,:post],:update_inter_transfer => [:get,:post]},:collection => {:record_payment=>[:get,:post],:inter_transfer =>[:get,:post]}
  end
 map.financial_account_specific_to_client '/financial_account/:financial_account_id/client_specific/:client_id', :controller => :financial_accounts, :action => :client_specific, :method => :get
 map.financial_transaction_client_contacts_or_invoice_no '/financial_transactions/invoice_or_contacts/:matter_id', :controller => :financial_transactions, :action => :client_contacts, :method => :get
  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect 'excel_imports', :controller => 'excel_imports'

  map.import_records 'excel_imports/import', :controller => 'excel_imports',:action=>"import",:method=>:post
  
  map.download_template 'excel_imports/download_template', :controller => 'excel_imports',:action=>"download_template",:method=>:get

  map.connect 'excel_imports/contact_import', :controller => 'excel_imports',:action=>"contact_import",:method=>:post
  map.connect 'excel_imports/contact_import_from_invalid_records', :controller => 'excel_imports',:action=>"contact_import_from_invalid_records",:method=>:post
  map.download_invalid_excel_file 'excel_imports/download_invalid_excel_file', :controller => 'excel_imports',:action=>"download_invalid_excel_file",:method=>:get
  map.download_original_import_file '/import_histories/download_original_import_file/:id', :controller=>'import_histories', :action=>'download_original_import_file'

  map.download_invalid_import_file '/import_histories/download_invalid_import_file/:id', :controller=>'import_histories', :action=>'download_invalid_import_file'
  map.display_contact_import_histories '/import_histories/display_contact_import_histories', :controller=>'import_histories', :action=>'display_contact_import_histories'

  map.connect 'excel_imports/matter_import', :controller => 'excel_imports',:action=>"matter_import",:method=>:post
  map.connect 'excel_imports/matter_import_from_invalid_records', :controller => 'excel_imports',:action=>"matter_import_from_invalid_records",:method=>:post
  map.display_matter_import_histories '/import_histories/display_matter_import_histories', :controller=>'import_histories', :action=>'display_matter_import_histories'

  map.display_import_history '/import_histories/display_import_histories', :controller=>'import_histories', :action=>'display_import_histories'
  
  map.connect 'import_histories', :controller => 'import_histories'
  map.connect ":controller/:action/:uuid", :uuid => /[a-f\d\-]{36}/
  map.connect ":controller/:action/:uuid.:format", :uuid => /[a-f\d\-]{36}/
  map.connect ":controller/:action/:id"
  map.connect ":controller/:action/:id.:format"
  map.connect ":controller/:action"  
end
