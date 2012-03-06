class Product < ActiveRecord::Base
  has_many    :product_subproducts
  has_many    :subproducts, :through => :product_subproducts
  has_many    :product_licences
  has_many    :licences
  has_many    :invoice_details
  has_many    :company, :through => :product_licences  
  has_one     :productlimit
  has_many    :product_licences
  #has_and_belongs_to_many :product_dependents, :class_name => "Product", :join_table => "product_dependents", :foreign_key => "product_id", :association_foreign_key => "parent_id"
  has_many :product_dependents
  validates_presence_of :name, :message => :prod_name
  validates_presence_of :cost, :message => :prod_cost
  validates_uniqueness_of :name, :case_sensitive => false
  acts_as_paranoid #for soft delete

  def self.dependencies(params)
    productid = params[:role_assign][:product_id].to_i
    companyid = params[:comp_id]
    userid = params[:employee_id]
    licenceid = params[:role_assign][:licence_id]
    msg=''

    @user = User.find(userid)
    @mainproduct = self.find(productid.to_i)
    @dependent_products = @mainproduct.product_dependents.find_all
    depids = @dependent_products.collect{|y| y.parent_id.to_i}
    #Validation
    #Check If the selected product which has dependency is already assigend to user or not.
    @productlicence = ProductLicence.scoped_by_company_id_and_product_id(companyid, productid, 1)    
    @productlicence.each do |prd|
      prdtls = prd.product_licence_details.scoped_by_user_id(userid)
      if !prdtls.empty?
        msg = "#{@mainproduct.name} is already assigned !"
        return msg
      end
    end

    deps = []
    dep_assigned = []
    #Validations
    #check If Selected Product has its dependent products with status 0 for a users
    unless depids.empty?
      depids.each do |depid|
        @productlicence = ProductLicence.scoped_by_company_id_and_product_id(companyid, depid)
        @depprod = Product.find(depid)
        @productlicence.each do |prd|
          prdtl = prd.product_licence_details.scoped_by_user_id(userid)
          if !prdtl.empty? #Dependent Product is Present so you can assign
            deps << true # "Dependent Products Already Present, so you can add the product"
            dep_assigned << "#{@depprod.name}"
          else # Dependent Product is not present so you need to assign the dependent product
            deps << "#{@depprod.name}"
          end
        end
      end
      deps = deps.uniq!
      if deps != [true]
        deps = deps.to_a - [true].to_a
        deps = deps.to_a - dep_assigned.to_a
        if !deps.empty?
          msg = "#{@mainproduct.name} is dependent on #{deps.join(" and ").to_s}, so please assing the dependent products !"
        end
      end
    else
      @depprod = Product.find(productid)
      @productlicence = ProductLicence.scoped_by_company_id_and_product_id(companyid, productid)
      @productlicence.each do |prd|
        prdtl = prd.product_licence_details.scoped_by_user_id(userid)
        if !prdtl.empty?
          deps << "#{@depprod.name}"      
        else
          deps << true
        end
      end
      deps = deps.uniq! if deps.length > 1
      if deps.to_a != [true].to_a
        msg = "#{@depprod.name} is already assigned !"
      end      
    end
    msg
  end

  def self.with_licences(company_id)
    all(:include=>[:product_licences=>[:subproduct_assignments=>:user]]).map{|prd| [prd, prd.product_licences.select{|o| o.company_id == company_id.to_i}.size,prd.product_licences.select{|o| o.company_id == company_id.to_i && o.licence_type == 0}.size, prd.product_licences.select{|o| o.company_id == @company_id.to_i && o.licence_type == 1}.size, prd.product_licences.select{|o| o.company_id == company_id.to_i && o.status==1 && o.licence_type == 0}.size,  prd.product_licences.select{|o| o.company_id == company_id.to_i && o.status==1 && o.licence_type == 1}.size,prd.product_licences.select{|o| o.company_id == company_id.to_i}]}
  end

end

# == Schema Information
#
# Table name: products
#
#  id                   :integer         not null, primary key
#  name                 :string(64)      default(""), not null
#  created_at           :datetime
#  updated_at           :datetime
#  delta                :boolean         default(TRUE), not null
#  permanent_deleted_at :datetime
#  deleted_at           :datetime
#  created_by_user_id   :integer
#  updated_by_user_id   :integer
#  cost                 :integer         not null
#  description          :string(255)
#

