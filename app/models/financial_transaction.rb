class FinancialTransaction < ActiveRecord::Base
  require 'base64'
  belongs_to :company
  belongs_to :financial_account
  belongs_to :account
  belongs_to :matter
  belongs_to :approval_status
  belongs_to :expense_type
  belongs_to :income_type
  belongs_to :transaction_status
  belongs_to :purpose
  has_many :matter_retainers  
  validates_presence_of :transaction_date, :message => :blank
  validates_presence_of :account, :message => :blank
  validates_numericality_of :amount, :message => :numeric_greater_than_zero, :greater_than_or_equal_to => 0.01
  validates_presence_of :details, :message => :blank
  before_save :save_balance
  after_save :update_balances
  #after_save  :update_financial_account_amount
  before_validation :change_names

  #named_scope total_in

  @@the_controller_action_name = 'receipt'

  def self.the_controller_action_name(name)
    @@the_controller_action_name = name
  end

  @@humanized_attributes = {:amount => "Amount Received", :transaction_date => "Date Received", :details => "Description", :transaction_no => 'Check No'}
  def change_names
    unless @@the_controller_action_name == 'receipt'
      @@humanized_attributes = {:amount => "Amount Paid / Settled", :transaction_date => "Date Paid / settled", :payer => "Payee", :details => "Description", :transaction_no => 'Check No'}
    end
  end
  
  def self.human_attribute_name(attr)
    @@humanized_attributes[attr.to_sym] || super
  end
  
  def inter_relation_transaction
    FinancialTransaction.find_by_inter_transfer_relation_token(self.inter_transfer_relation_token, :conditions => ["id != ?", self.id], :select => "financial_account_id")
  end

  def self.inter_transfer_transaction(debiting_transaction_obj, params)
    self.transaction do
      encoded_token = Base64.b64encode("#{rand(12345)}#{Time.now}")
      credit_transaction_obj = self.new(params[:financial_transaction])
      debiting_transaction_obj.inter_transfer_relation_token = encoded_token
      debiting_transaction_obj.save!
      credit_transaction_obj.financial_account_id = params[:financial_account_credited_no]
      credit_transaction_obj.inter_transfer_relation_token = encoded_token
      credit_transaction_obj.inter_transfer = true
      credit_transaction_obj.save!
    end
  end

  def self.inter_transfer_transaction_update(financial_transaction,params)
    self.transaction do
      related_transaction = FinancialTransaction.all(:conditions => ["inter_transfer_relation_token = ? AND id != ?", financial_transaction.inter_transfer_relation_token, financial_transaction.id])[0]
      related_transaction.attributes = params[:financial_transaction]
      if(financial_transaction.financial_account_id == params[:financial_account_credited_no].to_i)
        financial_transaction.transaction_type = true
      else
        financial_transaction.transaction_type = false
      end
      if(related_transaction.financial_account_id == params[:financial_account_debited_no].to_i)
        related_transaction.transaction_type = false
      else
        related_transaction.transaction_type = true
      end
      financial_transaction.save!
      related_transaction.save!
    end
  end

  def validate
    if (!self.transaction_type && self.financial_account.amount < self.amount)
      self.errors.add_to_base(:financial_account_not_sufficient_amount)
    end
    if (self.matter_id && (self.matter == nil || self.matter.company_id != self.company_id))
      self.errors.add(:matter_id,:financial_account_matter)
    end
    if (self.approval_status_id  && self.approval_status.company_id != self.company_id)
      self.errors.add(:approval_status_id,:financial_account_approval_status)
    end
    if (self.account_id && (self.account == nil || self.account.company_id != self.company_id))
      self.errors.add(:account_id, :financial_account_account)
    end
    if self.approved_by && (self.matter.matter_peoples.find(self.approved_by,:conditions => ["people_type = ? OR people_type = ?", 'matter_client', 'client_contact'], :select => 'id') == nil)
      self.errors.add(:approved_by, :financial_account_approval_by)
    end
    if (self.invoice_no && self.matter_id && !self.errors.on(:matter_id))
    end
  end

  def self.filtered_result(financial_account, params)
    sql_conditional_arr = []
    array_str = sql_condition_str = ""
    if params[:financial_transaction]
      params[:financial_transaction].each_pair { |name, val|
        sql_conditional_arr << "#{name} = #{val}" if val.to_i != 0
      }
    end
    if (!params[:from_date].blank? && !params[:to_date].blank?)
      sql_condition_str = "transaction_date BETWEEN '#{params[:from_date]}' AND '#{params[:to_date]}'"
    elsif !params[:from_date].blank?
      sql_condition_str = "transaction_date >= '#{params[:from_date]}'"
    elsif !params[:to_date].blank?
      sql_condition_str = "transaction_date <= '#{params[:to_date]}'"
    end
    if sql_conditional_arr.size > 0
      array_str = sql_condition_str.length > 0 ?  " AND " + sql_conditional_arr.join(" AND ") :  sql_conditional_arr.join(" AND ")
    end
    sql_condition_str += array_str
    sql_condition_str += sql_condition_str.length > 0 ?  " AND company_id=#{financial_account.company_id} AND financial_account_id=#{financial_account.id}" : " company_id=#{financial_account.company_id} AND financial_account_id = #{financial_account.id}"
    FinancialTransaction.all(:conditions => sql_condition_str)
  end

  def self.client_trust_view(company_id)   
    client_transactions = FinancialTransaction.all(:joins => "INNER JOIN accounts ON accounts.id = account_id INNER JOIN financial_accounts ON financial_accounts.id =  financial_account_id LEFT OUTER JOIN matters ON matters.id = financial_transactions.matter_id INNER JOIN company_lookups ON company_lookups.id = financial_accounts.financial_account_type_id",
                                                      :conditions => ["financial_transactions.company_id = ?", company_id],
                                                      :select => "financial_transactions.*, matters.name AS matter_name, financial_accounts.name AS trust_name, accounts.name AS account_name, alvalue, bank_name, account_no",
                                                      :order => "financial_transactions.account_id, financial_account_id")

    transaction_calculation(client_transactions)
  end
  
  def self.transaction_calculation(client_transactions)
    client_transactions_hash = client_transactions.group_by(&:account_id)
    client_transactions_arr = []
    client_balance = 0.0
    client_view_hash = {}
    client_name = ""
    i = 0
    client_transactions_hash.each_pair do |key_account_id, val_transaction|
      client_name = val_transaction[0].account_name
      financial_account_id = val_transaction[0].financial_account_id
      val_order_hash = val_transaction.group_by(&:financial_account_id)
      credit, debit, balance, tr_account_name, bank_name, account_no, financial_account_type, matter = self.initial_client_local_variable
      val_order_hash.each_pair do |k_financial_account_id, v_transaction|
        v_transaction.each do |trust_transaction|
          credit += trust_transaction.amount if trust_transaction.transaction_type
          debit  += trust_transaction.amount unless trust_transaction.transaction_type
          tr_account_name = trust_transaction.trust_name
          bank_name = trust_transaction.bank_name
          account_no = trust_transaction.account_no
          financial_account_type = trust_transaction.alvalue
          matter = trust_transaction.matter_name.blank? ? '' :  trust_transaction.matter_name
          financial_account_id = k_financial_account_id
        end
        balance = (credit - debit)
        client_balance += balance
        transaction_amount = balance.abs
        balance = 0.00 if balance < 0
        client_transactions_arr << [tr_account_name, bank_name, account_no, financial_account_type, matter, transaction_amount, balance, key_account_id, financial_account_id]
        client_transactions_arr
        credit, debit, balance, tr_account_name, bank_name, account_no, financial_account_type, matter = self.initial_client_local_variable
      end
      i += 1
      client_balance = 0.00 if client_balance < 0
      client_view_hash.merge!("#{client_name}_0000_livia_#{client_balance}_0000_livia_#{}" => client_transactions_arr)
      client_balance = 0.00
      client_transactions_arr = []
      client_account_id = key_account_id
    end
    return client_view_hash
  end

  def self.all_clients(company_id)
    Account.all(:conditions => ["id IN (select account_id from financial_transactions where company_id = ?)", company_id], :select => "accounts.id, name")
  end

  def self.matter_invoice_nums(matter_id, company_id)
    
    MatterBilling.all(:joins => "INNER JOIN company_lookups ON matter_billing_status_id = company_lookups.id",
                      :conditions => ["company_lookups.lvalue = ? AND matter_id = ? AND matter_billings.company_id = ?", 'Open', matter_id, company_id],
                      :select => "bill_no, bill_amount AS billed_amt, SUM(bill_amount_paid) AS paid_amt, (bill_amount - SUM(bill_amount_paid)) AS balance_amt",
                      :group => "bill_id, bill_no, bill_amount, matter_billings.created_at")
  end

  def create_update_matter_billing(matter_billing_status_id, action_str = nil)
    unless action_str
      matter_billing = MatterBilling.last(:conditions => ["matter_id = ? AND bill_no = ? AND company_id = ?", self.matter_id, self.invoice_no, self.company_id])
      matter_billing = MatterBilling.new({:matter_id => self.matter_id, :bill_pay_date => self.transaction_date, :bill_id => matter_billing.bill_id,
          :bill_amount => matter_billing.bill_amount, :financial_transaction_id => self.id, :bill_no => self.invoice_no, :remarks => 'Paided by trust account', :matter_billing_status_id => matter_billing_status_id, :bill_amount_paid => self.amount, :company_id => self.company_id })
    else
      matter_billing = MatterBilling.last(:conditions => ["financial_transaction_id = ?", self.id])
      if action_str == 'edit'
        matter_billing.update_attributes({:matter_id => self.matter_id, :bill_pay_date => self.transaction_date,
          :financial_transaction_id => self.id, :bill_no => self.invoice_no.to_s, :remarks => 'Paided by trust account', :matter_billing_status_id => matter_billing_status_id, :bill_amount_paid => self.amount, :company_id => self.company_id })
      elsif action_str == 'delete'
        matter_billing.update_attributes({:remarks => "Deleted from trust account transaction ", :deleted_at => Time.now.to_s})
        matter_billing.save false
        return 
      end
    end
    matter_billing.save!
  end

  def create_update_matter_retainer_receipt(new_record = true)
    matter_retainer = new_record ? self.matter_retainers.new : self.matter_retainers.find_by_financial_transaction_id(self.id)
    #Incase record is not updated of created in retainer for particluar FT
    if matter_retainer.nil?
      matter_retainer =  self.matter_retainers.new
    end
    matter_retainer.attributes = {:matter_id => self.matter_id, :amount => self.amount.to_f, :date => self.transaction_date, :company_id => self.company_id}
    matter_retainer.save(false)
  end
  private
 
  def save_balance
    prev_ft = FinancialTransaction.find(:first, :conditions=>["company_id =? and financial_account_id= ? and id < ?", self.company_id, self.financial_account_id, self.id], :order=>'id desc')
    prev_bal = prev_ft.present? ? prev_ft.balance : 0
    calculate_inflow_outflow(self,prev_bal)
  end

  def calculate_inflow_outflow(obj, bal)
    if obj.transaction_type
      obj.balance = bal + obj.amount
    end
    if obj.matter_id
      obj.balance = obj.balance - obj.amount
    end
  end

  def update_balances    
    fts = FinancialTransaction.find(:all, :conditions=>["company_id =? and financial_account_id= ? and id > ?", self.company_id, self.financial_account_id, self.id], :order=>'id asc')
    if fts.empty? #If new record transaction is created
      prev_ft = FinancialTransaction.find(:first, :conditions=>["company_id =? and financial_account_id= ? and id < ?", self.company_id, self.financial_account_id, self.id], :order=>'id desc')
      prev_bal = prev_ft.present? ? prev_ft.balance : 0
      calculate_inflow_outflow(self,prev_bal)
      ActiveRecord::Base.connection.execute("update financial_transactions set balance = #{self.balance} where id = #{self.id}")
    else
      current_bal = self.balance
      fts.each do |ft|
        calculate_inflow_outflow(ft,current_bal)
        ActiveRecord::Base.connection.execute("update financial_transactions set balance = #{ft.balance} where id = #{ft.id}")
        current_bal = ft.balance
      end
      self.financial_account.update_attribute(:amount,current_bal)
    end
    
  end

#  def update_balance
#    previous_tr = FinancialTransaction.find(self.id)
#    previous_amount = previous_tr.amount
#    diff_amount = (previous_amount >  self.amount) ? (previous_amount - self.amount) : (self.amount - previous_amount)
#    if (self.inter_transfer && diff_amount == 0 && previous_tr.transaction_type != self.transaction_type)
#      diff_amount = self.amount
#    end
#    if self.transaction_type
#      self.balance +=  diff_amount
#    else
#      self.balance -= diff_amount
#    end

#  end

  def update_financial_account_amount
    self.transaction do
      self.financial_account.update_attribute(:amount,self.balance)
    end
  end

  def self.initial_client_local_variable
    credit = debit = balance = 0.00
    tr_account_name = bank_name = account_no = financial_account_type = matter = ''
    [credit, debit, balance, tr_account_name, bank_name, account_no, financial_account_type, matter]
  end
end
