namespace :add_status_for_tne_invoices do
  task :status_to_company_lookups =>:environment do
    statuses = ["Open", "Finalized", "Sent to Client", "Cancelled", "Partly Settled", "Settled"]
    companies = Company.all
    companies.each do |company|
      statuses.each do |status|
        existing_status = TneInvoiceStatus.find_all_by_lvalue_and_company_id(status, company.id)
        if existing_status.nil?
          TneInvoiceStatus.create(:company_id => company.id, :type => "TneInvoiceStatus", :lvalue => status, :alvalue => status)
        end
      end
    end
  end
end