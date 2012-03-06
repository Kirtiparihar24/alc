namespace :modify_tne_invoice_for_status do
  task :modify_status_to_tne_invoice =>:environment do
    companies = Company.all
    companies.each do |company|
      statuses = TneInvoiceStatus.find_all_by_company_id(company.id)
      statuses.each_with_index do |status, indx|
        if indx > 5
          invoices = status.tne_invoices
          if invoices
            invoices.each do |invoice|
              prevstatus = TneInvoiceStatus.find(:first, :conditions => "lvalue = '#{status.lvalue}' and company_id = #{company.id}")
              if prevstatus
                unless (prevstatus.id == status.id)
                  TneInvoice.update_all({:tne_invoice_status_id => prevstatus.id}, {:id=> invoice.id})
                  #status.delete
                end
              end              
            end
          end
          status.delete
        end
      end
    end
  end
end