class Invoice < ActiveRecord::Base
  belongs_to :company
  has_many :invoice_details
  has_many :payments
  
  acts_as_paranoid
  named_scope :grouped_records, lambda{|id|{ :group=>"product_id,date(product_purchase_date),cost,invoice_id", :conditions=>["invoice_id =?", id],:select=>"product_id,date(product_purchase_date) as product_purchase_date,invoice_id,cost,sum(count) as count,  sum(total_amount) as total_amount"}}
  def self.index_invoice(company_id,month,status)
    if company_id == "all"
      if month == "All"
        if status == "All"
           Invoice.all(:include => :company)
        else
          Invoice.find_all_by_status(status.to_s, :include => :company)
        end
      else
        if status == "All"
          Invoice.all(:conditions => ["extract(month from invoice_date) = #{month.to_i}"], :include => :company)
        else
          Invoice.all(:conditions => ["extract(month from invoice_date) = #{month.to_i} AND status = '#{status}'"], :include => :company)
        end
      end
    else
      if month == "All"
        if status == "All"
           Invoice.all(:conditions => ["company_id = #{company_id}"], :include => :company)
        else
          Invoice.all(:conditions => ["company_id = #{company_id} AND status = '#{status}'"], :include => :company)
        end
      else
        if status == "All"
           Invoice.all(:conditions => ["extract(month from invoice_date) = #{month.to_i} AND company_id = #{company_id}"], :include => :company)
      else
          Invoice.all(:conditions => ["extract(month from invoice_date) = #{month.to_i} AND status = '#{status}' AND company_id = #{company_id}"], :include => :company)
        end
      end
    end
  end

  def self.create_invoice(params)
      company = Company.find_by_id(params[:company][:id])
      licences = Licence.all(:conditions => ["(expired_date >= '#{params[:date_start].to_date}' OR expired_date IS NULL ) and start_date <'#{(params[:date_end].to_date + 1.days).to_date}' AND company_id=#{company.id}"])
      invoice = Invoice.new(:company_id=>company.id, :invoice_date=>Time.zone.now, :invoice_amount=>0, :invoice_from_date=>params[:date_start], :invoice_to_date=>params[:date_end],:status=>'Not Paid')
      invoiceTotalAmount=0
      unless licences.blank?
        licences.each do |licence|
          tempInvoiceDetailRecord = {}
          tempInvoiceDetailRecord[:company_id] = company.id
          tempInvoiceDetailRecord[:product_id] = licence.product_id
          tempInvoiceDetailRecord[:count] = licence.licence_count
          tempInvoiceDetailRecord[:licence_id] = licence.id
          tempInvoiceDetailRecord[:cost] = licence.cost
          tempInvoiceDetailRecord[:total_amount] = 0
          tempInvoiceDetailRecord[:billing_from_date] = params[:date_start]
          tempInvoiceDetailRecord[:billing_to_date] = params[:date_end]
          tempInvoiceDetailRecord[:product_purchase_date] = licence.start_date
          product_licences = ProductLicence.find_all_by_licence_id(licence.id)
          unless product_licences.blank?
            product_licences.each do |product_licence|
              (params[:date_start].to_date - product_licence.start_at.to_date).to_i > 0 ? (usage_start_date = params[:date_start]) : (usage_start_date = product_licence.start_at)
              if product_licence.deleted_at == nil
                if product_licence.end_at == nil || (params[:date_end].to_date - product_licence.end_at.to_date).to_i <= 0
                  usage_end_date = params[:date_end]
                else
                  usage_end_date = product_licence.end_at
                end
              else
                if (params[:date_end].to_date - product_licence.deleted_at.to_date).to_i > 0
                  usage_end_date = product_licence.deleted_at
                else
                  usage_end_date = params[:date_end]
                end
              end
              tempInvoiceDetailRecord[:total_amount] += (((usage_end_date.to_date + 1.days).to_date - usage_start_date.to_date).to_i * ((tempInvoiceDetailRecord[:cost].to_f * 12)/ 365)).round(2)
            end
            (licence.product_licences.first.licence_type.to_i == 1) ? (tempInvoiceDetailRecord[:status] = 1) : (tempInvoiceDetailRecord[:status] = 0)
            if (tempInvoiceDetailRecord[:total_amount] > 0) || tempInvoiceDetailRecord[:status] == 1
              invoiceTotalAmount += tempInvoiceDetailRecord[:total_amount]
              invoice.invoice_details.build(tempInvoiceDetailRecord)
            end
          end
        end
      end
      invoiceTotalAmount >0 ? invoice.invoice_amount = invoiceTotalAmount : invoice.status = "N/A"
      invoice.save
  end
  
end

# == Schema Information
#
# Table name: invoices
#
#  id                   :integer         not null, primary key
#  company_id           :integer         not null
#  invoice_date         :datetime        not null
#  invoice_from_date    :datetime
#  invoice_to_date      :datetime
#  invoice_amount       :decimal(12, 2)  not null
#  status               :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#  delta                :boolean         default(TRUE), not null
#  permanent_deleted_at :datetime
#  deleted_at           :datetime
#  created_by_user_id   :integer
#  updated_by_user_id   :integer
#

