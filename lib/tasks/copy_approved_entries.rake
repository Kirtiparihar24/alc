namespace :copy_approved_entries do
  task :data_to_billing => :environment do

    # Copy Time Entries
    Physical::Timeandexpenses::TimeEntry.find(:all).each do |te|
      if te.status=='Approved'        
       tne_time = TneInvoiceTimeEntry.find_by_tne_time_entry_id(te.id)       
       if tne_time.nil?
        p "$$$$$$$$"
        tne1 = TneInvoiceTimeEntry.create(te.attributes)
        tne1.tne_time_entry_id = te.id
        tne1.save
       end
      end
    end

    #Copy Expense Entries
    Physical::Timeandexpenses::ExpenseEntry.find(:all).each do |ee|      
      if ee.status=='Approved'
        tne_exp = TneInvoiceExpenseEntry.find_by_tne_expense_entry_id(ee.id)
        if tne_exp.nil?
          tne2 = TneInvoiceExpenseEntry.create(ee.attributes)
          tne2.tne_expense_entry_id = ee.id
          tne2.save
          p "333333333"
        end
      end
    end

  end

end