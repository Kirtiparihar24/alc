# To change this template, choose Tools | Templates
# and open the template in the editor.

module ExpenseEntryGeneralized
  #after update callback to create or permanently delete entry in billing invoice entries.// Surekha
  def save_approved_entry_to_invoice
    if self.status_changed?
      t=TneInvoiceExpenseEntry.find_by_tne_expense_entry_id(self.id)
      if self.status=='Approved'
        if self.is_billable && t.nil? && (self.time_entry.nil? || (!self.time_entry.nil? && self.time_entry.is_billable))
          tne = TneInvoiceExpenseEntry.create(self.attributes)
          tne.tne_expense_entry_id = self.id
          tne.save
        end
      else
        if self.status=='Open' && !t.nil?
          t.destroy!
        end
      end
    end
  end

  def check_billing_type
    if(self.billing_method_type == 2 && self.billing_percent.blank?)
      self.billing_method_type=1
    elsif(self.billing_method_type == 3 && self.final_expense_amount.blank?)
      self.billing_method_type=1
    end
  end

  def billing_percent_check
    self[:billing_percent].present?
  end

  def markup_check
    self.markup.present?
  end

  # Returns final expense amount from discount and override amount.
  def calculate_final_expense_amount
    #if self.billable_type == 2 || self.accounted_for_type == 8
    if !self.is_billable || self.is_internal
      self.final_expense_amount = 0.0
    elsif self.billing_method_type == 3
      self.final_expense_amount = self.final_expense_amount
    elsif self.billing_method_type == 4
      if self.markup && self.markup > 0
        self.final_expense_amount = self.expense_amount + ((self.markup * self.expense_amount)/100)
      else
        self.billing_method_type = 1
        self.final_expense_amount = self.expense_amount
      end
    else
      if self.billing_percent && self.billing_percent > 0
        self.final_expense_amount = self.expense_amount - ((self.billing_percent * self.expense_amount)/100)
      else
        self.billing_method_type = 1
        self.final_expense_amount = self.expense_amount
      end
    end
    #self.final_expense_amount
  end

  # Returns expense amount after changing discount value.
  def calculate_new_expense_discount(expense_amount, billing_percent)
    billing_percent ||=0
    expense_amount ||=0

    expense_amount - ((billing_percent/100) * expense_amount)
  end

  def check_matter_inception_date
   matter_inception_date=Matter.find_by_id(self.matter_id).matter_date
    if self.expense_entry_date < matter_inception_date
      self.errors.add(:base,"Expense entry date cannot be less than matter inception date")
    end
  end
    
end
