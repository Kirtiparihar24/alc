# This is new controller added in order to manage SalutationType into company_lookups table Rahul P 5/5/2011
class Company::SalutationTypesController < ApplicationController
  before_filter:authenticate_user!
  before_filter :filter_contacts
  before_filter :get_company
  before_filter :get_salutations ,:only=>[:edit,:update]

  layout "admin"
  
  def index
  end

  def new
    @salutation = @company.salutation_types.new
    render :layout=>false
  end
  
  def create
    salutation_types = @company.salutation_types
    salutation_typescount = salutation_types.count
    if salutation_typescount > 0
      params[:salutation_type][:sequence] = salutation_typescount+1
    end
    salutation = SalutationType.add_salute(@company,params)    
    render :update do |page|
      unless !salutation.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice',"Salutation Type was successfully created")
        page<<"window.location.href='#{manage_company_utilities_path('salutation_types',:linkage=>"contacts")}';"
      else
        page.call('show_msg','nameerror',salutation.errors.on(:alvalue))
      end
    end
  end

  def edit
    render :layout=>false
  end
  
  def update
    respond_to do |format|
      format.js {
        render :update do |page|
          if @salutation.update_attributes(params[:salutation_type].merge(:lvalue=>params[:salutation_type][:alvalue]))
            active_deactive = find_model_class_data('salutation_types')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'salutation_types', :header=>"Salutation Type", :modelclass=> 'salutation_types',:linkage=>"contacts"})
            page<< 'tb_remove();'
            page.call('common_flash_message_name_notice',"Salutation Type was successfully updated")
            page<<"window.location.href='#{manage_company_utilities_path('salutation_types',:linkage=>"contacts")}';"
          else
            page.call('show_msg','nameerror',@salutation.errors.on(:alvalue))
          end
        end
      }
    end
  end
  
  def get_salutations
    @salutation = SalutationType.find(params[:id])
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @salutation_type = @company.salutation_types.find_only_deleted(params[:id])
    unless @salutation_type.blank?
      @salutation_type.update_attribute(:deleted_at, nil)      
      set_sequence_for_lookups(@company.salutation_types)
    end
    respond_to do |format|
      flash[:notice] = "Salutation Type '#{@salutation_type.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('salutation_types',:linkage=>"contacts")) }
      format.xml  { head :ok }
    end
  end
  
end
