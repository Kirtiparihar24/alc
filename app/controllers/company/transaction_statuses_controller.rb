class Company::TransactionStatusesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('transaction_statuses')",:only=>:index
  layout "admin"
  def index

  end
  def new
    @transaction_status = @company.transaction_statuses.new
    render :layout=>false
  end

  def create
    transaction_status_types = @company.transaction_statuses
    transaction_statuscount = transaction_status_types.count
    if transaction_statuscount > 0
      params[:transaction_status][:sequence] = transaction_statuscount+1
    end
    lvalue = params[:transaction_status][:lvalue].blank? ? params[:transaction_status][:alvalue] : params[:transaction_status][:lvalue]
    @transaction_status_type = TransactionStatus.new(params[:transaction_status].merge(:lvalue=>lvalue))
    if @transaction_status_type.valid? && @transaction_status_type.errors.empty?
      @company.transaction_statuses << @transaction_status_type
      #set_sequence_for_lookups(@company.@company.financial_account_types)
    end
    render :update do |page|
      unless !@transaction_status_type.errors.empty?
        page<< 'tb_remove();'
        flash[:notice] = "Transaction Status was successfully created"
        page<<"window.location.href='#{manage_company_utilities_path('transaction_statuses')}';"
      else
        page.call('show_msg','nameerror',@transaction_status_type.errors.on(:alvalue))
      end
    end
  end

  def edit
    @transaction_status_type = TransactionStatus.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @transaction_status_type = TransactionStatus.find(params[:id])
    lvalue = params[:transaction_status][:lvalue].blank? ? params[:transaction_status][:alvalue] : params[:transaction_status][:lvalue]
    @transaction_status_type.attributes = params[:transaction_status].merge(:lvalue =>lvalue)
    if @transaction_status_type.valid? && @transaction_status_type.errors.empty?
      @transaction_status_type.save
    end

    respond_to do |format|
      format.js {
        render :update do |page|
        unless !@transaction_status_type.errors.empty?
          active_deactive = find_model_class_data('transaction_statuses')
          page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'transaction_statuses', :header=>"Transaction", :modelclass=> 'transaction_statuses'})
          page<< 'tb_remove();'
          page<<"window.location.href='#{manage_company_utilities_path('transaction_statuses')}';"
          flash[:notice] = "Transaction Status was successfully updated"
        else
            page.call('show_msg','nameerror',@transaction_status_type.errors.on(:alvalue))
          end
        end
      }
    end
  end

  def show
    @transaction_status_type = @company.transaction_statuses.find_only_deleted(params[:id])
    unless @transaction_status_type.blank?
      @transaction_status_type.update_attribute(:deleted_at, nil)
      set_sequence_for_lookups(@company.transaction_statuses)
    end
    respond_to do |format|
      flash[:notice] = "Transaction Status '#{@transaction_status_type.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('transaction_statuses')) }
      format.xml  { head :ok }
    end
  end
end
