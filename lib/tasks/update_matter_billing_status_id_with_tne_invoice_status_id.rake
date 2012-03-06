# matter_billings : update matter_billing_status_id
# with tne_invoice_status_id after comparing the bill_status with that companies tne_invoice_status lvalue
# Supriya Surve - 16 June 2011
namespace :update_matter_billing_status_id do
  task :with_tne_invoice_status_id => :environment do
    matter_billings = MatterBilling.find(:all)
    matter_billings.each do |billing|      
      if billing.matter_billing_status_id.blank? and !billing.bill_status.blank? and !billing.company_id.blank?
        status = TneInvoiceStatus.find_by_lvalue_and_company_id(billing.bill_status, billing.company_id)
        unless billing.tne_invoice_id.blank?
          if billing.tne_invoice
            MatterBilling.update_all({:matter_billing_status_id => billing.tne_invoice.tne_invoice_status_id}, {:id => billing.id})
          else
            invoice = TneInvoice.find_with_deleted(billing.tne_invoice_id) rescue nil
            cancelstatus = TneInvoiceStatus.find_by_lvalue_and_company_id("Cancelled", billing.company_id)
            MatterBilling.update_all({:matter_billing_status_id => cancelstatus.id}, {:id => billing.id})
            TneInvoice.update_all({:tne_invoice_status_id => cancelstatus.id}, {:id => invoice.id}) if invoice.present?
          end
        else
          billing.update_attribute(:matter_billing_status_id, status.id)
        end
      end
    end
  end
end

namespace :update_company_id do
  task :for_matter_billing => :environment do
    matter_billings = MatterBilling.find(:all)
    matter_billings.each do |billing|
      if billing.company_id.blank?
        MatterBilling.update_all({:company_id => billing.matter.company_id}, {:id => billing.id})
      end
    end
  end
end

namespace :update_blank_bill do
  task :for_matter_billing => :environment do
    matter_billings = MatterBilling.find(:all)
    matter_billings.each do |billing|
      if billing.bill_id.blank?
        matter_bill=MatterBilling.find( billing.id)
        matter_bill.bill_id=matter_bill.id
        matter_bill.bill_amount_paid=0
        matter_bill.bill_pay_date=Time.now.strftime('%Y-%m-%d')
        matter_bill.save
      end
    end
  end
end