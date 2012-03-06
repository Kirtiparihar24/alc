
namespace :update do
  task :matter_billing_status => :environment do
    
    billing = MatterBilling.find(:all,:conditions => ["automate_entry = true AND tne_invoice_id is not null"])
    billing.each do |bill|
      invoice=  TneInvoice.find_by_id( bill.tne_invoice_id, :with_deleted => true) rescue nil
      MatterBilling.update_all({:matter_billing_status_id => invoice.tne_invoice_status_id}, {:id => bill.id})
    end

  end
end

