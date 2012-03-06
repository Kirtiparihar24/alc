class TneInvoiceDetail < ActiveRecord::Base
  unloadable
  belongs_to :company
  belongs_to :tne_invoice
  has_many :tne_invoice_time_entries
  accepts_nested_attributes_for :tne_invoice_time_entries, :allow_destroy => true
  has_many :tne_invoice_expense_entries
  accepts_nested_attributes_for :tne_invoice_expense_entries, :allow_destroy => true

  acts_as_paranoid #for soft delete
end
