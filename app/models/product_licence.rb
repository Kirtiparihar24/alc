class ProductLicence < ActiveRecord::Base
  belongs_to :licences
  belongs_to :product
  belongs_to :company
  has_many :subproduct_assignments
  has_many :invoice_details
  has_many :product_licence_details

  validates_presence_of :company_id
  validates_presence_of :start_at
  #validates_presence_of :end_at
  acts_as_paranoid

  Status = [
    ['Un-Assigned', 0],
    ['Assigned', 1],
    ['De-Active',2]
  ]

  LICENCE_TYPE = [
    ['Permanent', 0],
    ['Temporary', 1]
  ]
 named_scope :company_id, lambda { |company_id|
    { :conditions=>["company_id = ?",company_id] }
  }



  def self.product_licence_save(licence,url)
    company_id = licence[:company].present? ? licence[:company].to_i : licence[:product_licence][:company_id].to_i 
    product_id = licence[:product_licence][:product_id].to_i
    end_date = licence[:product_licence][:end_date].to_i
    licence_type = licence[:product_licence][:licence_type].to_i
    end_at = Time.zone.now.to_date
    licence_date = end_at >> end_date.to_i
    if end_date.to_i == 0
      licence_end = nil
    else
      licence_end = licence_date.to_s
    end
    msg = ''
    product = Product.find(product_id, :include => :product_dependents)
    dependents = product.product_dependents.find_all
    dependent_product = dependents.collect{|a| Product.find(a.parent_id)}.flatten + [product]

    prd_sym = "product_licence_#{product_id}".to_sym
    subqty = licence[prd_sym][:qty].to_i
    if subqty<=0
      return msg = "#{product.name} quantity can't be blank or 0!"
    end

    #Validations
    dependents.each do |depval|
      prd_sym = "product_licence_#{depval.parent_id}".to_sym
      subqty = licence[prd_sym][:qty].to_i
      unassignlic = ProductLicence.scoped_by_status_and_company_id_and_product_id_and_licence_type(0, company_id, depval.parent_id, licence_type)
      if unassignlic.empty? and subqty <=0
        return msg = "#{Product.find(depval.parent_id).name} quantity can't be blank or 0!"
      end
    end

    #Validations
    if licence_type == 1
      total = 0
      unless dependent_product.empty?
        dependent_product.each do | depval|
          prd_sym = "product_licence_#{depval.id}".to_sym
          subqty = licence[prd_sym][:qty].to_i
          total += subqty
        end
      else
        prd_sym = "product_licence_#{product_id}".to_sym
        total = licence[prd_sym][:qty].to_i
      end
      company = Company.find(company_id)
      remaining = company.get_temporary_licence_usage
      if total > remaining
        return msg = "Sorry! You have crossed the temporary licences limit, you can purchase only #{remaining} temporary licences !"
      end
    end
    total_licences_array,email = [], {}
    unless dependent_product.empty?
      dependent_product.each do |dep|
        prd_sym = "product_licence_#{dep.id}".to_sym
        subqty = licence[prd_sym][:qty].to_i
        subprice = licence[prd_sym][:price].to_i
        prod_id = dep.parent_id rescue dep.id
        #if subqty > 0
          total_licences = {}
          total_licences[:product] = Product.find(prod_id).name
          total_licences[:count] = subqty
          total_licences[:price] = subprice
          total_licences[:start_date] = Time.zone.now.strftime('%m/%d/%y')
          total_licences[:end_date] = (licence_end.blank?? '' : licence_end.to_date.strftime('%m/%d/%y'))
          total_licences[:licence_type] = licence_type
          total_licences_array << total_licences
          licences = Licence.create(:company_id => company_id, :product_id =>  prod_id , :licence_count => subqty, :cost=> subprice, :start_date => Time.zone.now, :expired_date => licence_end)
        #end
        subqty.times do
          prd_lic = ProductLicence.new(
            :product_id => prod_id,
            :company_id => company_id,
            :start_at => Time.zone.now,
            :end_at => licence_end,
            :status => 0,
            :licence_key => generate_licence_key,
            :licence_cost => subprice,
            :licence_id => licences.id,
            :licence_type => licence_type
          )
          prd_lic.save
        end

      end
    end
    recipient = self.get_lawfirm_admin_email_for_companyid(company_id)
    cc = self.get_liviaadmin_email
    subject = "Licence purchase details"
    email[:total_licences_array] = total_licences_array
    liviaMailer = LiviaMailer
    #liviaMailer.deliver_licences_purchase_mail(url,cc,recipient, subject, email) if total_licences_array.length > 0

    msg
  end


  #this function is to get the email id of the lawfirm when a company id is provided
  def self.get_lawfirm_admin_email_for_companyid(company_id)
    user = User.find_all_by_company_id(company_id).find{|user| user if user.role?('lawfirm_admin') }
    user.blank? ? nil : user.email
  end

  #This function is to get the email id of liviaadmin
  def self.get_liviaadmin_email
    User.find(UserRole.find_by_role_id(Role.find_by_name("livia_admin").id).user_id).email
  end


  def self.generate_licence_key
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newkey = ""
    1.upto(16) { |i| newkey << chars[Kernel.rand(chars.size-1)] }

    newkey
  end

  def key_with_type
    type = LICENCE_TYPE[self.licence_type][0]
    "#{self.licence_key} (#{type})"
  end

  #This function is used to deactive/unassign the licence
  def self.product_licence_delete(product_licence,params)
      if params[:type] == 'd'
        product_licence.product_licence_details.destroy_all
        product_licence.subproduct_assignments.destroy_all
        product_licence.destroy
      elsif params[:type] == 'u'
        #TODO Before Unassigning the Product check if the product has dependency then don't allow to unassign.
        product_licence.update_attributes({:status => 0})
        product_licence.product_licence_details.destroy_all
        product_licence.subproduct_assignments.destroy_all
      end
  end
end

# == Schema Information
#
# Table name: product_licences
#
#  id                 :integer         not null, primary key
#  product_id         :integer         not null
#  company_id         :integer
#  licence_key        :string(255)     not null
#  licence_cost       :float           not null
#  start_at           :datetime        not null
#  end_at             :datetime
#  deleted_at         :datetime
#  created_by_user_id :integer
#  updated_by_user_id :integer
#  created_at         :datetime
#  updated_at         :datetime
#  status             :integer         default(0)
#  licence_id         :integer         not null
#  licence_type       :integer         default(0), not null
#

