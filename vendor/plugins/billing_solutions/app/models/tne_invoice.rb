require 'rubygems'
require 'spreadsheet'
require "activesupport"
require "tidy_ffi"
require "erb"
require "acts_as_flying_saucer"
require "tempfile"

class TneInvoice < ActiveRecord::Base
  unloadable
  include LiviaRound
  belongs_to :company
  has_many :tne_invoice_details, :order=>"entry_type DESC"
  has_many :time_entries , :class_name=>"Physical::Timeandexpenses::TimeEntry"
  has_many :expense_entries, :class_name=>"Physical::Timeandexpenses::ExpenseEntry"
  belongs_to :matter
  belongs_to :contact
  belongs_to :tne_invoice_status
  has_many :tne_invoice_time_entries
  has_many :tne_invoice_expense_entries
  has_one :matter_billing
  accepts_nested_attributes_for :tne_invoice_details, :allow_destroy => true
  attr_accessor :regenerate,:time_entries_ids,:expense_entries_ids,:owner_user_id
  acts_as_commentable
  acts_as_paranoid
  cattr_reader :per_page
  @@per_page=25
  validate :bill_no
  before_create :get_contact_address
  after_create :update_time_expense_entries
  before_update :update_time_expense_entries, :get_contact_address
  after_save :update_matter_billing,:update_time_expense_entries

  named_scope :with_status ,lambda{|status|{:conditions =>["tne_invoice_status_id = ?",status]}}
  named_scope :address_modified_status ,lambda{|status|{:conditions=>["address_modified is NULL OR address_modified = ?",status]}}

  # Used for sphinx search
  define_index do
    indexes invoice_no, :prefixes => true
    indexes matter.name, :as => :invoice_matter_name, :prefixes => true
    indexes matter.contact.first_name, :prefixes => true
    indexes matter.matter_no, :as => :invoice_matter_no, :prefixes => true
    has :company_id, :matter_id
  end

  def update_matter_billing
    if self.changed? && self.matter_id.present?
      self.add_or_update_matter_billing
    end
  end

  def add_or_update_matter_billing
    m_billing = MatterBilling.find_by_tne_invoice_id_and_matter_id(self.id,self.matter_id)
    hash_value = {:tne_invoice_id => id, :bill_no => invoice_no, :bill_pay_date => invoice_date,
      :bill_due_date => invoice_due_date, :bill_amount => final_invoice_amt,
      :matter_billing_status_id =>tne_invoice_status_id, :matter_id => matter_id,
      :remarks => invoice_notes.nil? ? '' : invoice_notes , :created_by_user_id => created_by_user_id,
      :updated_by_user_id => updated_by_user_id, :automate_entry => true,
      :company_id => company_id}
    hash_value.merge!({:bill_amount_paid => 0}) if m_billing.blank?
    if m_billing.blank?
      matter_billing = MatterBilling.create(hash_value)
      matter_billing.bill_id = matter_billing.id
      matter_billing.save(false)
    elsif m_billing.present?
      m_billing.update_attributes(hash_value)
    end
  end

  #IMPORTANT NOTE: METHODS MOVED TO Module TimeEntryGeneralized
  def get_contact_address
    primary_contact= self.contact_id? ? self.contact : self.matter.try(:contact)
    unless primary_contact.try(:accounts).blank?
      unless primary_contact.try(:accounts).first.get_address.blank?
        primary_contact = primary_contact.try(:accounts).first
      end
    end
    if self.client_address.blank?
      self.client_address=primary_contact.try(:get_address)
    end
  end

  def validate_view
    if self.view == 'postsales' || self.view.blank?
      self.errors.add_to_base("Please select a matter from matters list.") if self.matter_id.nil? || self.matter_id.blank?
    elsif self.view == 'presales'
      self.errors.add_to_base("Please select a contact from contacts list.")
    end
  end

  # get_invoice_detail(detailed)- Added by Pratik A J 28-06-2011 : Common code for invoice detail moved here.
  def get_invoice_detail(detailed)
    if self.contact_id
      primary_contact = self.contact
    elsif self.matter_id
      primary_contact = self.matter.contact
    end
    role_id = Role.find_by_name('lawyer').id if consolidated_by.eql?("User")
    p_tax,s_tax,n_total = self.calculate_tax
    invoice_details = self.tne_invoice_details.map do |id|
      activity = consolidated_by =='User' ? id.lawyer_name : (consolidated_by =='Activity' ?  id.activity : id.tne_entry_date.to_s)
      if detailed
        case consolidated_by
        when 'User'
          time_entries,expense_entries = consolidated_by_user(self, id.entry_type, id.lawyer_name)
          if id.entry_type == 'Time'
            for te in time_entries
              actual_duration = company.duration_setting.setting_value == "1/100th" ?  one_hundredth_timediffernce(te.actual_duration) : one_tenth_timediffernce(te.actual_duration)
              activity+= "\n\t\t #{te.time_entry_date} #{te.acty_type.alvalue} #{commas(actual_duration)} hrs @ $#{commas(te.actual_activity_rate)}/hr - #{te.description}"
            end
          else
            for ee in expense_entries
              activity+= "\n\t\t #{ee.expense_entry_date} #{ee.expense.alvalue}- $#{commas(ee.final_expense_amount)}- #{ee.description}"
            end
          end
        when 'Activity'
          time_entries, expense_entries = consolidated_by_activity(self, id.entry_type, id.activity)
          if id.entry_type == 'Time'
            for te in time_entries
			  actual_duration = company.duration_setting.setting_value == "1/100th" ?  one_hundredth_timediffernce(te.actual_duration) : one_tenth_timediffernce(te.actual_duration)
              activity+= "\n\t\t #{te.time_entry_date} #{te.performer.full_name} #{commas(te.actual_duration)} hours @ $#{commas(te.actual_activity_rate)}/hr - #{te.description}"
            end
          else
            for ee in expense_entries
              activity+= "\n\t\t #{ee.expense_entry_date} #{ee.performer.full_name}- $#{commas(ee.final_expense_amount)} - #{ee.description}"
            end
          end
        when 'Date'
          time_entries, expense_entries = consolidated_by_date(self, id.entry_type, id.tne_entry_date)
          if id.entry_type == 'Time'
            for te in time_entries
			  actual_duration = company.duration_setting.setting_value == "1/100th" ?  one_hundredth_timediffernce(te.actual_duration) : one_tenth_timediffernce(te.actual_duration)
              activity+= "\n\t\t #{te.acty_type.alvalue} #{te.performer.full_name} #{commas(te.actual_duration)} hours @ $#{commas(te.actual_activity_rate)}/hr - #{te.description}"
            end
          else
            for ee in expense_entries
              activity+= "\n\t\t #{ee.expense.alvalue} #{ee.performer.full_name}- $#{commas(ee.final_expense_amount)} - #{ee.description}"
            end
          end
        end
      end
    actual_duration = company.duration_setting.setting_value == "1/100th" ?  one_hundredth_timediffernce(id.duration) : one_tenth_timediffernce(id.duration)
      if id.entry_type
        [
          activity,
          commas(id.rate),
          actual_duration.blank? ? '' : actual_duration,
          commas(id.amount)
        ]
      end
    end
    return [primary_contact,p_tax,s_tax,n_total,invoice_details]
  end

  def generate_invoice_pdf(detailed)
    primary_contact,p_tax,s_tax,n_total,time_entry,expense_entry,summary_view =  get_invoice_detail_for_pdf(detailed)
    new_logo=''
    if company.logo_for_invoice
      logo=company.logo.url.split('?')[0]
      new_logo = "#{Rails.root}/public"+logo
    end
    invoice_setting = TneInvoiceSetting.find_by_company_id(company.id)
    invoice=self
    html = File.read("#{Rails.root}/vendor/plugins/billing_solutions/app/views/tne_invoices/invoice_pdf.pdf.erb")

    template = ERB.new(html)
    input_file_html = Tempfile.new("random.html")
    input_file_html << TidyFFI::Tidy.new(template.result(binding)).clean
    input_file_html.close
    pdf_name= "/tmp/#{self.id}.pdf"
    options = ActsAsFlyingSaucer::Config.options.merge({:input_file=>input_file_html.path,:output_file=>pdf_name})
    ActsAsFlyingSaucer::Xhtml2Pdf.write_pdf(options)
    return pdf_name
  end

  def generate_invoice_xls(detailed)
    invoice_setting = TneInvoiceSetting.find_by_company_id(company.id)
    format = LiviaExcelReport.format
    primary_contact,p_tax,s_tax,n_total,invoice_details = get_invoice_detail(detailed)
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet
    #formatting column with and row height
    column_format = Spreadsheet::Format.new :text_wrap => true ,:shrink => true
    5.times{|column| sheet.column(column).default_format = column_format}
    sheet.column(0).width= 50;
    sheet.column(1).width= 30;
    sheet.column(2).width= 30;
    sheet.column(3).width= 30;
    total = invoice_details.size
    (12..(total+11)).each {|rows| sheet.row(rows).height = 40}
    sheet.instance_variable_set("@index",-1)
    row = LiviaExcelReport.create_new_row(sheet)
    row = LiviaExcelReport.create_new_row(sheet)
    row.replace [self.company.name.camelize]
    row.default_format = format
    row = LiviaExcelReport.create_new_row(sheet)
    row.replace ["","","INVOICE"]
    row.default_format = format

    row = LiviaExcelReport.create_new_row(sheet)
    row.replace ["","Invoice :"," #{self.invoice_no}"]
    row.default_format = format
    row = LiviaExcelReport.create_new_row(sheet)
    row.replace ["","Invoice Date:"," #{self.invoice_date}"]
    row.default_format = format
    row = LiviaExcelReport.create_new_row(sheet)
    row.replace ["","Due Date:"," #{self.invoice_due_date}"]
    unless primary_contact && primary_contact.try(:get_account_name).nil?
      row.default_format = format
      row = LiviaExcelReport.create_new_row(sheet)
      row.replace ["Account : #{primary_contact.try(:get_account_name)}"]
    end
    row.default_format = format
    row = LiviaExcelReport.create_new_row(sheet)
    row.replace ["Primary Client : #{primary_contact.try(:first_name)} #{primary_contact.try(:last_name)}"]
    row.default_format = format
    row = LiviaExcelReport.create_new_row(sheet)
    row.replace ["Account/Client Address : "]
    row.default_format = format
    row = LiviaExcelReport.create_new_row(sheet)
    row.replace ["#{self.client_address}"]
    row.default_format = format
    row.height = 60 if self.client_address?
    row = LiviaExcelReport.create_new_row(sheet)
    row.replace ["Matter : #{self.matter_id ? self.matter.name : '-' }"]
    row.default_format = format
    row = LiviaExcelReport.create_new_row(sheet)

    unless invoice_details.nil?
      headers = ["Activity/Expense Type","Rate","Hours","Amount($)"]
      LiviaExcelReport.set_headers(LiviaExcelReport.create_new_row(sheet),headers)
      invoice_details.each do|array|
        #Creating Table Rows
        row = LiviaExcelReport.create_new_row(sheet)
        row.replace array
      end
    end
    row = LiviaExcelReport.create_new_row(sheet)
    row.replace ["","Sub Total:"," #{commas(self.invoice_amt)}"]
    row.default_format = format
    if self.discount && self.discount!=0
      row = LiviaExcelReport.create_new_row(sheet)
      row.replace ["","Discount:"," #{self.discount ? commas(self.discount) : 0.00}"]
      row.default_format = format
    end
    if invoice_setting.present? && invoice_setting.primary_tax_enable
      if self.primary_tax_rate && self.primary_tax_rate!=0
        row = LiviaExcelReport.create_new_row(sheet)
        row.replace ["","#{self.primary_tax_name.blank? ? 'Primary Tax' : self.primary_tax_name} (#{self.primary_tax_rate ? self.primary_tax_rate : 0}%):"," #{commas(p_tax)}"]
        row.default_format = format
      end
    end
    if invoice_setting.present? && invoice_setting.secondary_tax_enable
      if self.secondary_tax_rate && self.secondary_tax_rate!=0
        row = LiviaExcelReport.create_new_row(sheet)
        row.replace ["","#{self.secondary_tax_name.blank? ? 'Secondary Tax' : self.secondary_tax_name} (#{self.secondary_tax_rate ? self.secondary_tax_rate : 0}%):"," #{commas(s_tax)}"]
        row.default_format = format
      end
    end

    row = LiviaExcelReport.create_new_row(sheet)
    row.replace ["","Total:"," #{commas(n_total)}"]
    row.default_format = format
    if self.check_notes && self.invoice_notes.present?
      row = LiviaExcelReport.create_new_row(sheet)
      row.replace ["Note: #{self.invoice_notes}"]
      row.default_format = format
    end

    report =  StringIO.new
    (book.write report )
    report.string
  end

  def calculate_tax
    primary_tax_rate = primary_tax_rate.blank? ?  0 : primary_tax_rate
    secondary_tax_rate = secondary_tax_rate.blank? ?  0 : secondary_tax_rate
    discount = discount.blank? ?  0 : discount
    invoice_setting = TneInvoiceSetting.find_by_company_id(self.company_id)
    if invoice_setting.present? && invoice_setting.secondary_tax_enable
      calculations_for_tax = primary_tax_rate + secondary_tax_rate + discount
    else
      if invoice_setting.present? && invoice_setting.primary_tax_enable
        calculations_for_tax = primary_tax_rate + discount
      else
        calculations_for_tax = discount
      end
    end
    if calculations_for_tax== 0
      n_total = final_invoice_amt
    else
      n_total = invoice_amt
    end
    if invoice_setting.present? && invoice_setting.primary_tax_enable
      if self.primary_tax_rate
        details_tax = 0
        if self.view_by == "Summary"
          self.tne_invoice_details.each do |d|
            if d.primary_tax
              details_tax += livia_round(((d.amount * self.primary_tax_rate)/100))
            end
          end
        else
          time_entries = TneInvoiceTimeEntry.find(:all,:conditions=>["tne_invoice_id=? ",self.id])
          time_entries.each do |e|
            if e.primary_tax
              details_tax += livia_round(((e.final_billed_amount * self.primary_tax_rate)/100))
            end
          end
          expense_entries=TneInvoiceExpenseEntry.find(:all,:conditions=>["tne_invoice_id=? ",self.id])
          expense_entries.each do |e|
            if e.primary_tax
              details_tax += livia_round((e.final_expense_amount * self.primary_tax_rate)/100)
            end
          end
        end
        p_tax = details_tax
      else
        p_tax = 0
      end

      if invoice_setting.present? && invoice_setting.secondary_tax_enable && self.secondary_tax_rate
        details_s_tax = 0
        if self.view_by == "Summary"
          self.tne_invoice_details.each do |d|
            if d.secondary_tax
              if self.secondary_tax_rule
                if d.primary_tax
                  prim_tax = livia_round((d.amount * self.primary_tax_rate)/100)
                  details_s_tax += livia_round(((d.amount + prim_tax) * self.secondary_tax_rate)/100)
                else
                  details_s_tax += livia_round((d.amount * self.secondary_tax_rate)/100)
                end
              else
                details_s_tax += livia_round((d.amount * self.secondary_tax_rate)/100)
              end
            end
          end
        else
          time_entries=TneInvoiceTimeEntry.find(:all,:conditions=>["tne_invoice_id=? ",self.id])
          time_entries.each do |e|
            if e.secondary_tax
              if self.secondary_tax_rule
                if e.primary_tax
                  prim_tax = livia_round((e.final_billed_amount * self.primary_tax_rate)/100)
                  details_s_tax += livia_round(((e.final_billed_amount + prim_tax) * self.secondary_tax_rate)/100)
                else
                  details_s_tax += livia_round((e.final_billed_amount * self.secondary_tax_rate)/100)
                end
              else
                details_s_tax += livia_round((e.final_billed_amount * self.secondary_tax_rate)/100)
              end
            end
          end
          expense_entries=TneInvoiceExpenseEntry.find(:all,:conditions=>["tne_invoice_id=? ",self.id])
          expense_entries.each do |e|
            if e.secondary_tax
              if self.secondary_tax_rule
                if e.primary_tax
                  prim_tax = livia_round((e.final_expense_amount * self.primary_tax_rate)/100)
                  details_s_tax += livia_round(((e.final_expense_amount + prim_tax) * self.secondary_tax_rate)/100)
                else
                  details_s_tax += livia_round((e.final_expense_amount * self.secondary_tax_rate)/100)
                end
              else
                details_s_tax += livia_round((e.final_expense_amount * self.secondary_tax_rate)/100)
              
              end
            end
          end
        end
        s_tax = details_s_tax
      else
        s_tax = 0
      end
    else
      p_tax, s_tax = 0, 0
    end

    if self.discount
      n_total= self.invoice_amt + p_tax+ s_tax- self.discount
    end
    return p_tax, s_tax, n_total
  end

  # invoice will canceled with associated bill from matter_billing and both status will change to "Cancelled"
  # and also the time/ expense/ tne_invoice_time/ tne_invoice_expense entries status will change to "Approved"
  # 13 June 2011 Supriya Surve
  def cancel_invoice_and_bill
    cancelled = TneInvoiceStatus.find_by_company_id_and_lvalue(self.company_id, "Cancelled").id
    self.update_attribute(:tne_invoice_status_id, cancelled)
    time_entries = self.tne_invoice_time_entries
    if time_entries.length > 0
      time_entries.each do |timentry|
        if timentry.tne_time_entry_id.present?
          timentry.update_attributes(:tne_invoice_detail_id=>nil, :tne_invoice_id=>nil, :status=> "Approved")
          time_entry = Physical::Timeandexpenses::TimeEntry.find(timentry.tne_time_entry_id) if timentry.tne_time_entry_id
          time_entry.update_attribute(:status, "Approved") if time_entry.present?
        else
          timentry.destroy
        end
      end
    end

    expense_entries = self.tne_invoice_expense_entries
    if expense_entries.length > 0
      expense_entries.each do |expentry|
        if expentry.tne_expense_entry_id.present?
          expentry.update_attributes(:tne_invoice_detail_id=>nil, :tne_invoice_id=>nil, :status=> "Approved")
          exp_entry = Physical::Timeandexpenses::ExpenseEntry.find(expentry.tne_expense_entry_id) if expentry.tne_expense_entry_id
          exp_entry.update_attribute(:status, "Approved") if exp_entry.present?
        else
          expentry.destroy
        end
      end
    end
    mb = MatterBilling.find_by_tne_invoice_id_and_automate_entry(self.id, true)
    unless mb.nil?
      mb.update_attribute(:matter_billing_status_id, self.tne_invoice_status_id)
    end

    self.tne_invoice_details.each do |detail|
      detail.destroy
    end
    self.destroy
  end

  def self.get_invoices(company, status, params, search)
    conditions = "tne_invoices.company_id = #{company.id} "
    conditions << " and UPPER(tne_invoices.invoice_no) like '#{params[:letter]}%'"  if params[:letter].present?
    if (params[:mode_type]=="client" || params[:type]=="client")
      conditions << " and tne_invoices.contact_id is not null and tne_invoices.matter_id is null"
      conditions << " and DATE(tne_invoices.invoice_date) between \'#{params[:date_start]}\' and \'#{params[:date_end]}\'" unless params[:date_start].blank? && params[:date_end].blank?
      cancelled = company.tne_invoice_statuses.find_by_lvalue("Cancelled")
      conditions << " and tne_invoices.tne_invoice_status_id != #{cancelled.id}" unless (params[:status].to_i==cancelled.id)
    else
      unless status.blank?
        unless status.lvalue == "Cancelled"
          conditions << " and tne_invoices.matter_id is not null and tne_invoices.contact_id is null"
        else
          conditions << " and tne_invoices.matter_id is not null and DATE(tne_invoices.invoice_date) between \'#{params[:date_start]}\' and \'#{params[:date_end]}\'" unless params[:date_start].blank? && params[:date_end].blank?
        end
      else
        conditions << " and tne_invoices.matter_id is not null and tne_invoices.contact_id is null and DATE(tne_invoices.invoice_date) between \'#{params[:date_start]}\' and \'#{params[:date_end]}\'" unless params[:date_start].blank? && params[:date_end].blank?
      end
    end

    dir = params[:dir]=="down" ? "DESC" : "ASC"
    dir = params[:dir].eql?("up")? "desc" : "asc"  if params[:col].eql?("bill_pay_date")

    order = "tne_invoices.created_at DESC"
    if params[:col]
      if params[:col]=="matters.name"
        order = "#{params[:col]} #{dir}"
      elsif params[:col]=="contacts.name"
        order="coalesce(contacts.last_name,'')||''||contacts.first_name||''||coalesce(contacts.middle_name,'') #{dir}"
      elsif params[:col]=="type"
        order = nil
      elsif params[:col]=="billing_status"
        order = "company_lookups.alvalue #{dir}"
      elsif params[:col]=="matters.matter_no"
        order = "#{params[:col]} #{dir}"
      else
        order = "tne_invoices.#{params[:col]} #{dir}"
      end
    end
    unless search
      unless status.blank?
        conditions << " and tne_invoices.tne_invoice_status_id = #{status.id}"
        if status.lvalue=="Cancelled"
          self.paginate(:all, :only_deleted=>true, :conditions => conditions, :page=>params[:page], :per_page=>params[:per_page], :include => [{:matter => :contact}, :tne_invoice_status], :order => order)
        else
          self.paginate(:all, :conditions => conditions, :include => [{:matter => :contact}, :tne_invoice_status], :page=>params[:page], :per_page=>params[:per_page], :order => order)
        end
      else
        self.paginate(:all, :conditions => conditions, :include => [{:matter => :contact}, :tne_invoice_status], :page=>params[:page], :per_page=>params[:per_page], :order => order)
      end
    else
      self.find(:all, :conditions => conditions, :include => [{:matter => :contact}, :tne_invoice_status], :order => order)
    end
  end

  def bill_no
    bill= MatterBilling.find(:last,:conditions=>["bill_no ilike ? and company_id= ?",self.invoice_no,self.company_id])
    if bill && (!self.id.present? ||(self.id.present? && bill.tne_invoice_id != self.id) )
      self.errors.add_to_base("Invoice No Has Already Been Taken")
      return false
    else
      return true
    end
  end

  def update_time_expense_entries
    if self.time_entries_ids
      timeentries = TneInvoiceTimeEntry.find(self.time_entries_ids)
      if timeentries.size > 0
        timeentries.each do |timeentry|
          unless timeentry.tne_time_entry_id.nil?
            tne_timeentries = Physical::Timeandexpenses::TimeEntry.find(timeentry.tne_time_entry_id)
            tne_timeentries.status = 'Billed'
            tne_timeentries.tne_invoice_id=self.id
            tne_timeentries.save
          end
          timeentry.update_attributes(:status=>'Billed',:tne_invoice_id=>self.id)
        end
      end
    end
    if self.expense_entries_ids
      expenseentries = TneInvoiceExpenseEntry.find(self.expense_entries_ids)
      if expenseentries.size > 0
        expenseentries.each do |expenseentry|
          unless expenseentry.tne_expense_entry_id.nil?
            tne_expenseentries = Physical::Timeandexpenses::ExpenseEntry.find(expenseentry.tne_expense_entry_id)
            tne_expenseentries.status = 'Billed'
            tne_expenseentries.tne_invoice_id=self.id
            tne_expenseentries.save
          end
          expenseentry.update_attributes(:status=>'Billed',:tne_invoice_id=>self.id)
        end
      end
    end
    role_id = Role.find_by_name('lawyer').id if consolidated_by.eql?("User")
    #Code for updating Tne_invoice_id
    self.tne_invoice_details.each do |id|
      if self.consolidated_by == 'Activity'
        if id.entry_type == 'Time'
          act_type=  self.company.company_activity_types.find_by_alvalue(id.activity)
          time_entries=TneInvoiceTimeEntry.find(:all,:conditions=>["tne_invoice_id=? and activity_type=?",self.id,act_type.id])         
          for te in time_entries
            unless te.nil?
              te.tne_invoice_detail_id = id.id
              if view_by =='Summary'
                te.primary_tax=id.primary_tax
                te.secondary_tax=id.secondary_tax
              end
              te.save
            end
          end
        else
          act_type = CompanyLookup.find(:first,:conditions => ['company_id = ? and alvalue=? and type like ?',self.company_id,id.activity,"Physical::Timeandexpenses::ExpenseType"]).id rescue 0
          expense_entries=TneInvoiceExpenseEntry.find(:all,:conditions=>["tne_invoice_id=? and expense_type=?",self.id,act_type])
          for ee in expense_entries
            unless ee.nil?
              ee.tne_invoice_detail_id  = id.id
              if view_by =='Summary'
                ee.primary_tax=id.primary_tax
                ee.secondary_tax=id.secondary_tax
              end
              ee.save
            end
          end
        end
      elsif self.consolidated_by == 'User'
        lawyer_id = User.find(:first,:joins=>[:user_role],:conditions=>["user_roles.role_id = ? and company_id = ? and Lower(Trim(first_name || ' ' || coalesce(last_name,''))) = ? ",role_id,self.company_id,id.lawyer_name.downcase]).id rescue 0
        if id.entry_type == 'Time'
          time_entries=TneInvoiceTimeEntry.find(:all,:conditions=>["tne_invoice_id=? and employee_user_id=?",self.id,lawyer_id])
          for te in time_entries
            unless te.nil?
              te.tne_invoice_detail_id = id.id
              if view_by =='Summary'
                te.primary_tax=id.primary_tax
                te.secondary_tax=id.secondary_tax
              end
              te.save
            end
          end
        else
          #TODO: NEED TO CHECK WHY relationship is not working
          expense_entries=TneInvoiceExpenseEntry.find(:all,:conditions=>["tne_invoice_id=? and employee_user_id=?",self.id,lawyer_id])
          for ee in expense_entries
            unless ee.nil?
              ee.tne_invoice_detail_id  = id.id
              if view_by =='Summary'
                ee.primary_tax=id.primary_tax
                ee.secondary_tax=id.secondary_tax
              end
              ee.save
            end
          end
        end
      else
        if id.entry_type == 'Time'
          time_entries=TneInvoiceTimeEntry.find(:all,:conditions=>["tne_invoice_id=? and time_entry_date=?",self.id,id.tne_entry_date])
          for te in time_entries
            unless te.nil?
              te.tne_invoice_detail_id = id.id
              if view_by =='Summary'
                te.primary_tax=id.primary_tax
                te.secondary_tax=id.secondary_tax
              end
              te.save
            end
          end
        else
          #TODO: NEED TO CHECK WHY relationship is not working
          expense_entries=TneInvoiceExpenseEntry.find(:all,:conditions=>["tne_invoice_id=? and expense_entry_date=?",self.id,id.tne_entry_date])
          for ee in expense_entries
            unless ee.nil?
              ee.tne_invoice_detail_id  = id.id
              if view_by =='Summary'
                ee.primary_tax=id.primary_tax
                ee.secondary_tax=id.secondary_tax
              end
              ee.save
            end
          end
        end
      end
    end
  end

  # it is used to add commas and convert into float values in pdf and xls format
  def commas(num)
    if num.blank?
      number = ''
    else
      number=  num.to_f.fixed_precision(2).to_s.reverse.scan(/(?:\d*\.)?\d{1,3}-?/).join(',').reverse
    end
    return number
  end

  def get_invoice_detail_for_pdf(detailed)
    if contact_id
      primary_contact = contact
    elsif matter_id
      primary_contact = matter.contact
    end
    role_id = Role.find_by_name('lawyer').id if consolidated_by.eql?("User")
    p_tax,s_tax,n_total = self.calculate_tax
    summary_view,time_entry,expense_entry =[],[],[], []
    tne_invoice_details.map do |id|
      time_detailed_view,expense_detailed_view=[],[]
      if detailed
        case consolidated_by
        when 'Activity'
          time_entries,expense_entries = consolidated_by_activity(self, id.entry_type, id.activity)
          if id.entry_type == 'Time'
            time_detailed_view = time_entries.collect {|te| [te.time_entry_date,te.performer.full_name, commas(company.duration_setting.setting_value == "1/100th" ?  one_hundredth_timediffernce(te.actual_duration) : one_tenth_timediffernce(te.actual_duration)), commas(te.actual_activity_rate), te.description]}
           actual_duration = company.duration_setting.setting_value == "1/100th"?  one_hundredth_timediffernce(id.duration) : one_tenth_timediffernce(id.duration)
           time_entry <<[id.activity,time_detailed_view, commas(id.rate), actual_duration, commas(id.amount)]
          else
            expense_detailed_view = expense_entries.collect {|ee| [ee.expense_entry_date,ee.performer.full_name, commas(ee.final_expense_amount),ee.description,nil]}
            expense_entry << [id.activity,expense_detailed_view, '', '', commas(id.amount)]
          end
        when 'User'
          time_entries,expense_entries = consolidated_by_user(self, id.entry_type, id.lawyer_name)
          if id.entry_type == 'Time'
            time_detailed_view = time_entries.collect {|te| [te.time_entry_date, te.acty_type.alvalue, commas(company.duration_setting.setting_value == "1/100th" ?  one_hundredth_timediffernce(te.actual_duration) : one_tenth_timediffernce(te.actual_duration)), commas(te.actual_activity_rate), te.description]}
            actual_duration = company.duration_setting.setting_value == "1/100th" ?  one_hundredth_timediffernce(id.duration) : one_tenth_timediffernce(id.duration)
            time_entry <<[id.lawyer_name,time_detailed_view,commas(id.rate), actual_duration, commas(id.amount)]
          else
            expense_detailed_view = expense_entries.collect{|ee| [ee.expense_entry_date, ee.expense.alvalue , commas(ee.final_expense_amount), ee.description,nil]}            
            expense_entry << [id.lawyer_name,expense_detailed_view, '', '', commas(id.amount)]
          end
        when 'Date'
          time_entries, expense_entries = consolidated_by_date(self, id.entry_type, id.tne_entry_date)
          if id.entry_type == 'Time'
            time_detailed_view = time_entries.collect{|te| [te.acty_type.alvalue, te.performer.full_name, commas(company.duration_setting.setting_value == "1/100th" ?  one_hundredth_timediffernce(te.actual_duration) : one_tenth_timediffernce(te.actual_duration)), commas(te.actual_activity_rate), te.description]}
            actual_duration = company.duration_setting.setting_value == "1/100th" ?  one_hundredth_timediffernce(id.duration) : one_tenth_timediffernce(id.duration)
            time_entry <<[id.tne_entry_date,time_detailed_view, commas(id.rate), actual_duration, commas(id.amount)]
          else
            expense_detailed_view = expense_entries.collect{|ee| [ee.expense.alvalue, ee.performer.full_name, commas(ee.final_expense_amount), ee.description, nil]}
            expense_entry << [id.tne_entry_date,expense_detailed_view, '', '', commas(id.amount)]
          end
        end
      else
        actual_duration = company.duration_setting.setting_value == "1/100th" ?  one_hundredth_timediffernce(id.duration) : one_tenth_timediffernce(id.duration)
        summary_view<< [consolidated_by =='User' ? id.lawyer_name : (consolidated_by =='Activity' ?  id.activity : id.tne_entry_date.to_s), commas(id.rate),actual_duration.blank? ? '' : actual_duration,commas(id.amount)]
      end
    end
    return [primary_contact,p_tax,s_tax,n_total,time_entry,expense_entry,summary_view]
  end

  # It will get the time and expense entry for activity related to specific Invoice
  def consolidated_by_activity(tne_invoice, entry_type, activity)  
    if entry_type == 'Time'
      act_type = CompanyLookup.find(:first,:conditions => ['company_id = ? and alvalue=? and type ilike ?',tne_invoice.company_id,activity,"CompanyActivityType"]).id rescue 0
      time_entries=TneInvoiceTimeEntry.find(:all,:conditions=>["tne_invoice_id=? and activity_type=?",tne_invoice.id,act_type])
    else
      act_type = CompanyLookup.find(:first,:conditions => ['company_id = ? and alvalue=? and type like ?',tne_invoice.company_id, activity,"Physical::Timeandexpenses::ExpenseType"]).id rescue 0
      expense_entries = self.tne_invoice_expense_entries.select{|ee| ee.expense_type == act_type}
    end
    return time_entries, expense_entries
  end

  # It will get the time and expense entry for User related to specific Invoice
  def consolidated_by_user(tne_invoice, entry_type, lawyer)
    lawyer_name=lawyer.downcase.split(' ')
    lawyer_id = User.find(:first,:conditions=>['company_id = ? and Lower(Trim(first_name)) = ? and Lower(Trim(last_name)) = ? ',tne_invoice.company_id,lawyer_name[0],lawyer_name[1]]).id rescue 0
    if entry_type == 'Time'
      time_entries=TneInvoiceTimeEntry.find(:all,:conditions=>["tne_invoice_id=? and employee_user_id=?",tne_invoice.id,lawyer_id])
    else
      expense_entries = tne_invoice.tne_invoice_expense_entries.select{|ee| ee.employee_user_id == lawyer_id}
    end
    return time_entries, expense_entries
  end

  # It will get the time and expense entry for Date related to specific Invoice
  def consolidated_by_date(tne_invoice, entry_type, tne_entry_date)
    if entry_type == 'Time'
      time_entries=TneInvoiceTimeEntry.find(:all,:conditions=>["tne_invoice_id=? and time_entry_date=?",tne_invoice.id,tne_entry_date])
    else
      expense_entries = tne_invoice.tne_invoice_expense_entries.select{|ee| ee.expense_entry_date == tne_entry_date}
    end
    return time_entries, expense_entries
  end
  
end