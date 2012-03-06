
namespace :update do
  task :tne_invoice_detail => :environment do
    
    invoice = TneInvoice.all
    invoice.each do |bill|
      bill.tne_invoice_details.each do |detail|
        if detail.entry_type == 'Time'
          act_type = CompanyLookup.find(:first,:conditions => ['company_id = ? and alvalue=? and type like ?',bill.company_id,detail.activity,"CompanyActivityType"]).id rescue 0
          time_entries = detail.tne_invoice_time_entries.select{|te| te.activity_type == act_type}
          amount = 0
          duration = 0
          time_entries.each do |te|
            amount+=te.final_billed_amount
            duration+=te.actual_duration
          end
          duration = duration > 0 ? duration : detail.duration
          amount = amount > 0 ? amount : detail.amount
          rate = amount.to_f / duration.to_f
          detail.update_attributes(:duration=>duration, :amount=>amount,:rate => rate)
        end
      end

    end
  end
end
