namespace :add_matter_billing do
  task :for_invoice => :environment do
    invoices = TneInvoice.find(:all, :conditions => ["matter_id is not null"])
    invoices.each do |invoice|
      invoice.add_or_update_matter_billing
    end
  end
end