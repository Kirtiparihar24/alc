# Handles the billing and receipts made for the matter.

class MatterBillingRetainersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :current_service_session_exists
  before_filter :get_service_session
  before_filter :get_matter, :get_statuses
  before_filter :check_for_matter_acces, :only=>[:bill_retainers]
  before_filter :check_access_to_matter,:except=>[:edit_bill_payment_details, :update_bill_payment_details, :destroy, :billing_history,:edit_bill,:update_bill]
  before_filter :get_user, :only => [:bill_retainers,:edit_bill]
  layout 'left_with_tabs', :except => [:new_bill_payment_details, :new_retainer]
  
  add_breadcrumb I18n.t(:text_matters), :matters_path

  def new_bill
    @bill = @matter.matter_billings.new
    @oldbill = nil
    render :partial => "new_bill", :locals => {:page_reload => params[:page_reload]}
  end

  def new_retainer
    @retainer = @matter.matter_retainers.new
    render :partial => "new_retainer", :locals => {:page_reload => params[:page_reload]}
  end
  
  def upload(id, type)
    user_id = get_employee_user_id
    bill_comment = Comment.first(:conditions => {:commentable_type => type, :commentable_id => id}, :order => "created_at DESC")
    mapable_id = bill_comment ? bill_comment.id : id
    mapable_type =  bill_comment ? 'Comment' : type
    data=params
    company_id=get_company_id
    if data[:document_home].present?
      data[:document_home].merge!(:access_rights=>2, :employee_user_id=>user_id ,
        :created_by_user_id=>current_user.id,:company_id=>company_id,
        :mapable_id=> mapable_id,:mapable_type=> mapable_type,:upload_stage=>1,:owner_user_id=>user_id)
      unless DocumentHome.create_new_document(data[:document_home])
        # TODO:
        # Add error message!        
      end
    end    
  end

  def billing_history
    @history = Comment.find_with_deleted(:all,:conditions => ["commentable_type ='MatterBilling' AND commentable_id = ?", "#{params[:id]}"], :order => "created_at DESC")
    render :layout => false
  end
  
  def bill_retainers
    authorize!(:bill_retainers,@user) unless @user.has_access?('Billing & Retainer')
    @bill = @matter.matter_billings.new
    @retainer = @matter.matter_retainers.new
    status = params[:status].present? ? params[:status] : TneInvoiceStatus.find_by_lvalue_and_company_id("Cancelled", @matter.company_id).id    
    @bills = @matter.matter_billings.all(:conditions => "id = bill_id")
    @retainers = @matter.matter_retainers
    @matter_retainer_fee = @matter
    @pagenumber=153
    add_breadcrumb t(:text_billing_retainer), bill_retainers_matter_matter_billing_retainers_path(@matter)
  end

  def new_bill_payment_details    
    @bill = @matter.matter_billings.new
    render :layout => false
  end
  
  def create_bill_payment_details
    params[:matter_billing].merge!({
        :created_by_user_id => current_user.id,
        :company_id => get_company_id
      })
    @errors = []
    params[:matter_billing][:bill_no] = (params[:matter_billing][:bill_no]).strip if params[:matter_billing][:bill_no]
    @bill = @matter.matter_billings.new(params[:matter_billing])
    if @bill.bill_amount_paid.nil? or @bill.bill_amount_paid.blank?
      @bill.bill_amount_paid = 0
    end
    if(params[:use_financial_account] =='1')
      trust_transaction_hash = {:company_id => current_company.id, :transaction_date => params[:matter_billing][:bill_pay_date],
        :amount=>params[:matter_billing][:bill_amount_paid],:transaction_type=>false, :matter_id => @matter.id, :account_id => @matter.account.id,
        :details => params[:matter_billing][:remarks], :payer => current_user.full_name}
      @financial_transaction = FinancialTransaction.new(params[:financial_transaction].merge!(trust_transaction_hash))
      @financial_transaction.valid?
      @errors = @financial_transaction.errors.full_messages
    end
	@bill.valid?
    @errors += @bill.errors.full_messages

    responds_to_parent do |format|
      respond_to do |format|
        MatterBilling.transaction do
          if (@errors.empty? && @bill.save)			
			@financial_transaction.save! if @financial_transaction
            @bill.bill_id = @bill.id
            @bills = @matter.matter_billings.all(:conditions => ["id = ? ", @bill.id])
            @retainers = @matter.matter_retainers
            @bill.send(:update_without_callbacks)
            upload(@bill.id, 'MatterBilling')
            update_document_comment(@bill.id)
          end
          format.js
        end
      end
    end
  end

  def edit_bill_payment_details
    @oldbill = @matter.matter_billings.find(params[:id])
    @bill = @matter.matter_billings.new(:bill_id=>@oldbill.id, :matter_billing_status_id => @oldbill.matter_billing_status_id)
    render :partial => "new_bill"
  end
  
  def update_bill_payment_details
    @oldbill = @matter.matter_billings.find(params[:id])
    @bill = @matter.matter_billings.new(params[:matter_billing])
    @bill.bill_id = @oldbill.id
    @bill.bill_amount = @oldbill.bill_amount
    @errors = []
    if(params[:use_financial_account] =='1')
      financial_transaction_hash = {:company_id => current_company.id, :transaction_date => params[:matter_billing][:bill_pay_date],
        :amount=>params[:matter_billing][:bill_amount_paid],:transaction_type=>false, :matter_id => @matter.id, :account_id => @matter.account.id,
        :details => params[:matter_billing][:remarks], :payer => current_user.full_name}
      @financial_transaction = FinancialTransaction.new(params[:financial_transaction].merge!(financial_transaction_hash))
      @financial_transaction.valid?
      @errors = @financial_transaction.errors.full_messages
    end
    @bill.valid?
    @errors += @bill.errors.full_messages
    responds_to_parent do
      respond_to do |format|
        # Name: Mandeep Singh
        # Date: Sep 9, 2010
        # Transaction purpose: Save additional bill payment and associated document.
        # Tables affected: matter_bilings, document_homes, documents, assets.
        MatterBilling.transaction do
          if (@errors.empty? && @bill.save)			
            @financial_transaction.save! if @financial_transaction
            @oldbill.matter_billing_status_id = @bill.matter_billing_status_id
            @oldbill.send(:update_without_callbacks)
            @bills = @matter.matter_billings.all(:conditions => ["id = ? ", @bill.id])
            @retainers = @matter.matter_retainers
            upload(@bill.id, 'MatterBilling')
            update_document_comment(@bill.id)
          end
          format.js
        end
      end
    end
  end

  def edit_bill
    @bill = @matter.matter_billings.find(@matter.matter_billings.find(params[:id]).bill_id)
    respond_to do |format|
      format.js {render :partial => "modal_edit_bill"}
    end
  end

  def update_bill
    @bill = @matter.matter_billings.find(@matter.matter_billings.find(params[:id]).bill_id)
    params[:matter_billing][:bill_no] = (params[:matter_billing][:bill_no]).strip if params[:matter_billing][:bill_no]
    responds_to_parent do
      respond_to do |format|
        MatterBilling.transaction do
          if @bill.update_attributes(params[:matter_billing])
            @bills = @matter.matter_billings.all(:conditions => ["id = ? ", @bill.id])
            @retainers = @matter.matter_retainers
            upload(@bill.id, 'MatterBilling')
            update_document_comment(@bill.id)
          end
          format.js{render "update_bill_payment_details"}
        end
      end
    end
  end

  def create_retainer    
    params[:matter_retainer].merge!({
        :created_by_user_id => current_user.id,
        :company_id => get_company_id
      })
    @retainer = @matter.matter_retainers.new(params[:matter_retainer])    
    respond_to_parent do
      respond_to do |format|
        # Name: Mandeep Singh
        # Date: Sep 9, 2010
        # Transaction purpose: Save the matter retainer and associated document.
        # Tables affected: matter_retainers, document_homes, documents, assets.
        MatterRetainer.transaction do
          if @retainer.save
            # Upload associated receipt.
            @bills = @matter.matter_billings.all(:conditions => "id = bill_id")
            @retainers = @matter.matter_retainers
            upload(@retainer.id, 'MatterRetainer')
          end
          format.js
        end
      end
    end
  end

  def edit_retainer
    @retainer = @matter.matter_retainers.find(params[:id])
    respond_to do|format|
      format.js { 
        render :partial => "new_retainer", :locals => {:page_reload => params[:page_reload]}
      }
    end
  end

  def update_retainer
    @retainer = @matter.matter_retainers.find(params[:id])
    @bills = @matter.matter_billings.all(:conditions => "id = bill_id")
    @retainers = @matter.matter_retainers
    respond_to_parent do
      respond_to do |format|
        if @retainer.update_attributes(params[:matter_retainer])
          upload(@retainer.id, 'MatterRetainer')
        end
        format.js
      end
    end
  end

  def destroy
    bill = @matter.matter_billings.find(params[:id])
    invoice_no = bill.bill_no
    if bill.tne_invoice.blank?
      cancelstatus = TneInvoiceStatus.find_by_lvalue_and_company_id("Cancelled", @matter.company_id)
      bill.update_attribute(:matter_billing_status_id, cancelstatus.id)      
    else
      bill.tne_invoice.cancel_invoice_and_bill
    end
    respond_to do |format|
      flash[:notice] = "#{t(:text_invoice)} No. #{invoice_no}  was  #{t(:flash_was_successful)}  cancelled."
      if params[:return_path].present? && !params[:return_path].blank?
        return_path = remember_past_path
      else
        return_path = bill_retainers_matter_matter_billing_retainers_path(@matter)
      end
      format.html { redirect_to return_path }
      format.xml  { head :ok }
    end
  end

  def get_statuses
    @matter_billing_statuses = @company.tne_invoice_statuses.reject{|status| status.lvalue == "Cancelled" || status.lvalue == "Partly Settled"}
  end

  def update_document_comment(id)
    comment = Comment.first(:conditions => ["commentable_type = 'MatterBilling' AND commentable_id = #{id}"], :order => "created_at DESC")
    unless comment.blank?
      unless comment.document_homes.blank?
        document = comment.document_homes.first.latest_doc
        unless document.blank?
          document.comment_id = comment.id
          document.send(:update_without_callbacks)
        end
      end
    end
  end
end
