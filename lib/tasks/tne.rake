namespace :time_entry do
  task :convert_existing_actual_duration_to_minutes => :environment do
    ActiveRecord::Base.transaction do
      Physical::Timeandexpenses::TimeEntry.all.each do |te|
        te.update_attribute(:actual_duration,te.actual_duration.to_f * 60)
      end

      TneInvoiceDetail.all.each do |tne_invoice_detail|
        tne_invoice_detail.update_attribute(:duration,tne_invoice_detail.duration.to_f * 60)
      end

      TneInvoiceTimeEntry.all.each do |tneite|
        tneite.update_attribute(:actual_duration,tneite.actual_duration.to_f * 60)
      end
    end
  end
end