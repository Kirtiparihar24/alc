class ChangeIntegerColumnsToFloatForMultipleTables < ActiveRecord::Migration
  def self.up
    change_column :company_activity_rates,	:billing_rate, :decimal, :precision => 14, :scale => 2
    change_column :company_role_rates,	:billing_rate, :decimal, :precision => 14, :scale => 2

    change_column :employee_activity_rates, :billing_rate, :decimal, :precision => 14, :scale => 2

    change_column :employees,	:billing_rate, :decimal, :precision => 14, :scale => 2

    change_column :invoice_details,	:total_amount, :decimal, :precision => 14, :scale => 2
    change_column :invoice_details,	:cost, :decimal, :precision => 14, :scale => 2
    change_column :invoice_details,	:count, :decimal, :precision => 14, :scale => 2

    change_column :invoices,	:invoice_amount, :decimal, :precision => 14, :scale => 2

    change_column :licences,	:cost, :decimal, :precision => 14, :scale => 2

    change_column :matter_billings,	:bill_amount, :decimal, :precision => 14, :scale => 2
    change_column :matter_billings,	:bill_amount_paid, :decimal, :precision => 14, :scale => 2

    change_column :matter_retainers,	:amount, :decimal, :precision => 14, :scale => 2

    # They were strings!! :(
=begin
    change_column :matter_termconditions, :billing_value, :decimal, :precision => 14, :scale => 2
    change_column :matter_termconditions,	:retainer_amount, :decimal, :precision => 14, :scale => 2
    change_column :matter_termconditions,	:not_to_exceed_amount, :decimal, :precision => 14, :scale => 2
    change_column :matter_termconditions,	:min_trigger_amount, :decimal, :precision => 14, :scale => 2
    change_column :matter_termconditions,	:fixed_rate_amount, :decimal, :precision => 14, :scale => 2
=end
    
    change_column :matters,	:retainer_fee, :decimal, :precision => 14, :scale => 2
    change_column :matters,	:min_retainer_fee, :decimal, :precision => 14, :scale => 2

    change_column :opportunities,	:amount, :decimal, :precision => 14, :scale => 2
    change_column :opportunities,	:discount, :decimal, :precision => 14, :scale => 2

    change_column :payments,	:amount, :decimal, :precision => 14, :scale => 2

    change_column :product_licences,	:licence_cost, 	:decimal, :precision => 14, :scale => 2

    change_column :products,	:cost, :decimal, :precision => 14, :scale => 2

    change_column :time_entries,	:activity_rate, :decimal, :precision => 14, :scale => 2

    change_column :tne_invoice_details,	:amount, :decimal, :precision => 14, :scale => 2
    change_column :tne_invoice_details,	:rate, :decimal, :precision => 14, :scale => 2
    
    change_column :tne_invoice_settings,	:primary_tax_rate, :decimal, :precision => 14, :scale => 2
    change_column :tne_invoice_settings,	:secondary_tax_rate, :decimal, :precision => 14, :scale => 2

    change_column :tne_invoices,	:invoice_amt, :decimal, :precision => 14, :scale => 2
    change_column :tne_invoices,	:primary_tax_rate, :decimal, :precision => 14, :scale => 2
    change_column :tne_invoices,	:secondary_tax_rate, :decimal, :precision => 14, :scale => 2
    change_column :tne_invoices,	:discount, :decimal, :precision => 14, :scale => 2
    change_column :tne_invoices, :final_invoice_amt, :decimal, :precision => 16, :scale => 2

    change_column :tne_invoice_expense_entries, :markup, :float
    change_column :tne_invoice_expense_entries, :final_expense_amount, :decimal, :precision => 16, :scale => 2

    change_column :tne_invoice_time_entries, :final_billed_amount, :decimal, :precision => 16, :scale => 2
  end

  def self.down
    change_column :company_activity_rates,	:billing_rate, :decimal, :precision => 10, :scale => 2
    change_column :company_role_rates,	:billing_rate, :decimal, :precision => 10, :scale => 2

    change_column :employee_activity_rates, :billing_rate, :decimal

    change_column :employees,	:billing_rate, :integer

    change_column :invoice_details,	:total_amount, :decimal, :precision => 12, :scale => 2
    change_column :invoice_details,	:cost, :decimal, :precision => 12, :scale => 2
    change_column :invoice_details,	:count, :decimal, :precision => 12, :scale => 2

    change_column :invoices,	:invoice_amount, :decimal, :precision => 12, :scale => 2
   
    change_column :licences,	:cost, :integer

    change_column :matter_billings,	:bill_amount, :float
    change_column :matter_billings,	:bill_amount_paid, :integer

    change_column :matter_retainers,	:amount, :integer

    # They were strings!! :(
=begin
    change_column :matter_termconditions, :billing_value, :string, :length => 255
    change_column :matter_termconditions,	:retainer_amount, :string, :length => 64
    change_column :matter_termconditions,	:not_to_exceed_amount, :string, :length => 64
    change_column :matter_termconditions,	:min_trigger_amount, :string, :length => 64
    change_column :matter_termconditions,	:fixed_rate_amount, :string, :length => 64
=end
    change_column :matters,	:retainer_fee, :integer
    change_column :matters,	:min_retainer_fee, :integer

    change_column :opportunities,	:amount, :decimal, :precision => 12, :scale => 2
    change_column :opportunities,	:discount, :decimal, :precision => 12, :scale => 2

    change_column :payments,	:amount, :integer

    change_column :product_licences,	:licence_cost, 	:float

    change_column :products,	:cost, :integer

    change_column :time_entries,	:activity_rate, :decimal, :precision => 12, :scale => 2

    change_column :tne_invoice_details,	:amount, :float
    change_column :tne_invoice_details,	:rate, :integer

    change_column :tne_invoice_settings,	:primary_tax_rate, :integer
    change_column :tne_invoice_settings,	:secondary_tax_rate, :integer

    change_column :tne_invoices,	:invoice_amt, :float
    change_column :tne_invoices,	:primary_tax_rate, :integer
    change_column :tne_invoices,	:secondary_tax_rate, :integer
    change_column :tne_invoices,	:discount, :integer
    change_column :tne_invoices, :final_invoice_amt, :float

    change_column :tne_invoice_expense_entries, :markup, :integer
    change_column :tne_invoice_expense_entries, :final_expense_amount, :decimal, :precision => 14, :scale => 2
    
    change_column :tne_invoice_time_entries, :final_billed_amount, :decimal, :precision => 14, :scale => 2
  end
end
