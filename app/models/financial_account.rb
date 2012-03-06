class FinancialAccount < ActiveRecord::Base
  has_many :financial_transactions, :order => 'created_at DESC'
  belongs_to :company
  belongs_to :matter
  belongs_to :account
  belongs_to :financial_account_type, :class_name => "FinancialAccountType"
  validates_presence_of :name, :message => :blank
  validates_presence_of :bank_name, :message => :blank
  validates_presence_of :address, :message => :blank
  validates_presence_of :description, :message => :blank
  validates_numericality_of :account_no, :message => :should_be_numeric, :allow_nil => true
  attr_accessor :transaction_no

  def validate
    if (self.matter_id && (self.matter == nil || self.matter.company_id != self.company_id))
      self.errors.add(:matter_id, :financial_account_matter)
      self.matter_id = nil
    end
    if (self.financial_account_type == nil || self.financial_account_type.company_id != self.company_id)
      self.errors.add(:financial_account_type_id, :financial_account_financial_account_type)
    elsif (self.financial_account_type.lvalue == 'linked to matter' || self.financial_account_type.lvalue == 'linked to account')
      self.errors.add(:account_id, :financial_account_blank_or_not_exist) if (self.account_id == nil || self.account.company_id != self.company_id)
      self.errors.add(:matter_id, :financial_account_blank_or_not_exist) if (self.financial_account_type.lvalue == 'linked to matter' && self.matter_id == nil)
    end
    if (self.account_id && (self.account == nil || self.account.company_id != self.company_id))
      self.errors.add(:account_id, :financial_account_account)
    end
    financial_account_id = self.id ? self.id : 0
    if (self.account_no && self.bank_name && FinancialAccount.count(:conditions => ["bank_name = ? AND account_no = ? AND id != ?", self.bank_name, self.account_no, financial_account_id]) > 0)
      self.errors.add(:account_no, :financial_account_account_already_exist)
    end
  end
end
