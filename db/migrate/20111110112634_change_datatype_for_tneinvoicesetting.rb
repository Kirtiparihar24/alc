class ChangeDatatypeForTneinvoicesetting < ActiveRecord::Migration
  def self.up
    change_column :tne_invoice_settings ,:primary_tax_rate ,:float
    change_column :tne_invoice_settings ,:secondary_tax_rate ,:float
  end

  def self.down
    change_column :tne_invoice_settings ,:primary_tax_rate ,:integer
    change_column :tne_invoice_settings ,:secondary_tax_rate ,:integer
  end
end
