class MatterBilling < ActiveRecord::Base
  default_scope :order => 'matter_billings.created_at DESC'
  attr_reader :STATUS
  belongs_to :matter
  belongs_to :user, :foreign_key => :created_by_user_id
  belongs_to :tne_invoice
  belongs_to :bill,:class_name=>'MatterBilling'
  belongs_to :matter_billing_status, :class_name => "TneInvoiceStatus", :foreign_key => :matter_billing_status_id

  validates_presence_of :bill_no ,:message=>:bill_no_blank
  validates_uniqueness_of :bill_no,:message=> :bill_no_unique, :case_sensitive => false, :unless => "bill_id.present?" #skip uniq check for the bills which are for partial payment record
  validates_presence_of :bill_amount ,:message=>:bill_amount_blank
  validates_numericality_of :bill_amount, :message => :bill_amount_invalid,:allow_blank => :true
  validates_numericality_of :bill_amount_paid, :message =>:bill_payment_invalid
  validates_presence_of :bill_pay_date,:message=> :bill_pay_date_blank
  validates_length_of :remarks, :maximum => 255, :message => :too_long_remark
  validate :bill_date_cant_be_less_than_matter_inception
  #validate :amount_length
  cattr_reader :per_page
  @@per_page=25

  # Used for sphinx search
  define_index do
    #set_property :delta => true
    indexes bill_no, :prefixes => true
    indexes matter.name, :as => :invoice_matter_name, :prefixes => true
    indexes matter.contact.first_name, :prefixes => true
    indexes matter.matter_no, :as => :invoice_matter_no, :prefixes => true
    #indexes matter_billing_status.lvalue, :as => :tne_invoice_status, :prefixes => true
    has :company_id, :matter_billing_status_id
    
    #has :deleted_at
  end
  after_update :update_tne_invoice
  after_create :update_bill_payment_details
  
  STATUS = [ "Open", "Settled" ]
  
  #To Update payment details in invoice
  def update_bill_payment_details
    if self.bill && self.bill.tne_invoice.present?
      tne_invoice=self.bill.tne_invoice
      tne_invoice.final_invoice_amt=tne_invoice.final_invoice_amt - self.bill_amount_paid
      tne_invoice.send(:update_without_callbacks)
    end
  end

  def computed_bill_amount_due
    if self.matter_billing_status.try(:lvalue) != 'Settled'
      nil2zero(self.bill_amount) - computed_bill_amount_paid
    else
      0
    end
  end

  def bill_date_cant_be_less_than_matter_inception
    bill = MatterBilling.find_by_bill_id(self.bill_id) if self.bill_id
    if bill.present?
      self.errors.add_to_base('Settlement Date Cannot Be Less Than Matter Inception Date') if self.bill_pay_date && self.matter[:matter_date] &&  self.bill_pay_date < self.matter[:matter_date].to_date
    else
      self.errors.add_to_base('Invoice Date Cannot Be Less Than Matter Inception Date') if self.bill_pay_date && self.matter[:matter_date] &&  self.bill_pay_date < self.matter[:matter_date].to_date
    end
  end
  def computed_bill_amount_paid
    tot = 0
    MatterBilling.all(:conditions =>
        [ "bill_id = ?", self.id ]).each do|e|
      tot += nil2zero(e.bill_amount_paid)
    end

    tot
  end

  def bill_amount_due
    # No amount is due, if the bill is settled.
    if self.matter_billing_status.lvalue.eql?("Settled")
      0
      # Otherwise compute the remaining amount.
    elsif self.bill_amount && self.bill_amount_paid
      nil2zero(self.bill_amount) - nil2zero(self.bill_amount_paid)
      # If there is not bill amount, but some amount is paid, then there
      # is zero due amount.
    elsif self.bill_amount_paid
      0
      # Nothing has been paid yet, bill amount is due amount also.
    elsif self.bill_amount
      self.bill_amount
    end
  end

  def get_document
    bills = Comment.find_with_deleted(:all, :order => "created_at DESC", :conditions => ["commentable_id = ? AND commentable_type = ?", self.id, 'MatterBilling'])
    DocumentHome.first(:order => "created_at DESC", :conditions => ["mapable_type = ? AND mapable_id in (?)", 'Comment', bills.collect(&:id)])
  end

  #This method retrieves records from DB based on user selection of parameters in Reports
  #include or select options for below find method is passed as hash 'include_hash' - Ketki 9/5/2011
  def self.find_for_rpt(company_id, matter_types, record_type, matters, include_hash = {})
    matter_ids = []
    matter_ids = matters.collect{|matter| matter.id}
    search_hash = "company_id = :company_id "
    search_hash << " AND id = bill_id"
    search_hash << " AND matter_id in (:matter_ids)"  if matter_ids
    condition_hash = {:company_id => company_id, :matter_ids => matter_ids}
    include_hash.merge!(:conditions =>[search_hash, condition_hash])
    matter_billing =  MatterBilling.all(include_hash ).group_by(&:matter_id)
    basic_data, total_data, conditions = {}, {}, {}
    total_length = 0
    grand_amount, grand_received, grand_discount, grand_outstanding =0.00,0.00,0.00,0.00
    unless matters.blank?
      matters = matters.group_by(&:matter_type_id)      
      matters.each do |label, matrs|
        label = label.nil? ? "Other" : label
        types = matter_types.collect{|type| [type.id, type.alvalue]}
        types.each{|type| label = type[1] if type[0] == label}
        data = []
        total_amount, total_received, total_discount, total_outstanding, total_billed= 0.00, 0.00, 0.00, 0.00, 0
        matrs.each do |matter|
          billing  = matter_billing[matter.id]
          tamt_outstanding, tamt_discount, billed_total, amount_received = 0,0,0,0
          unless billing.blank?
            billing.each do |bill|
              received_amt, discount_amt, outstanding_amt = bill.get_other_bill_details
              total_amt = bill.bill_amount
              billed_total =billed_total + total_amt
              amount_received =amount_received + received_amt
              tamt_discount = tamt_discount + discount_amt
              tamt_outstanding = tamt_outstanding +  outstanding_amt
            end
            total_billed =total_billed + billing.size
          end
          unless record_type.eql?("Basic")
            data << [matter.matter_no,matter.name,matter.matter_date, billing.try(:size), billed_total.to_f.fixed_precision(2), amount_received.to_f.fixed_precision(2), tamt_discount.to_f.fixed_precision(2), tamt_outstanding.to_f.fixed_precision(2) ]
          end
          total_amount +=billed_total
          total_received +=amount_received
          total_discount +=tamt_discount
          total_outstanding +=tamt_outstanding
        end
        if record_type.eql?("Basic")
          basic_data[label] = [[label, matrs.size, total_billed, total_amount.to_f.fixed_precision(2), total_received.to_f.fixed_precision(2), total_discount.to_f.fixed_precision(2), total_outstanding.to_f.fixed_precision(2)]]
          conditions[label] = [total_billed, total_amount.to_f.fixed_precision(2), total_received.to_f.fixed_precision(2), total_discount.to_f.fixed_precision(2), total_outstanding.to_f.fixed_precision(2)]
        else
          total_length += data.try(:length)
          total_data[label] = data
          conditions[label] = [label, total_amount.to_f.fixed_precision(2), total_received.to_f.fixed_precision(2), total_discount.to_f.fixed_precision(2), total_outstanding.to_f.fixed_precision(2), total_billed]
        end
        grand_amount += total_amount
        grand_received += total_received
        grand_discount += total_discount
        grand_outstanding += total_outstanding        
      end      
      conditions[:grand_total] = [grand_amount.to_f.fixed_precision(2), grand_received.to_f.fixed_precision(2), grand_discount.to_f.fixed_precision(2), grand_outstanding.to_f.fixed_precision(2)]
      conditions[:revenue_by_matter_type] = true
      data = []
      basic_data.collect{|k,v| data << v.flatten}
      total_data["By Type"] = data unless record_type.eql?("Detail")      
      total_data = total_data.each{|k, v| v = v.flatten}
    end
    unless record_type.eql?("Basic")
      conditions[:total_length] = total_length
    else
      conditions[:total_length] = total_data["By Type"].blank? ? 0 : total_data["By Type"].length
    end
    alignment = {0=> :left,1=> :left,2=> :center,3=> :center,4=> :right,5=> :right,6=>:right, 7=> :right}
    [total_data, conditions, alignment]
  end

  # For each bill created this method return all the associated billing details used for generating report -Ketki 10/5/2011
  def get_other_bill_details
    bill_details = MatterBilling.find_all_by_bill_id(self.id)
    amount_paid = 0
    status = self.matter_billing_status.lvalue
    bill_details.collect{|b| amount_paid += b.bill_amount_paid unless b.bill_amount_paid.blank?}
    bill_paid, received_amt, amt_discount, amt_outstanding = 0,0,0,0
    bill_details.each do |bill|
      received_amt +=  bill.try(:bill_amount_paid)
      if !bill.bill_amount_paid.nil? and !bill.bill_amount.nil?
        bill_paid = bill_paid + bill.bill_amount_paid
      end
    end
    status.eql?("Settled") ? (amt_discount = self.bill_amount - bill_paid) : (amt_outstanding = self.bill_amount - bill_paid)
    [received_amt, amt_discount, amt_outstanding]
  end

  def update_tne_invoice
    if self.matter_billing_status_id_changed?
      if self.tne_invoice.present?
        company = self.tne_invoice.company
        self.tne_invoice.tne_invoice_status_id = self.matter_billing_status.id
        self.tne_invoice.send(:update_without_callbacks)
      end
    end    
  end

  def self.get_bills(company, status, params, search)
    if (params[:mode_type]=="client" || params[:type]=="client")
      TneInvoice.get_invoices(company, status, params, search)
    else
      conditions = "matter_billings.id = bill_id and matter_billings.company_id = #{company.id} "      
      conditions << "and DATE(matter_billings.bill_pay_date) between \'#{params[:date_start]}\' and \'#{params[:date_end]}\'"unless params[:date_start].blank? && params[:date_end].blank?
      unless status.blank?
        conditions << " and matter_billings.matter_billing_status_id = #{status.id}"
      else
        cancelled = company.tne_invoice_statuses.find_by_lvalue("Cancelled")
        conditions << " and matter_billings.matter_billing_status_id != #{cancelled.id}"
      end
      
      dir = params[:dir]=="down" ? "DESC" : "ASC"
      secondary_sort = params[:secondary_sort_direction].eql?("up")? "asc" : "desc"
      if params[:col].eql?("bill_pay_date")
        dir = params[:dir].eql?("up")? "desc" : "asc"
      end
      order = nil
      if params[:col] && params[:secondary_sort]
        if params[:col]=="matters.name"
          order = "#{params[:col]} #{dir} , #{params[:secondary_sort]} #{secondary_sort}"
        elsif params[:col]=="contacts.last_name"
          order = "contacts.last_name #{dir} , #{params[:secondary_sort]} #{secondary_sort}"
          #order="coalesce(contacts.last_name,'')||''||contacts.first_name||''||coalesce(contacts.middle_name,'') #{dir}"
        elsif params[:col]=="billing_status"
          order = "company_lookups.alvalue #{dir} , #{params[:secondary_sort]} #{secondary_sort}"
        elsif params[:col]=="type"
          order = "matter_billings.automate_entry #{dir} , #{params[:secondary_sort]} #{secondary_sort}"
        elsif params[:col]=="matters.matter_no"
          order = "#{params[:col]} #{dir} , #{params[:secondary_sort]} #{secondary_sort}"
        else
          order = "matter_billings.#{params[:col]} #{dir} , #{params[:secondary_sort]} #{secondary_sort}"
        end
      elsif params[:col] && !params[:secondary_sort]
        if params[:col]=="matters.name"
          order = "#{params[:col]} #{dir}"
        elsif params[:col]=="contacts.last_name"
          order = "contacts.last_name #{dir}"
          #order="coalesce(contacts.last_name,'')||''||contacts.first_name||''||coalesce(contacts.middle_name,'') #{dir}"
        elsif params[:col]=="billing_status"
          order = "company_lookups.alvalue #{dir}"
        elsif params[:col]=="type"
          order = "matter_billings.automate_entry #{dir}"
        elsif params[:col]=="matters.matter_no"
          order = "#{params[:col]} #{dir}"
        else
          order = "matter_billings.#{params[:col]} #{dir}"
        end
      end     
      self.paginate(:all, :conditions => conditions, :include => [{:matter => :contact}, :matter_billing_status, :tne_invoice], :page=>params[:page], :per_page=>params[:per_page], :order => order)
    end    
  end

  def bill_paid_date
    matter=MatterBilling.first(:conditions => ['bill_id = ?', self.id])
    matter.bill_pay_date.to_time
  end

  # It used search for cancelled billed
  def cancelled_system_bill
    TneInvoice.find_only_deleted(:first,:conditions => {:matter_id => self.matter_id})
  end

  def call_validation   
    bill=MatterBilling.find_by_bill_no_and_company_id(self.bill_no,self.company_id)
    if (self.id.nil? && self.bill_id) ||(bill && self.bill_id && bill.bill_id == self.bill_id)
      return false
    elsif bill.blank?
      return false
    else
      return true
    end
  end
  
  private

  def nil2zero(amt)
    amt.nil? ? 0 : amt
  end
  
  def amount_length
    if(!self.errors.on(:bill_amount)&& self.bill_amount.to_s.length > 12)
      self.errors.add(:bill_amount,"maximum length 12")
    end
    if(!self.bill_amount_paid.blank? && !self.errors.on(:bill_amount_paid) && self.bill_amount_paid.to_s.length > 12)
      self.errors.add(:bill_amount_paid,"maximum length 12")
    end
  end
end

# == Schema Information
#
# Table name: matter_billings
#
#  id                       :integer         not null, primary key
#  bill_no                  :string(255)
#  bill_issue_date          :date
#  bill_pay_date            :date
#  bill_amount              :float
#  bill_amount_paid         :integer
#  bill_status              :string(255)
#  matter_id                :integer
#  remarks                  :string(255)
#  bill_id                  :integer
#  created_by_user_id       :integer
#  updated_by_user_id       :integer
#  company_id               :integer
#  created_at               :datetime
#  updated_at               :datetime
#  tne_invoice_id           :integer
#  automate_entry           :boolean         default(FALSE)
#  matter_billing_status_id :integer
#
