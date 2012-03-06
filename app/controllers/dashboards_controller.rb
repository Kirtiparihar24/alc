require "dashboard"
class DashboardsController < ApplicationController
	layout 'left_with_tabs'	
	before_filter :authenticate_user!
  before_filter :get_base_data
	include FusionChartsHelper
  include DashboardHelper

	def index
		@category_checked = "checked"
		@data,@selected_charts, @checked_charts, @cheacked = [], {}, {}, []
		@fav_dashboard = CompanyDashboard.all(:conditions => ["(company_id = ? AND employee_user_id=? AND is_favorite=#{true})", @company.id, @emp_user_id])
		charts_info = DashboardChart.all(:order => 'id')
		manage_dashboard = CompanyDashboard.all(:conditions => ["(company_id =? AND employee_user_id = ?)", @company.id, @emp_user_id])
		charts_info.each do |item|
			@checked_list = manage_dashboard.detect{ |obj| obj.dashboard_chart_id == item.id  and obj.is_favorite != true }
			@hidden_checked = @hidden_checked ? @hidden_checked + @checked_list.dashboard_chart_id.to_s + "," :  @checked_list.dashboard_chart_id.to_s + "," if @checked_list
			@managed_checked = @managed_checked ?  @managed_checked + @checked_list.id.to_s + "," :  @checked_list.id.to_s + "," if @checked_list
		end
		if manage_dashboard!=[]
			manage_dashboard.each do |obj|
				if obj.show_on_home_page == true
					@cheacked << obj.dashboard_chart_id
					@checked_charts[obj.dashboard_chart.template_name]=obj.id
				end
			end
		else
			charts_info.each do |obj|
				if obj.default_on_home_page == true
					@cheacked << obj.id
				end
			end
		end
		charts_info.each do |obj|
			if @cheacked.include?(obj.id)
				@selected_charts[obj.template_name] =['checked',obj.id]
			else
				@selected_charts[obj.template_name]=['',obj.id]
			end
		end
	end

	def all_category
		@pagenumber=157
    @selected_charts, @checked_charts =  {}, {}
    @hidden_checked, @managed_checked = '', ''
		#@category_checked="checked"
		@fav_dashboards = CompanyDashboard.current_company_and_current_employee(@company.id, @emp_user_id).favorite#all(:conditions => ["(company_id =? AND employee_user_id=? AND is_favorite=#{true})", @company.id, @emp_user_id], :include => :dashboard_chart)
		@selected_dashboards = CompanyDashboard.current_company_and_current_employee(@company.id, @emp_user_id).show_on_home_page#all(:conditions => ["(company_id =? AND employee_user_id = ? AND show_on_home_page=#{true})", @company.id, @emp_user_id], :include => :dashboard_chart)
    CompanyDashboard.manage_dashboard(@company.id, @emp_user_id, @selected_charts, @checked_charts, @hidden_checked, @managed_checked)
		add_breadcrumb "Dashboard",{:controller => :dashboards , :action => :all_category, }
	end

	def dashboard_new
		@data=[]
	end

	def dashboard_show
		@dashboard=Dashboard.new(params, @emp_user_id, @company.id)
		@pagenumber=107
		render :layout => false
	end

	def manage_dashboard
		@dashboard=Dashboard.new(params, @emp_user_id, @company.id)
	end
  
  def render_dashboard_xml_file
		@dashboard=Dashboard.new(params, @emp_user_id, @company.id)
		@dashboard.render_chart_data
		render(:file => "/xml_builder/#{@dashboard.dashboard.xml_builder_name}")
	end

  #This is used to display the dashbords in facebox
  def display_dashboard_in_facebox
  end

  def fav_on_facebox
    render :partial => "dashboards/create_fav"
  end

  def create_fav
		@dashboard = Dashboard.new(params,@emp_user_id,@company.id)
		@dashboard.build_parameters_for_favourite_dashboard
		company_dashboard= CompanyDashboard.create(:company_id=>@company.id,:employee_user_id=>@emp_user_id,:parameters=>@dashboard.parameters,:is_favorite=>true,:favorite_title=>params[:favorite_title],:dashboard_chart_id=>params[:dashboard_chart_id],:thresholds=>@dashboard.threshold)
		@fav_dashboard = CompanyDashboard.all(:conditions => ["(company_id =? AND employee_user_id = ? AND is_favorite=#{true})", @company.id, @emp_user_id])
		flash[:notice] = "Dashboard is added to favorites."
		render "dashboard_partials/create_favourite.js"
	end

  def build_favourite_parameter
	end

  def fav_dashboard
    @pagenumber = 11
		@fav_charts,@data=[],[]
		@fav_dashboard = CompanyDashboard.all(:conditions => ["(company_id = ? AND employee_user_id=? AND is_favorite=#{true})", @company.id, @emp_user_id])
		@dashboard = Dashboard.new({:fav_id => @fav_dashboard[0].id, :chart_name => @fav_dashboard[0].dashboard_chart.template_name},@emp_user_id, @company.id) unless @fav_dashboard.empty?
		render :layout => false
	end

  def fav_destroy
    CompanyDashboard.destroy(params[:fav_id])
    redirect_to '/dashboards/all_category'
  end

  def show_favs
		@data=[]
		show_favs=CompanyDashboard.find(params[:id])
		params[:fav_id] = show_favs.id if show_favs.is_favorite == true
		@dashboard = Dashboard.new({:fav_id=>show_favs.id,:chart_name=>show_favs.dashboard_chart.template_name},@emp_user_id, @company.id) unless show_favs.blank?
		render :layout => false
	end
  
  def title_change
		@data=[]
		@mag_name = CompanyDashboard.find(params[:id])
	end

  def update_favorite_title
		@data=[]
		@mag_name=CompanyDashboard.find(params[:id])
		@mag_name.favorite_title=params[:edit_title]
		@mag_name.save
		@fav_charts=[]
		@fav_dashboard = CompanyDashboard.all(:conditions => ["(company_id = ? AND employee_user_id = ? AND is_favorite=#{true})", @company.id, @emp_user_id])
		params[:fav_id] = @mag_name.id if @mag_name.is_favorite == true
		@data << self.send(@mag_name.dashboard_chart.template_name)
		render "dashboard_partials/create_favourite.js"
	end

  def mange_dashboards_on_homepage
		# Temporary Fix for https
		actual_root = root_url
		unless actual_root.include?('localhost')
			actual_root.gsub!('http', 'https') if actual_root.include?('http:')
		end
		CompanyDashboard.update_all("show_on_home_page = false",["company_id =? and employee_user_id=? ", @company.id, @emp_user_id])
		chartoids,moids =[],[]
		if params[:charts]
			chartoids = params[:charts].keys.collect {|obj| obj.to_i}
			moids = (params[:charts].values.collect {|obj| obj.to_i if obj != "" }).compact
		end
		if chartoids.length < 3 and params[:chartsfav]
			chartoids = params[:chartsfav].keys.collect {|obj| obj.to_i} + chartoids
			moids = (params[:chartsfav].values.collect {|obj| obj.to_i if obj != "" }).compact + moids
		end
		if params[:managed_checked] && params[:managed_checked] != ''
			hidden_values=params[:managed_checked].split(',')
			oids = hidden_values - moids
			mcol = CompanyDashboard.find(oids)
			mcol.each do |obj|
				obj.show_on_home_page = false
				obj.save!
			end
		end
		col = CompanyDashboard.find(moids)
		if chartoids.length == col.length
			col.each do |obj|
				obj.show_on_home_page = true
				obj.save!
			end
		elsif not col.length == 0
			col.each do |obj|
				chartoids = chartoids - [obj.dashboard_chart_id]
				obj.show_on_home_page = true
				obj.save!
			end
			if chartoids != []
				chartoids.each do |oid|
					exist_manage_dashboard = CompanyDashboard.find_by_dashboard_chart_id oid
					obj =  exist_manage_dashboard ? exist_manage_dashboard : CompanyDashboard.new
					obj.employee_user_id = @emp_user_id
					obj.company_id = @company.id
					obj.dashboard_chart_id = oid
					obj.show_on_home_page = true
					obj.save!
				end
			end
		else
			chartoids.each do |oid|
				exist_manage_dashboard = CompanyDashboard.find_by_dashboard_chart_id oid
				obj =  exist_manage_dashboard ? exist_manage_dashboard : CompanyDashboard.new
				obj.employee_user_id = @emp_user_id
				obj.company_id = @company.id
				obj.dashboard_chart_id = oid
				obj.show_on_home_page = true
				obj.save!
			end
		end
		if current_user.role?('lawyer')
			redirect_to actual_root +  'physical/clientservices/home'
		else
			redirect_to '/dashboards/all_category'
		end
	end

  def get_base_data
    @company  ||= current_company
    @emp_user_id ||= get_employee_user_id
    add_breadcrumb t(:text_menu_rnd), "/rpt_contacts/current_contact"
  end

end
