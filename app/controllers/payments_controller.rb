class PaymentsController < ApplicationController
  load_and_authorize_resource
  #This function is used to create the payment record
  layout 'admin'

  def create
    #Added Exception Hadling
    begin
      params[:payment][:invoice_id] = params[:invoice_id]
      @mode_id = params[:payment][:payment_mode]
      params[:payment][:payment_mode].blank?? '' : (params[:payment][:payment_mode] = Lookup.find_by_id(params[:payment][:payment_mode]).lvalue )
      @payment = Payment.new(params[:payment])
      if params[:payment][:payment_mode] == "Cheque"
        if params[:payment][:cheque_no].blank? || params[:payment][:cheque_date].blank? || params[:payment][:bank_name].blank? || params[:payment][:branch_name].blank?
          @payment.errors.add_to_base(t(:pay_mandatory_fill))
        end
      elsif params[:payment][:payment_mode] == "Paypal" && params[:payment][:paypal_account_id].blank?
        @payment.errors.add_to_base(t(:pay_mandatory_fill))
      end
      respond_to do |format|
        if @payment.errors.size == 0 && @payment.save
          @invoice = Invoice.find_by_id(params[:invoice_id])
          if (Payment.sum(:amount, :conditions=>['invoice_id=?', @invoice.id])).to_i >= @invoice.invoice_amount.to_i
            params[:payment][:status] = 'Paid'
            @invoice.update_attributes(:status=>'Paid')
          elsif (((Payment.sum(:amount, :conditions=>['invoice_id=?', @invoice.id])).to_i < @invoice.invoice_amount.to_i) && (Payment.sum(:amount, :conditions=>['invoice_id=?', @invoice.id])).to_i > 0)
            params[:payment][:status] = 'Partially Paid'
            @invoice.update_attributes(:status=>'Partially Paid')
          end
          flash[:notice] = "#{t(:text_payment_record)} " "#{t(:flash_was_successful)} " "#{t(:text_added)}"
          format.html { redirect_to :controller=>'invoices',:action => 'index'}
          format.xml  { render :xml => @user }
        else
          @amount = Invoice.sum(:invoice_amount,:conditions=>["id = ?", params[:invoice_id]]) - Payment.sum(:amount, :conditions=>['invoice_id = ?', params[:invoice_id]])
          @payment_modes = Lookup.payment_mode_type
          @payment_type = params[:payment][:payment_mode]
          params[:id] = params[:invoice_id]
          format.html { render :action => "new" }
          format.xml  { render :xml => @payment.errors }
        end
      end
    rescue Exception =>e
    end
  end

  #This function is used to provide the information required for creation of a new payment record
  def new
    @amount = Invoice.sum(:invoice_amount, :conditions => ["id = ?", params[:id]]) - Payment.sum(:amount, :conditions => ['invoice_id = ?', params[:id]])
    @payment = Payment.new
    @payment_modes = Lookup.payment_mode_type
  end

  #This function is used to show complete details of the selected payment record
  def show
    @payment = Payment.find(params[:id])
  end

  #Function to find the selected payment_mode for the dropdown in form for creation of Payment record. This function is called from "payment_mode_change" function in livia_common.js
  def payment_mode_of_selected_id
    @payment_mode = Lookup.find_by_id(params[:selected_value]).lvalue
  end

end
