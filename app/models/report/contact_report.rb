class ContactReport
  include Report
  attr_accessor :params,:employee_user,:company,:fav_id,:data,:group_by_hash,:group_by,:query_string,:start_date,:end_date,:column,:total_records,:order,:table_header,:locale
  #param ContactReport.new(params,18,2,[:assignee]])
  GROUP_BY = %w(rating owner contactstage source account act_owner)
  def initialize(params,employee_user_id,company_id,include_options=nil,order_options=nil)
    @params = params
    @employee_user = get_employee(employee_user_id)
    @company = 	 get_company(company_id)
    @group_by_hash =  HashWithIndifferentAccess.new
    @query_string = ""
    @group_by = ""
    @include = include_options
    @order = order_options || "coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') asc"
    @table_header = []
    @locale = @params["locale"]
    manage_group_by_clause
    manage_date_range
  end

  # This method generate group_by clause
  #Group by has
  # "owner","assigned_to_user_id","User","name"
  # "stage","contact_stage_id","ContactStage","alvalue"
  # "account","account_id","Account","name"
  # "rating","rating","Contact","rating"
  # "source","source","CompanySource","alvalue"

  def manage_group_by_clause
    @group_by =  @params["report"]["summarize_by"] if @params["report"] && @params["report"]["summarize_by"] && GROUP_BY.include?(@params["report"]["summarize_by"])
  end

  # manages date range
  # if date is selected i.e checkbox is true then set start_date and end_date parameter
  # if params contaion duration
  # then 1 indicates 1week,2 for 1 month, 3 for 3 month,4 for 6 month and if it is range then set date start and end date
  def manage_date_range
    @start_date,@end_date = @params["date_start"], @params["date_end"] if @params["date_selected"] == "true"  || @params["date_selected"] == "1"
    if @params["report"] && @params["report"]["duration"]
      date_range_type = @params["report"]["duration"]
      current_time =Time.zone.now

      @end_date = current_time
      # for last 1 week
      if date_range_type == "1"
        @start_date = current_time - 7.days
        # for last 1.month
      elsif 	date_range_type == "2"
        @start_date = current_time - 1.month
        # for last 3 month
      elsif date_range_type == "3"
        @start_date = current_time - 3.month
        # for last 6 month
      elsif date_range_type == "4"
        @start_date = current_time - 6.month
      elsif date_range_type == "range"
        @start_date,@end_date = @params["date_start"], @params["date_end"]
      end
    end
    # if start date is present and end date is absent then set end date is start date
    @end_date = @start_date if @start_date.present? && @end_date.blank?

  end


  def build_query_string
    @query_string << build_conditions_for_my_or_all(@employee_user.id,@company.id,@params["get_records"])
    @query_string << " and " << build_condition_for_date(@start_date, @end_date) if @start_date.present?
  end

  def reset_query_string
    @query_string = ""
  end

  def current_contact_data
    build_query_string
    data = render_data
    @total_records = data.size
    reset_query_string
   
    if @group_by == "rating"
      @data = data.group_by(& :rating)
      @table_headers = ["#{t(:label_contact)}","#{t(:label_Account)}",t(:label_phone),t(:label_email),t(:label_source),t(:label_rating),t(:text_created),t(:label_owner)]
    elsif @group_by == "owner"
      @data = data.group_by(& :assigned_to_employee_user_id)
      @table_headers=["#{t(:label_contact)}","#{t(:label_Account)}",t(:label_phone),t(:label_email),t(:label_source),t(:label_rating),t(:text_created),t(:label_stage)]
    elsif @group_by == "source"
      @data = data.group_by(& :source)
      @table_headers= ["#{t(:label_contact)}","#{t(:label_Account)}","Phone",  "Email",   "Rating",  "Created","Owner",  "Stage"]
    elsif @group_by == "contactstage"
      @data = data.group_by(& :contact_stage_id)
      @table_headers= ["#{t(:label_contact)}","#{t(:label_Account)}",t(:label_phone),t(:label_email),t(:label_source),t(:label_rating),t(:text_created),t(:label_owner)]
    elsif @group_by == "account"
      @data = data.group_by {|o| o.accounts.collect(& :id)}
      @table_headers=["#{t(:label_contact)}",t(:label_phone),t(:label_email),t(:label_source),t(:label_rating),t(:text_created),t(:label_owner),t(:label_stage)]
    end

  end

  def recent_contact_data
    build_query_string
    @data =render_data
    @total_records = @data.size
  end

  def render_data
    Contact.find(:all,:include=>@include ,:conditions=>@query_string,:order=>@order)
  end

end
