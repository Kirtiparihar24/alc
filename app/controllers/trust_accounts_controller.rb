class TrustAccountsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :is_not_lawfirm_admin, :except => [:client_view, :index, :show, :search, :matters, :advanced_filter, :client_specific]
  before_filter :company_and_companies
  load_and_authorize_resource
  layout :trust_account_layout

  def index
    @trust_accounts = []
    if @company
      @trust_accounts = TrustAccount.all(:conditions => ["trust_accounts.company_id = ?", @company.id], :include => :trust_type)
    end
    if request.xhr?
      render :update do |page|
        page.replace_html("add_new_trust_account", :text => "<a href='#{new_trust_account_path}'>Add new</a>")
        page.replace_html("trust_account_partial", :partial => "trust_accounts", :collection => @trust_accounts, :as => :trust_account)
      end
    end
  end

  def new
    @trust_account = TrustAccount.new
  end

  def show
    @trust_account = TrustAccount.find(params[:id], :conditions => ["trust_accounts.company_id = ?", @company.id])
  end
  
  def create
    @trust_account = @company.trust_accounts.new(params[:trust_account])
    if (@trust_account.valid? && @trust_account.errors.empty?)
      @trust_account.created_by = current_user.id
      @trust_account.save!
      @trust_accounts = @company.trust_accounts
      render_the_action
    else
      @matters = Matter.all(:conditions => ["company_id = ? AND contact_id = ?", @company.id, @trust_account.account.primary_contact_id]) if params[:is_matter_list] == 'yes'
      render_the_action('new')
    end
  end

  def edit
    @trust_account = TrustAccount.find(params[:id], :conditions => ["company_id = ?", @company.id])
  end

  def update
    @trust_account = TrustAccount.find(params[:id], :conditions => ["company_id = ?", @company.id])
    @trust_account.attributes = params[:trust_account]
    if (@trust_account.valid? && @trust_account.errors.empty?)
      @trust_account.updated_by = current_user.id
      @trust_account.save!
      @trust_accounts = @company.trust_accounts
      render_the_action
    else
      @matters = Matter.all(:conditions => ["company_id = ? AND contact_id = ?", @company.id, @trust_account.account.primary_contact_id]) if params[:is_matter_list] == 'yes'
      render_the_action('edit')
    end
  end

  def search
    if(params[:q])
      search_result = params[:searchable_type].classify.constantize.search(params[:q], :with => {:company_id => @company.id}, :star => true)
    else
      search_result = params[:searchable_type].classify.constantize.all(:conditions => ["company_id = ?", @company.id])
    end
    render_the_action('no_action', 'auto_complete', {:search_results => search_result})
  end

  def matters
    account = Account.find(params[:account_id])
    @matters = Matter.all(:conditions => ["company_id = ? AND contact_id = ?", @company.id, account.primary_contact_id])
  end

  def client_view
    key = "client_view_fragment_cache_#{current_company.id}"
    expire_fragment(key) unless @client_transaction_hash = read_fragment(key, :expires_in => 1.day) || write_fragment(key, TrustAccountTransaction.client_trust_view(@company.id))
  end

  def client_specific
    @trust_account = TrustAccount.find(params[:trust_account_id], :conditions => ["trust_accounts.company_id = ?", @company.id])
    @client = Account.find(params[:client_id], :conditions => ["company_id = ?", @company.id], :select => "id, name")
    @trust_account_transactions = TrustAccountTransaction.all(:conditions => ["trust_account_id = ? AND account_id = ? AND company_id = ?", params[:trust_account_id], params[:client_id], @company.id])
  end

  def advanced_filter
    trust_account = TrustAccount.find(params[:id], :select => "id,company_id", :conditions=>["trust_accounts.company_id = ?",@company.id])
    view_type = params[:client] ? 'client_specific' : ''
    unless request.post?
      @trust_account_banks = TrustAccount.all(:select => "id,name", :conditions=>["company_id = ?",@company.id]) if params[:client]
      filter_datas(trust_account)
      render :update do |page|
         page.replace_html "advanced_filter", :partial => "advanced_filter"
         page << "jQuery('.display_none').show();"
      end
    else
      trust_account_transactions = TrustAccountTransaction.filtered_result(trust_account,params)
        render :update do |page|
         page.replace_html "trust_account_transactions", :partial => "trust_account_transactions", :collection => trust_account_transactions, :as => :transaction, :locals => {:view_type => view_type}
        end
    end
  end

  def company_and_companies
    if current_user.role?:livia_admin
      @companies = Company.find(:all,:conditions => ['id NOT IN (?)', current_user.company_id], :order => "name")
      company_id = params[:company_id] ? params[:company_id] : session[:company_id]
      session[:company_id] = company_id
      @company = Company.find_by_id(company_id)
    else
      @company = current_company
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

  def trust_account_layout
    is_lawfirmadmin || is_liviaadmin ? 'admin' : 'full_screen'
  end

  def is_not_lawfirm_admin
    if (!is_lawfirmadmin && !is_liviaadmin)
      respond_to do |format|
        format.html { redirect_back_or_default("/")}
        format.js   { render(:update) { |page| page.redirect_to('/') } }
        format.xml  { render :text => flash[:warning], :status => :not_found }
      end
    end
  end

  #This method to find out the datas for list box in GUI for search
  def filter_datas(trust_account)
    @accounts = Account.all(:select => 'id, name', :conditions => "id IN (SELECT account_id FROM trust_account_transactions WHERE trust_account_id=#{trust_account.id})")
    @matters = Matter.all(:select => 'id, name', :conditions => "id IN (SELECT matter_id FROM trust_account_transactions WHERE trust_account_id=#{trust_account.id})")
  end
end
