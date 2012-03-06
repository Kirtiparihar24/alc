class Company::ExpenseTypesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('expense_types')",:only=>:index

  layout "admin"

  def index
  end
  
  def new
    @expense_type = @company.expense_types.new
    render :layout=>false
  end

  def create
    expense_types = @company.expense_types
    expense_typescount = expense_types.count
    if expense_typescount > 0
      params[:expense_type][:sequence] = expense_typescount+1
    end
    @expense_type = Physical::Timeandexpenses::ExpenseType.new(params[:expense_type].merge(:lvalue=>params[:expense_type][:alvalue]))
    @expense_type.valid?
    if  @expense_type.errors.empty?
      @company.expense_types << @expense_type      
    end
    render :update do |page|
      unless !@expense_type.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice', "Expense Type was successfully created")
        page<<"window.location.href='#{manage_company_utilities_path('expense_types',:linkage=>"time_expenses")}';"
      else
        page.call('show_msg','nameerror',@expense_type.errors.on(:alvalue))
      end
    end
  end

  def edit
    @expense_type = Physical::Timeandexpenses::ExpenseType.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @expense_type = Physical::Timeandexpenses::ExpenseType.find(params[:id])
    @expense_type.attributes = params[:expense_type].merge(:lvalue=>params[:expense_type][:alvalue])
    @expense_type.valid?
    if @expense_type.errors.empty?
      @expense_type.save
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@expense_type.errors.empty?
            active_deactive = find_model_class_data('expense_types')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'expense_types', :header=>"Expense Type", :modelclass=> 'expense_types',:linkage=>"time_expenses"})
            page<< 'tb_remove();'
            page.call('common_flash_message_name_notice', "Expense Type was successfully updated")
            page<<"window.location.href='#{manage_company_utilities_path('expense_types',:linkage=>"time_expenses")}';"
          else
            page.call('show_msg','nameerror',@expense_type.errors.on(:alvalue))
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @expense_type = @company.expense_types.find_only_deleted(params[:id])
    unless @expense_type.blank?
      @expense_type.update_attribute(:deleted_at, nil)
      set_sequence_for_lookups(@company.expense_types)
    end
    respond_to do |format|
      flash[:notice] = "Activity Type '#{@expense_type.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('expense_types',:linkage=>"time_expenses")) }
      format.xml  { head :ok }
    end
  end
  
end
