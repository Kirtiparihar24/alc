namespace :remove_old_lookups do
  task :task_types_and_appointments => :environment do
    TaskType.connection.execute("Delete from company_lookups where Type='TaskType' or Type='AppointmentType'")
    MatterTask.update_all(:category_type_id=>nil)
  end
end
namespace :add_new_type do
  task :activity_type => :environment do
    activity_types = ["Business Development", "Client Communications", "Document Review", "Document Draft / Edit", "Research", "Analysis", "Preparation", "Negotiations", "Follow Up","Administrative","CLE","Travel","Other"]
    companies = Company.all
    companies.each do |company|
      activity_types.each do |tt|
        Physical::Timeandexpenses::ActivityType.create(:company_id => company.id, :type => "ActivityType", :lvalue => tt, :alvalue => tt)
      end
    end
  end
end

namespace :add_lookups do
  task :task_type => :environment do
    task_types = ["Business Development", "Client Communications", "Document Review", "Document Draft / Edit", "Research", "Analysis", "Preparation", "Negotiations", "Follow Up","Administrative","CLE","Travel","Other"]
    companies = Company.all
    companies.each do |company|
      task_types.each do |tt|
        TaskType.create(:company_id => company.id, :type => "TaskType", :lvalue => tt, :alvalue => tt)
      end
    end
  end

  task :appointment_type => :environment do
    appointment_types =  ["Business Development", "Client Communications", "Document Review", "Document Draft / Edit", "Research", "Analysis", "Preparation", "Negotiations", "Follow Up","Administrative","CLE","Travel","Other"]
    companies = Company.all
    companies.each do |company|
      appointment_types.each do |tt|
        AppointmentType.create(:company_id => company.id, :type => "AppointmentType", :lvalue => tt, :alvalue => tt)
      end
    end
  end

  task :update_tne_invoice_id => :environment do
    tne_invoices=TneInvoice.find(:all)
    tne_invoices.each do |tne_invoice|
      tne_invoice.tne_invoice_details.each do |id|
        if tne_invoice.consolidated_by == 'Activity'

          if id.entry_type == 'Time'
            act_type = CompanyLookup.find(:first,:conditions => ['company_id = ? and lvalue=? and type like ?',tne_invoice.company_id,id.activity,"Physical::Timeandexpenses::ActivityType"]).id rescue 0
            time_entries = tne_invoice.tne_invoice_time_entries.select{|te| te.activity_type == act_type}
            for te in time_entries
              unless te.nil?
                te.tne_invoice_detail_id = id.id
                te.save
                p 'Saved Time entry'
              end
            end
          else
            act_type = CompanyLookup.find(:first,:conditions => ['company_id = ? and lvalue=? and type like ?',tne_invoice.company_id,id.activity,"Physical::Timeandexpenses::ExpenseType"]).id rescue 0
            expense_entries = tne_invoice.tne_invoice_expense_entries.select{|ee| ee.expense_type == act_type}
            for ee in expense_entries
              unless ee.nil?
                ee.tne_invoice_detail_id  = id.id
                ee.save
              end
            end
          end
          #end
        else
          lawyer_name=id.lawyer_name.split(' ')
          lawyer_id = User.find(:first,:conditions=>['company_id = ? and first_name = ? and last_name = ? ',tne_invoice.company_id,lawyer_name[0],lawyer_name[1]]).id rescue 0
          if id.entry_type == 'Time'
            time_entries = tne_invoice.tne_invoice_time_entries.select{|te| te.employee_user_id == lawyer_id}
            for te in time_entries
              unless te.nil?
                te.tne_invoice_detail_id = id.id
                te.save
              end
            end
          else
            expense_entries = tne_invoice.tne_invoice_expense_entries.select{|ee| ee.employee_user_id == lawyer_id}
            for ee in expense_entries
              unless ee.nil?
                ee.tne_invoice_detail_id  = id.id
                ee.save
              end
            end
          end
        end
      end
    end
  end
end