class TneInvoiceSetting < ActiveRecord::Base
  unloadable
  belongs_to :company
  validates_presence_of :primary_tax_rate, :message => :primary_tax_rate, :if => Proc.new { |tne_invoice_setting| tne_invoice_setting.primary_tax_enable == true }
  validates_presence_of :secondary_tax_rate, :message => :secondary_tax_rate, :if => Proc.new { |tne_invoice_setting| tne_invoice_setting.secondary_tax_enable == true }
  validates_numericality_of :primary_tax_rate, :message => :primary_tax_rate_numerical, :if => Proc.new { |tne_invoice_setting| tne_invoice_setting.primary_tax_enable == true }
  validates_numericality_of :secondary_tax_rate, :message => :secondary_tax_rate_numerical, :if => Proc.new { |tne_invoice_setting| tne_invoice_setting.secondary_tax_enable == true }
  before_save :set_tax_fileds_value

  #  Checks primary_tax_enable field, if false, updates the dependent field values to blank string or 0 to ensure data integrity
  def set_tax_fileds_value
    if self.primary_tax_enable == false
      self.primary_tax_name = ''
      self.primary_tax_rate = 0.0
      self.secondary_tax_name = ''
      self.secondary_tax_rate = 0.0
    end
    if self.secondary_tax_enable == false
      self.secondary_tax_name = ''
      self.secondary_tax_rate = 0.0
    end
  end

end
