module ProductLicencesHelper

  def end_date_tag
    option_list = [["No Expiry",0]]
    (1..36).each do |mnt|
      option_list << [mnt, mnt]
    end
    option_list = options_for_select(option_list)
    custom_select_tag "product_licence[end_date]", option_list,:prompt => 'No Expiry', :class => "field size3 dropbox"
  end

  def product_licence_status_option_tag(record)
    option_list = ProductLicence::Status
    option_list = options_for_select(option_list, record.status)
    select_tag "product_licence[status]", option_list,:class=>"dropbox"
  end

  def prodcts_sub_module_view(product)
    prd_view = ''
    for sub_prd in product.product_subproducts
     prd_view +=  "<p>#{sub_prd.product(sub_prd.product_id)}</p>"
    end
    prd_view
  end


  def get_licences_by_company_id(company_id)
       licences ||= Product.find(:all,:include=>[:product_licences=>[:subproduct_assignments=>:user]]).map{|prd| [prd, prd.product_licences.select{|o| o.company_id == company_id.to_i}.size,prd.product_licences.select{|o| o.company_id == company_id.to_i && o.licence_type == 0}.size, prd.product_licences.select{|o| o.company_id == company_id.to_i && o.licence_type == 1}.size, prd.product_licences.select{|o| o.company_id == company_id.to_i}]}
  end

  def licences_details_by_product(product_id, company_id)
    product_licences ||= ProductLicence.find_all_by_company_id_and_product_id(company_id, product_id,:include=>[{:subproduct_assignments=>:user}])
  end

  def company_products(company_id)
    prd = []
    @getlicence = ProductLicence.find(:all,
          :select => 'product_id',
          :conditions => {:company_id => company_id},:order => "product_id asc",
          :group => "product_id"
    )
    @getlicence.each do |pd|
      prd << [Product.find(pd.product_id).name, pd.product_id]
    end
    prd = [["-Select-", nil]] + prd
    option_list = options_for_select(prd)
    select_tag "role_assign[product_id]", option_list, :onchange => "get_company_licence_by_product(this.value,#{company_id},#{params[:id]})", :class=>'field size3'
  end
  
end
