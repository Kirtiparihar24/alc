class CompanyLookup < ActiveRecord::Base
  alias_attribute :designation, :lvalue
  acts_as_paranoid
  named_scope :company_and_type, lambda{|company,type| {:conditions=>["company_id = ? AND type = ? ", company, type]}}
  #default_scope :order => "sequence ASC"
  # Feature 6323 default scope added on sequence- Supriya Surve : 06/05/2011
  #It return list of designations of selected company.
  named_scope :getdesignations,lambda{|company_id|{:conditions=>["company_id=? AND type=?",company_id,'Designation']}}
  named_scope :get_salutations, lambda{|lawfirm_user|{:select=>['id,alvalue'],:conditions=>["company_id = ? AND type like 'SalutationType'",lawfirm_user.company.id]}}

  def self.types_liti(comp_id)
    records= CompanyLookup.all(:conditions => {:type => 'TypesLiti', :company_id => comp_id})
    if records.present?
      records
    else
      CompanyLookup.all(:conditions => {:type => 'TypesLiti', :company_id => Company.find_by_name("Livia").id})
    end
  end

  def self.types_non_liti(comp_id)
    records= CompanyLookup.all(:conditions => {:type => 'TypesNonLiti', :company_id => comp_id})
    if records.present?
      records
    else
      CompanyLookup.all(:conditions => {:type => 'TypesNonLiti', :company_id => Company.find_by_name("Livia").id})
    end
  end

  def validate_stage_name(company, lvalue)
    lvalue = lvalue.nil? ? '' : lvalue.strip
    previous_obj = self.class.find_by_lvalue_and_company_id(lvalue,company.id)
    unless (previous_obj.nil?)
      self.errors.add(:lvalue, " Duplicate entry")
    end
  end

  def validate
    is_duplicate = false
    alvalue = self.alvalue.nil? ? '' : self.alvalue.strip
    previous_obj = self.class.find_by_alvalue_and_company_id(alvalue,self.company_id)
    if(!self.new_record? && previous_obj != nil && previous_obj.id != self.id)
      is_duplicate = true
    elsif(self.new_record? && previous_obj != nil)
      is_duplicate = true
    end
    self.errors.add(:alvalue," Duplicate entry ") if is_duplicate
  end

  def self.get_employee_designation(designation_id)
    employee_designation= CompanyLookup.find_by_id(designation_id)
    employee_designation.lvalue
  end

end

class DocumentSubCategory < CompanyLookup
  validates_presence_of :lvalue ,:message=>"Sub Category can't be blank"
  belongs_to :company
  belongs_to :category, :class_name=>'DocumentCategory'
  has_many   :documents
end

class ContactPhoneType < CompanyLookup
  belongs_to :company, :dependent => :destroy
  validates_presence_of :lvalue ,:message=>"Phone type can't be blank"
end

class ContactPhoneType < CompanyLookup
  belongs_to :company, :dependent => :destroy
  validates_presence_of :lvalue ,:message=>"Phone type can't be blank"
end
class ApprovalStatus < CompanyLookup
 validates_presence_of :alvalue ,:message=>"Approval Status can't be blank"
end
class TransactionStatus < CompanyLookup
  validates_presence_of :alvalue ,:message=>"Transaction status can't be blank"
end
class IncomeType < CompanyLookup
 validates_presence_of :alvalue ,:message=>"Income type can't be blank"
end
class Purpose < CompanyLookup
 validates_presence_of :alvalue ,:message=>"Purpose can't be blank"
end
class ExpenseType < CompanyLookup
 validates_presence_of :alvalue ,:message=>"Expense type can't be blank"
end
class FinancialAccountType < CompanyLookup
  has_many :financial_accounts
end


# == Schema Information
#
# Table name: company_lookups
#
#  id                   :integer         not null, primary key
#  type                 :string(255)
#  lvalue               :string(255)
#  company_id           :integer         default(1)
#  created_at           :datetime
#  updated_at           :datetime
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  alvalue              :string(255)
#  category_id          :integer
#  sequence             :integer         default(0)
#

