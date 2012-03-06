namespace :invoice_details do

  task :update_entries_of_invoice => :environment do

    tne_invoice=TneInvoice.all
    tne_invoice.each do |tne|
      tne.tne_invoice_details.each do |id|
        if tne.consolidated_by == 'Activity'

          if id.entry_type == 'Time'
            act_type = CompanyLookup.find(:first,:conditions => ['company_id = ? and alvalue=? and type like ?',tne.company_id,id.activity,"Physical::Timeandexpenses::ActivityType"]).id rescue 0
            time_entries=TneInvoiceTimeEntry.find(:all,:conditions=>["tne_invoice_id=? and activity_type=?",tne.id,act_type])
            for te in time_entries
              unless te.nil?
                te.tne_invoice_detail_id = id.id
                te.primary_tax=id.primary_tax
                te.secondary_tax=id.secondary_tax
                te.save
              end
            end
          else
            act_type = CompanyLookup.find(:first,:conditions => ['company_id = ? and alvalue=? and type like ?',tne.company_id,id.activity,"Physical::Timeandexpenses::ExpenseType"]).id rescue 0
            expense_entries=TneInvoiceExpenseEntry.find(:all,:conditions=>["tne_invoice_id=? and expense_type=?",tne.id,act_type])
            for ee in expense_entries
              unless ee.nil?
                ee.tne_invoice_detail_id  = id.id
                ee.primary_tax=id.primary_tax
                ee.secondary_tax=id.secondary_tax
                ee.save
              end
            end
          end
        else
          lawyer_name=id.lawyer_name.split(' ')
          lawyer_id = User.find(:first,:conditions=>['company_id = ? and first_name = ? and last_name = ? ',tne.company_id,lawyer_name[0],lawyer_name[1]]).id rescue 0
          if id.entry_type == 'Time'
            time_entries=TneInvoiceTimeEntry.find(:all,:conditions=>["tne_invoice_id=? and employee_user_id=?",tne.id,lawyer_id])
            #time_entries = self.tne_invoice_time_entries.select{|te| te.employee_user_id == lawyer_id}
            for te in time_entries
              unless te.nil?
                te.tne_invoice_detail_id = id.id
                te.primary_tax=id.primary_tax
                te.secondary_tax=id.secondary_tax
                te.save
              end
            end
          else
            expense_entries=TneInvoiceExpenseEntry.find(:all,:conditions=>["tne_invoice_id=? and employee_user_id=?",tne.id,lawyer_id])
            #expense_entries = self.tne_invoice_expense_entries.select{|ee| ee.employee_user_id == lawyer_id}
            for ee in expense_entries
              unless ee.nil?
                ee.tne_invoice_detail_id  = id.id
                ee.primary_tax=id.primary_tax
                ee.secondary_tax=id.secondary_tax
                ee.save
              end
            end
          end
        end

      end
    end
  end
end
