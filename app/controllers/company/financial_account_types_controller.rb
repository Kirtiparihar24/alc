class Company::FinancialAccountTypesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('financial_account_types')",:only=>:index
  layout "admin"
  def index

  end
  def new
    @financial_account_type = @company.financial_account_types.new
    render :layout=>false
  end

  def create
    financial_account_types = @company.financial_account_types
    financial_account_typescount = financial_account_types.count
    if financial_account_typescount > 0
      params[:financial_account_type][:sequence] = financial_account_typescount+1
    end
    lvalue = params[:financial_account_type][:lvalue].blank? ? params[:financial_account_type][:alvalue] : params[:financial_account_type][:lvalue]
    @financial_account_type = TrustType.new(params[:financial_account_type].merge(:lvalue=>lvalue))
    if @financial_account_type.valid? && @financial_account_type.errors.empty?
      @company.financial_account_types << @financial_account_type
      #set_sequence_for_lookups(@company.@company.financial_account_types)
    end
    render :update do |page|
      unless !@financial_account_type.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice',"Trust Type was successfully created")
        page<<"window.location.href='#{manage_company_utilities_path('financial_account_types')}"
      else
        page.call('show_msg','nameerror',@financial_account_type.errors.on(:alvalue))
      end
    end
  end

  def edit
    @financial_account_type = TrustType.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @financial_account_type = TrustType.find(params[:id])
    lvalue = params[:financial_account_type][:lvalue].blank? ? params[:financial_account_type][:alvalue] : params[:financial_account_type][:lvalue]
    @financial_account_type.attributes = params[:financial_account_type]
    if @financial_account_type.valid? && @financial_account_type.errors.empty?
      @financial_account_type.save
    end

    respond_to do |format|
      format.js {
        render :update do |page|
        unless !@financial_account_type.errors.empty?
          active_deactive = find_model_class_data('financial_account_types')
          page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'financial_account_types', :header=>"Stage", :modelclass=> 'financial_account_types',:linkage=>'financial_account_types'})
          page<< 'tb_remove();'
          page<<"window.location.href='#{manage_company_utilities_path('financial_account_types')}';"
          page.call('common_flash_message_name_notice',"Trust Type was successfully updated")
        else
            page.call('show_msg','nameerror',@financial_account_type.errors.on(:alvalue))
          end
        end
      }
    end
  end

  def show
    @financial_account_type = @company.financial_account_types.find_only_deleted(params[:id])
    unless @financial_account_type.blank?
      @financial_account_type.update_attribute(:deleted_at, nil)
      set_sequence_for_lookups(@company.financial_account_types)
    end
    respond_to do |format|
      flash[:notice] = "Trust Type '#{@financial_account_type.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('financial_account_types') + '?linkage=financial_account_types') }
      format.xml  { head :ok }
    end
  end
end
