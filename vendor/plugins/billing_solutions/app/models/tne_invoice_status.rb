# To change this template, choose Tools | Templates
# and open the template in the editor.

class TneInvoiceStatus < CompanyLookup
  belongs_to :company
  has_many :tne_invoices
  default_scope :order => "sequence ASC"
  # Bug #8844 added default scope sequence--Beena Shetty --05/09/2011
  validates_presence_of :lvalue ,:message=>"Status Cant be blank"
end
