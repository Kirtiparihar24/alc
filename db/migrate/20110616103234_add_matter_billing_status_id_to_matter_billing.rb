class AddMatterBillingStatusIdToMatterBilling < ActiveRecord::Migration
  def self.up
    add_column :matter_billings, :matter_billing_status_id, :integer
  end

  def self.down
    remove_column :matter_billings, :matter_billing_status_id
  end
end
