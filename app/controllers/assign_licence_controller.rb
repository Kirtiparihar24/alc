class AssignLicenceController < ApplicationController
  include ApplicationHelper
  before_filter :authenticate_user!
  load_and_authorize_resource :except=>[:assignuser,:show,:show_licences]
  
  layout 'admin'

  # This function is used to get the information about all the licences of the selected company. The detials are like no. of licences purchased,used and unsed along with thier type such as temporary or permanent
  def show
    authorize!(:show,current_user) unless current_user.role?(:livia_admin)||current_user.role?(:lawfirm_admin)
    @clusters = Cluster.all
    if params[:populate].eql?("employees")
      session[:company_id] = params[:id]
      #@company_id = params[:id]
      company_total_licences_details(params[:id])
      @licences = Product.with_licences(params[:id])
      @activeusers = SubproductAssignment.scoped_by_company_id_and_employee_user_id(params[:id],nil).all(:select => 'user_id').collect{|sa| sa.user_id}.uniq.compact
    end
    if params[:populate].eql?("products")
      session[:company_id] = params[:comp_id]
      @user = User.find(params[:id])
      @productlicencedetails = @user.product_licence_details
      @productlicence = ProductLicence.scoped_by_company_id(params[:comp_id], :order => 'product_id asc').scoped_by_status(1)
    end
    @company = Company.find(session[:company_id])
    respond_to do |format|
      format.js
    end    
  end

  # This fucntion is uesd to assign the licences to the selected user.
  # While assigning the licences it has to check whether the licences arew having any dependencies or not and
  # if dependencies are there whether they are alreary assigned or not.
  # While assigning a licence to a user the related modules assignment records are to be created
  def assignuser
    authorize!(:assignuser,current_user) unless current_user.role?(:livia_admin)||current_user.role?(:lawfirm_admin)
    if current_user.role?(:livia_admin)
      session[:company_id] = session_status
      @companies = Company.company(current_user.company_id)
      !params[:company_id].blank?? session[:company_id] = params[:company_id] : params[:company_id] = session[:company_id]
      @company = Company.find(session[:company_id]) unless session[:company_id].blank?
    else
      @company = current_user.company
      session[:company_id] = @company.id
    end
    @clusters = Cluster.all
    if request.xhr?
      @user = User.find(params[:employee_id])

      @clusterid = @user.cluster_users.all(:select => ['cluster_id']).collect{|a| a.cluster_id}

      @msg = Product.dependencies(params)
      unless @msg.present?        
        # Added transaction block ---santoshChalla
        ProductLicenceDetail.transaction do
          lid = params[:role_assign][:licence_id]
          @pl  = ProductLicence.find(lid)
          @pld = ProductLicenceDetail.create(:user_id => params[:employee_id],
            :product_licence_id => @pl.id,
            :start_date => Time.zone.now,
            :expired_date => @pl.end_at,
            :status => 1
          )
          if params[:cluster_ids].present?
            clusters = Cluster.find(params[:cluster_ids])
            lawfirm_user = Employee.first :conditions => ['user_id = ?', params[:employee_id]]
            for cluster in clusters
              @clusteruser = ClusterUser.find_or_create_by_user_id_and_cluster_id(params[:employee_id], cluster.id)
              cluster_users = cluster.cluster_users
              for cu in cluster_users
                if cu.user && cu.user.service_provider != nil
                  service_provider_id = cu.user.service_provider.id
                  @mappings = Physical::Liviaservices::ServiceProviderEmployeeMappings.create(:service_provider_id=>service_provider_id, :employee_user_id=>lawfirm_user.user_id)
                end
              end
            end
          end
          mailmodule = Subproduct.find_by_name('Mail')
          service_assignment = Physical::Liviaservices::ServiceProviderEmployeeMappings.find_all_by_employee_user_id(params[:employee_id])
          secretary = service_assignment.collect{|s| s.service_provider.user}
          @pl.product.subproducts.each do |sp|
            @subproduct_assignment=SubproductAssignment.create(:user_id => params[:employee_id],
              :subproduct_id => sp.id,
              :product_licence_id => @pl.id,
              :company_id=> params[:comp_id]
            )
            unless secretary.blank?
              secretary.each do |sps|
                if mailmodule.id != sp.id
                  @subproduct_assignmentmail = SubproductAssignment.find_or_create_by_user_id_and_subproduct_id_and_product_licence_id_and_company_id_and_employee_user_id(:user_id => sps.id, :subproduct_id => sp.id,:product_licence_id => @pl.id,:company_id => params[:comp_id], :employee_user_id => params[:employee_id])
                end
              end
            end
          end
          @pl.update_attributes(:status => true)
        end
        params[:populate]="all"
        show
      end
    else
      if params[:id] != nil || session[:company_id] != nil
        @company_id = params[:id] || session[:company_id]
        company_total_licences_details(@company_id)       
        @licences = Product.with_licences(@company_id)
        @activeusers = SubproductAssignment.scoped_by_company_id_and_employee_user_id(@company_id,nil).all(:select => 'user_id').collect{|sa| sa.user_id}.uniq.compact
      end
    end
  end

  #This funciton is used to get the complete detials of all the licences of a provided company id and product id
  def show_licences
    @plicences = ProductLicence.find_all_by_company_id_and_product_id_and_status(params[:comp_id], params[:prod_id], 0)
    render :partial => 'show_licences', :locals => {:plicences => @plicences}
    authorize!(:show_licences,current_user) unless current_user.role?(:livia_admin)||current_user.role?(:lawfirm_admin)
  end

  private
  def company_total_licences_details(company_id)
    @employees = User.find_user_role_lawyer(company_id)
    @productlicence = ProductLicence.scoped_by_company_id(company_id)
    @activepermlicence = @productlicence.select {|o| o.licence_type == 0}.size
    @activetemplicence = @productlicence.select {|o| o.licence_type == 1}.size
    @usedpermlicence = @productlicence.select {|o| o.status == 1 && o.licence_type == 0}.size
    @usedtemplicence = @productlicence.select {|o| o.status == 1 && o.licence_type == 1}.size

  end

  #This function is to send the mail when a licene has been assigned to a lawyer
  def licence_assignment_details_mail()
    url=url_link
    user = User.find(@pld.user_id)
    recipient = []
    recipient << user.email
    recipient << get_lawfirm_admin_email(@pld.user_id)
    cc = current_user.email
    subject = "Licence assignment details"
    email = {}
    email[:notice] = "#{Product.find(@pl.product_id).name} licence has been assigned to #{user.full_name}"
    @liviaMailer = LiviaMailer    
  end

end
