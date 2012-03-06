
class AddIndexesToLiviaportal < ActiveRecord::Migration

  def self.up
    add_index :accounts, :employee_user_id rescue "Index already exist.."
    add_index :accounts, :assigned_to_employee_user_id rescue "Index already exist.."
    add_index :accounts, :parent_id rescue "Index already exist.."
    add_index :accounts, :company_id rescue "Index already exist.."
    add_index :accounts, :primary_contact_id rescue "Index already exist.."

    add_index :contacts, :campaign_id rescue "Index already exist.."
    add_index :contacts, :assigned_to_employee_user_id rescue "Index already exist.."
    add_index :contacts, :employee_user_id rescue "Index already exist.."
    add_index :contacts, :user_id rescue "Index already exist.."
    add_index :contacts, :company_id rescue "Index already exist.."

    add_index :account_contacts, [:account_id,:contact_id] rescue "Index already exist.."

    add_index :opportunities, :company_id rescue "Index already exist.."
    add_index :opportunities, :employee_user_id rescue "Index already exist.."
    add_index :opportunities, :assigned_to_employee_user_id rescue "Index already exist.."
    add_index :opportunities, :contact_id rescue "Index already exist.."

    add_index :campaigns, :employee_user_id rescue "Index already exist.."
    add_index :campaigns, :company_id rescue "Index already exist.."
    add_index :campaigns, :owner_employee_user_id rescue "Index already exist.."
    add_index :campaigns, :campaign_status_type_id rescue "Index already exist.."

    add_index :campaign_members, :campaign_id rescue "Index already exist.."

    add_index :cluster_users, :cluster_id rescue "Index already exist.."
    add_index :cluster_users, :user_id rescue "Index already exist.."

    add_index :matters, :contact_id rescue "Index already exist.."
    add_index :matters, :employee_user_id rescue "Index already exist.."
    add_index :matters, :company_id rescue "Index already exist.."

    add_index :matter_peoples, :employee_user_id rescue "Index already exist.."
    add_index :matter_peoples, :matter_id rescue "Index already exist.."
    add_index :matter_peoples, :company_id rescue "Index already exist.."
    add_index :matter_peoples, [:start_date,:end_date] rescue "Index already exist.."

    add_index :matter_tasks, :parent_id rescue "Index already exist.."
    add_index :matter_tasks, :assigned_to_matter_people_id rescue "Index already exist.."
    add_index :matter_tasks, :matter_id rescue "Index already exist.."
    add_index :matter_tasks, :company_id rescue "Index already exist.."

    add_index :matter_issues, :company_id rescue "Index already exist.."
    add_index :matter_issues, :matter_id rescue "Index already exist.."

    add_index :matter_facts, :matter_id rescue "Index already exist.."
    add_index :matter_facts, :company_id rescue "Index already exist.."

    add_index :matter_risks, :matter_id rescue "Index already exist.."
    add_index :matter_risks, :company_id rescue "Index already exist.."

    add_index :matter_billings, :company_id rescue "Index already exist.."
    add_index :matter_billings, :matter_id rescue "Index already exist.."

    add_index :document_access_controls, :document_home_id rescue "Index already exist.."
    add_index :document_access_controls, :employee_user_id rescue "Index already exist.."

    add_index :document_homes, :employee_user_id rescue "Index already exist.."
    add_index :document_homes, :owner_user_id rescue "Index already exist.."

    add_index :documents, :employee_user_id rescue "Index already exist.."
    add_index :documents, :document_home_id rescue "Index already exist.."

    add_index :links, :folder_id rescue "Index already exist.."

    add_index :folders, :employee_user_id rescue "Index already exist.."
    add_index :folders, :company_id rescue "Index already exist.."

    add_index :tne_invoices, :company_id rescue "Index already exist.."
    add_index :tne_invoices, :tne_invoice_status_id rescue "Index already exist.."

    add_index :tne_invoice_details, :tne_invoice_id rescue "Index already exist.."

    add_index :tne_invoice_expense_entries, :tne_invoice_id rescue "Index already exist.."
    add_index :tne_invoice_expense_entries, :tne_expense_entry_id rescue "Index already exist.."

    add_index :tne_invoice_time_entries, :tne_invoice_id rescue "Index already exist.."
    add_index :tne_invoice_time_entries, :tne_time_entry_id rescue "Index already exist.."

    add_index :company_dashboards, :dashboard_chart_id rescue "Index already exist.."
    add_index :company_dashboards, [:employee_user_id, :company_id] rescue "Index already exist.."

    add_index :notes, :assigned_by_employee_user_id rescue "Index already exist.."
    add_index :notes, :created_by_user_id rescue "Index already exist.."
    add_index :notes, :assigned_to_user_id rescue "Index already exist.."

    add_index :sticky_notes, :assigned_to_user_id rescue "Index already exist.."
  end

  def self.down
    remove_index :accounts, :column => :employee_user_id
    remove_index :accounts, :column => :assigned_to_employee_user_id
    remove_index :accounts, :column => :parent_id
    remove_index :accounts, :column => :company_id
    remove_index :accounts, :column => :primary_contact_id

    remove_index :contacts, :column => :campaign_id
    remove_index :contacts, :column => :assigned_to_employee_user_id
    remove_index :contacts, :column => :employee_user_id
    remove_index :contacts, :column => :user_id
    remove_index :contacts, :column => :company_id

    remove_index :account_contacts, :column => [:account_id,:contact_id]

    remove_index :opportunities, :column => :company_id
    remove_index :opportunities, :column => :employee_user_id
    remove_index :opportunities, :column => :assigned_to_employee_user_id
    remove_index :opportunities, :column => :contact_id

    remove_index :campaigns, :column => :employee_user_id
    remove_index :campaigns, :column => :company_id
    remove_index :campaigns, :column => :owner_employee_user_id
    remove_index :campaigns, :column => :campaign_status_type_id

    remove_index :campaign_members, :column => :campaign_id

    remove_index :cluster_users, :column => :cluster_id
    remove_index :cluster_users, :column => :user_id

    remove_index :matters, :column => :contact_id
    remove_index :matters, :column => :employee_user_id
    remove_index :matters, :column => :company_id

    remove_index :matter_peoples, :column => :employee_user_id
    remove_index :matter_peoples, :column => :matter_id
    remove_index :matter_peoples, :column => :company_id
    remove_index :matter_peoples, :column => [:start_date,:end_date]

    remove_index :matter_tasks, :column => :parent_id
    remove_index :matter_tasks, :column => :assigned_to_matter_people_id
    remove_index :matter_tasks, :column => :matter_id
    remove_index :matter_tasks, :column => :company_id

    remove_index :matter_issues, :column => :company_id
    remove_index :matter_issues, :column => :matter_id

    remove_index :matter_facts, :column => :matter_id
    remove_index :matter_facts, :column => :company_id

    remove_index :matter_risks, :column => :matter_id
    remove_index :matter_risks, :column => :company_id

    remove_index :matter_billings, :column => :company_id
    remove_index :matter_billings, :column => :matter_id

    remove_index :document_access_controls, :column => :document_home_id
    remove_index :document_access_controls, :column => :employee_user_id

    remove_index :document_homes, :column => :employee_user_id
    remove_index :document_homes, :column => :owner_user_id

    remove_index :documents, :column => :employee_user_id
    remove_index :documents, :column => :document_home_id

    remove_index :links, :column => :folder_id

    remove_index :folders, :column => :employee_user_id
    remove_index :folders, :column => :company_id

    remove_index :tne_invoices, :column => :company_id
    remove_index :tne_invoices, :column => :tne_invoice_status_id

    remove_index :tne_invoice_details, :column => :tne_invoice_id

    remove_index :tne_invoice_expense_entries, :column => :tne_invoice_id
    remove_index :tne_invoice_expense_entries, :column => :tne_expense_entry_id

    remove_index :tne_invoice_time_entries, :column => :tne_invoice_id
    remove_index :tne_invoice_time_entries, :column => :tne_time_entry_id

    remove_index :company_dashboards, :column => :dashboard_chart_id
    remove_index :company_dashboards, :column => [:employee_user_id, :company_id]

    remove_index :notes, :column => :assigned_by_employee_user_id
    remove_index :notes, :column => :created_by_user_id
    remove_index :notes, :column => :assigned_to_user_id

    remove_index :sticky_notes, :column => :assigned_to_user_id
  end
end
