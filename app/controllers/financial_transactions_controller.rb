class FinancialTransactionsController < ApplicationController
  before_filter :authenticate_user!
  cache_sweeper :financial_transaction_sweeper, :only =>[:create, :update, :destroy, :record_payment, :update_payment, :inter_transfer, :update_inter_transfer]
  load_and_authorize_resource
  layout :financial_account_transaction_layout
  def index

  end

  def new
    @financial_account = FinancialAccount.find(params[:financial_account_id], :conditions => ["company_id = ?", current_company.id])
    @financial_transaction = FinancialTransaction.new
  end
 
  def create
    @financial_account = FinancialAccount.find(params[:financial_account_id], :conditions => ["company_id = ? ", current_company.id])
    @financial_transaction = FinancialTransaction.new(params[:financial_transaction].merge!({:company_id => current_company.id, :financial_account_id => @financial_account.id}))
    if(@financial_transaction.valid? && @financial_transaction.errors.empty?)
      FinancialTransaction.transaction do
        @financial_transaction.save!
        @financial_transaction.create_update_matter_retainer_receipt unless @financial_transaction.matter_id.blank?
      end
      redirect_to financial_account_path(@financial_account)
    else
      render_the_action('new')
    end
  end

  def edit
    @financial_account = FinancialAccount.find(params[:financial_account_id], :conditions => ["company_id = ? ", current_company.id])
    @financial_transaction = FinancialTransaction.find(params[:id], :conditions => ["company_id = ? AND financial_account_id = ? ", current_company.id, @financial_account.id])
    render :layout => false if request.xhr?
  end
  
  def update
    @financial_account = FinancialAccount.find(params[:financial_account_id], :conditions => ["company_id = ?", current_company.id])
    @financial_transaction = FinancialTransaction.find(params[:id], :conditions => ["company_id = ? AND financial_account_id = ? ", current_company.id, @financial_account.id])
    @financial_transaction.attributes = params[:financial_transaction]
    if (@financial_transaction.valid? && @financial_transaction.errors.empty?)
      @financial_transaction.updated_by = current_user.id
      FinancialTransaction.transaction do
        @financial_transaction.save!
        @financial_transaction.create_update_matter_retainer_receipt(false) unless @financial_transaction.matter_id.blank?
        @financial_transaction.matter_retainers.first.destroy if (@financial_transaction.matter_id.blank? && !@financial_transaction.matter_retainers.empty?)
      end
      return_path = params[:return_action] ? bill_retainers_matter_matter_billing_retainers_path(@financial_transaction.matter.id) : financial_account_path(@financial_account)
      redirect_to return_path
    else
      render_the_action('edit')
    end
  end

  def record_payment
    @financial_account = FinancialAccount.find(params[:financial_account_id], :conditions => ["company_id = ?", current_company.id])
    if request.get?
      @financial_transaction = FinancialTransaction.new
    else
      @financial_transaction = FinancialTransaction.new(params[:financial_transaction].merge!({:company_id => current_company.id, :financial_account_id => @financial_account.id}))
      FinancialTransaction.the_controller_action_name('payment')
      if (@financial_account.valid? && @financial_account.errors.empty?)
        FinancialTransaction.transaction do
          @financial_transaction.transaction_type = false
          @financial_transaction.save!
          @financial_transaction.create_update_matter_billing(params[:matter_billing_status_id]) if(@financial_transaction.invoice_no)
        end
        redirect_to financial_account_path(@financial_account)
      else
        matter_invoices_and_approval_clients
        render_the_action('record_payment')
      end
    end
  end

  def update_payment
    @financial_account = FinancialAccount.find(params[:financial_account_id], :conditions => ["company_id = ?", current_company.id])
    @financial_transaction = FinancialTransaction.find(params[:id], :conditions => ["company_id = ?  AND financial_account_id = ? ", current_company.id, @financial_account.id])
    matter_invoices_and_approval_clients
    if request.get?
    else
      @financial_transaction.attributes = params[:@financial_transaction].merge!({:company_id => current_company.id, :financial_account_id => @financial_account.id})
      if (@financial_transaction.valid? && @financial_transaction.errors.empty?)
        FinancialTransaction.transaction do
          @financial_transaction.transaction_type = false
          if (@financial_transaction.invoice_no && params[:financial_transaction][:invoice_no])
            action_str = 'edit'
          elsif (@financial_transaction.invoice_no && params[:financial_transaction][:invoice_no] == nil)
            action_str = 'delete'
          end
          @financial_transaction.create_update_matter_billing(params[:matter_billing_status_id], action_str) if @financial_transaction.invoice_no
          @financial_transaction.invoice_no = nil if action_str == 'delete'
          @financial_transaction.save!
        end
        redirect_to financial_account_path(@financial_account)
      else
        render_the_action('update_payment')
      end
    end
  end

  def inter_transfer
    @financial_account = FinancialAccount.find(params[:financial_account_id], :conditions => ["company_id = ?", current_company.id])
    if request.get?
      @financial_transaction = FinancialTransaction.new
    else
      @financial_transaction = FinancialTransaction.new(params[:financial_transaction].merge!({:company_id => current_company.id}))
      @financial_transaction.inter_transfer = true
      @financial_transaction.financial_account_id = params[:financial_account_debited_no]
      @financial_transaction.transaction_type = false
      if (@financial_transaction.valid? && @financial_transaction.errors.empty?)
        FinancialTransaction.inter_transfer_transaction(@financial_transaction,params)
        redirect_to financial_account_path(@financial_account)
      else
        render_the_action('inter_transfer')
      end
    end
  end
  
  def update_inter_transfer
    @financial_account = FinancialAccount.find(params[:financial_account_id], :conditions => ["company_id = ?", current_company.id])
    if request.get?
      @financial_transaction = FinancialTransaction.find(params[:id], :conditions => ["company_id = ? AND financial_account_id = ? ", current_company.id, @financial_account.id])
    else
      @financial_transaction = FinancialTransaction.find(params[:id], :conditions => ["company_id = ? AND financial_account_id = ? ", current_company.id, @financial_account.id])
      @financial_transaction.inter_transfer = true
      @financial_transaction.attributes = params[:financial_transaction].merge!({:company_id => current_company.id})
      if (@financial_transaction.valid? && @financial_transaction.errors.empty?)
        FinancialTransaction.inter_transfer_transaction_update(@financial_transaction,params)
        redirect_to financial_account_path(@financial_account)
      else
        render_the_action('update_inter_transfer')
      end
    end
  end

  def client_contacts
    matter= Matter.find(params[:matter_id],:conditions => "company_id=#{current_company.id}")
    if(params[:type])
      matter_billings = FinancialTransaction.matter_invoice_nums(matter.id,current_company.id)
    else
      client_contacts = matter.matter_peoples.client_contacts_and_matter_client
    end
    list_box = ""
    billed_amt = paid_amt = balance = nil
    if(client_contacts && client_contacts.size > 0)
      list_box = "<select id='financial_transaction_approved_by' name='financial_transaction[approved_by]'>"
      client_contacts.each do |contact|
        list_box = list_box + "<option value='#{contact.id}'>#{contact.name}</option>"
      end
      list_box = list_box + "</select>"
    elsif(params[:type] && matter_billings && matter_billings.size > 0)
      billed_amt = matter_billings[0].billed_amt
      paid_amt = matter_billings[0].paid_amt
      balance_amt = matter_billings[0].balance_amt
      list_box = "<select id='financial_transaction_invoice_no' name='financial_transaction[invoice_no]'>"
      matter_billings.each do |invoice_no|
        list_box = list_box + "<option value='#{invoice_no.bill_no}' billed_amt='#{invoice_no.billed_amt}' paid_amt='#{invoice_no.paid_amt}' balance='#{invoice_no.balance_amt}'>#{invoice_no.bill_no}</option>"
      end
      list_box = list_box + "</select>"
    end
    if(billed_amt)
      list_box = list_box + "bre#{billed_amt}bre#{paid_amt}bre#{balance_amt}"
    end
    render :text=> list_box
  end

  def matter_invoices_and_approval_clients
    if (@financial_transaction.matter_id && @financial_transaction.invoice_no)
      @matter_billings = FinancialTransaction.matter_invoice_nums(@financial_transaction.matter_id,current_company.id)
      @selected_invoice_no = @financial_transaction.invoice_no
      selected_amt_paid_and_balance = @matter_billings.group_by(&:bill_no)[@financial_transaction.invoice_no.to_s]
      if (selected_amt_paid_and_balance && selected_amt_paid_and_balance.size > 0)
        @billed_amt = selected_amt_paid_and_balance[0].billed_amt
        @paid_amt = selected_amt_paid_and_balance[0].paid_amt
        @amount_to_paid = selected_amt_paid_and_balance[0].balance_amt
      end
    end
    if @financial_transaction.approved_by
      @approvel_clients = @financial_transaction.matter.matter_peoples.client_contacts_and_matter_client
      @selected_client_id = @financial_transaction.approved_by
    end
  end

  def render_the_action(action_name='index',partial=nil,locals={})
    respond_to do |format|
      if partial
        format.js { render :partial=> partial, :locals => locals}
        format.html { render :partial=> partial, :locals => locals}
      else
        format.html {render :action => action_name.to_sym}
      end
    end
  end

  private

  def financial_account_transaction_layout
    is_lawfirmadmin || is_liviaadmin ? 'admin' : 'full_screen'
  end

end
