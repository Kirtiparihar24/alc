class Dashboard

	attr_accessor :title,:caption,:dates,:sub_caption,:chart_id,:chart,:dashboard,:dashboard_template_name,:duration,:from_date,:to_date,:employee_user_id,:company_id,:data,:company,:user,:parameters,:today_task,:overdue_task,:open_task,:threshold,:params,:fav_id

	def initialize(parameter, employee_user_id=nil, company_id=nil)
		@params = parameter
		@dashboard= get_dashboard
		@fav_id = parameter[:fav_id]
		@employee_user_id = employee_user_id
		@company_id = company_id
		@dates = []
		@dates[1] = ""
		@dates[0] = ""
		@chart= get_employee_chart
		@threshold = @dashboard.defult_thresholds if @dashboard && @dashboard.defult_thresholds
		@title=""
		@caption=""
		@user = get_employee_user
		@company = get_company
		@data = []
		@locale = parameter[:locale] || "us"
		set_chart_details
	end

  # find out dashboard chart by chart_name or by passing dashboard_chart_id in params
	def get_dashboard
		if @params[:chart_name].present?
			DashboardChart.find_by_template_name(@params[:chart_name]) rescue nil
		else
			DashboardChart.find(@params[:dashboard_chart_id]) rescue nil
		end
	end

  # find out favorite chart of employee @fav_id set when in params[:fav_id] is passed
	def get_employee_chart
		@chart = CompanyDashboard.find(@fav_id) rescue nil
	end

  # find out employee user
	def get_employee_user
		User.find(@employee_user_id) rescue nil
	end

  # find out company
	def get_company
		Company.find(@company_id) rescue nil
	end

  # Set parameters which are present in database
  # this parameters are passed form params as it is
  # e.g some graph has to_date,from_date,duration
  # this parameters is passed from params as :to_date=>"some date",:from_date=>"some date"
  # there is no compulsion in parameter passing
  # this will aso set threshold value if threshold value is passed
  # after this duration is set it means date is set based on parameter
  # if chart is favorite then parameter is taken form favorite

	def set_chart_details
		@parameters = HashWithIndifferentAccess.new(@dashboard.parameters)
		if @params.present?
			@parameters.each do |k,v|
				@parameters[k] = @params[k] if @params[k].present? rescue ""
			end
			if @threshold.present?
				@threshold.each do |k,v|
					@threshold[k] = @params['threshold'][k] if  @params['threshold'][k].present? rescue @threshold[k]
				end
			end
		end
		if @chart.present? && @chart.parameters.present?
			@parameters = @chart.parameters
			@threshold= @chart.thresholds if @chart.thresholds
			@title = @chart.favorite_title if @chart.favorite_title
		end
		@sub_caption = duration_dates(@parameters,@dates)
	end

  # this sets parameter in manage_dashboard when filter is changed
  # we need to append all the required parameter to make persistent request
	def http_parameter
		x= ""
		@parameters.each { |k,v| x << "#{k}=#{v}&" if v.present? } if @parameters.present?
		@threshold.each{ |k,v| x  << "threshold[#{k}]=#{v}&" if v.present?} if @threshold.present?
		x << "fav_id=#{@fav_id}&"if @fav_id.present?
		return x
	end

  # this will set parameter for favorite chart
	def http_parameter_in_favourite_for_params
		x= ""
		@parameters.each { |k,v| x << "#{k}=#{v}&" if v.present? } if @parameters.present?
		x
	end

  # this will set threshold parameter for favorite chart
	def http_parameter_in_favourite_for_thresholds
		x= ""
		@threshold.each{ |k,v| x  << "threshold[#{k}]=#{v}&" if v.present?} if @threshold.present?
		x
	end

  # when parameters comes from favorite it joins with & so
  # we need to split by & do as per our need
  # eg. @params[:parameters]	is like"probability=>40&"

	def build_parameters_for_favourite_dashboard
		flatten_params,splitted_params= {},[]
		splitted_params = @params[:parameters].split("&").collect {|p| p.split("=")}
		# hack for matter task
		# for matter task if parameter is not passed then considered as
		# selected all

		if @dashboard.template_name == "matter_task_chart_graph" && splitted_params.flatten.uniq.length == 1 && splitted_params.flatten.uniq[0].blank?
			flatten_params = {"today"=>"today","overdue"=>"overdue","upcoming"=>"upcoming"}
		else
			flatten_params = Hash[*splitted_params.collect { |v| [v[0], v[1]] }.flatten]
		end
		@parameters.each do |k,v|
			@parameters[k] =  flatten_params[k] if flatten_params[k].present? rescue ""
		end
		flatten_params,splitted_params= {},[]
		splitted_params = @params[:thresholds].split("&").collect {|p| p.split("=")}
		flatten_params = Hash[*flatten_params.collect { |v| [v[0], v[1]] }.flatten]
		@threshold = flatten_params
	end

  #setting duration and sub captions
	def duration_dates(parameters, dates)
		today=Time.zone.now.to_date
		if parameters[:duration] == "1months"
			duration_date_for_month(1)
		elsif parameters[:duration] == "2months"
			duration_date_for_month(2)
		elsif parameters[:duration] == "3months"
			duration_date_for_month(3)
		elsif parameters[:duration] == "6months"
			duration_date_for_month(6)
		elsif parameters[:duration] == "9months"
			duration_date_for_month(9)
		elsif parameters[:duration] == "12months"
			duration_date_for_month(12)
		elsif parameters[:duration] == "2weeks"
			duration_date_for_week(2)
		elsif parameters[:duration] == "4weeks"
			duration_date_for_week(4)
		elsif parameters[:duration] == "current_week"
			@dates[0]=today.at_beginning_of_week
			@dates[1]=today.end_of_week
			@sub_caption = "( Current Week )"
		elsif parameters[:duration] == 'start_of_year'
			@dates[0]=today.at_beginning_of_year
			@dates[1]=today.end_of_month
			@sub_caption = "( From Start Of Year)"
		elsif parameters[:duration] == '5'
			@dates[0]=parameters["created_date"] || parameters["from_date"] if parameters["created_date"].present? || parameters["from_date"].present?
			@dates[1]=parameters["to_date"] if parameters["to_date"].present?
			@sub_caption="( #{@dates[0]} - #{@dates[1]})"
		end
	end

	def duration_date_for_month(month)
		today=Time.zone.now.to_date
		@dates[0]=today.beginning_of_month-(month-1).month
		@dates[1]=today.end_of_month
		@sub_caption = "( Last #{month} Months)"
	end

	def duration_date_for_week(week)
		today=Time.zone.now.to_date
		@dates[0]=today.beginning_of_week-(week-1).week
		@dates[1]=today.end_of_week
		@sub_caption = "( Last #{week} Weeks )"
	end

	def livia_date(d)
		d.to_time.strftime("%m/%d/%Y") rescue ''
	end

  # this will actually set chart data
  # by taking template_name and appending_data method to it
  # e.g contact_graph has method contact_graph_data

	def render_chart_data
		self.send(self.dashboard.template_name+"_data")
	end

  # setting up chart title
	def set_title(title_string)
		@title= @data[0] && @data[0][:title].present? ? @data[0][:title] : title_string
	end

  # setting up sub caption
	def set_sub_caption
		@sub_caption = @data[0][:sub_cap] if @data[0] && @data[0][:sub_cap]
	end

  # Start Of CRM GRAPH
  # This will returns the contact brake up stage wise
	def contact_graph_data
		total_data= {}
		conditions_hash = {:assign_to => @employee_user_id, :company_id => @company_id}
		conditions_hash = conditions_hash.merge({:date_start => @dates[0],:date_end =>@dates[1]}) if @dates[0]!='' && @dates[1]!=''
		search='company_id=:company_id AND assigned_to_employee_user_id=:assign_to'
		search += " AND created_at Between :date_start AND :date_end" if @dates[0] != '' && @dates[1] != ''
		cont = Contact.all(:conditions => [search,conditions_hash])
		cont.group_by(&:contact_stage_id).each do |label, col|
			if(label !=nil && label !="")
				label = ContactStage.find(label).lvalue
				total_data[label] = col.length
			end
		end
		total_data.each do |k,v|
			@data<<{:contact_name=>k,:contact_length=>v,:conatact_color=>@dashboard.colors[k],:contact_status=>ContactStage.find_by_lvalue_and_company_id(k,@company_id).id,:sub_cap=>@sub_caption,:title=>@title}
		end
		set_title("#{@user.full_name.titleize}'s #{I18n.t(:label_business_contacts)}")
		set_sub_caption
	end

  # This will returns the Opportunities brake up stage wise
	def get_opportunities_graph_data
		second_val=[]
		second_val = @company.opportunity_stage_types.collect do |obj|
			obj.id if ["Prospecting","Negotiation","Proposal","Final Review"].include?(obj.lvalue)
		end
		conditions_hash = {:assign_to => @employee_user_id , :company_id =>@company_id,:stage=>second_val.compact}
		search='company_id=:company_id AND assigned_to_employee_user_id=:assign_to AND stage IN (:stage)'
		search += " and probability #{@parameters[:probability]}"  if (@parameters[:probability] && !@parameters[:probability].blank?)
		col = Opportunity.all(:conditions => [search,conditions_hash], :order => 'stage DESC')

		amount =0
		col.group_by(&:stage).each do |label, cols|
			label = CompanyLookup.find(label).lvalue

			cols.each do |opp|
				amount +=  opp.amount if opp.amount
			end
			cols.length
			@data<<{:opp_name=>label,:opp_length=>cols.length,:opp_value=>amount,:opp_color=>@dashboard.colors[label],:title=>@title}
			amount = 0
		end
		set_title("#{@user.full_name.titleize}'s #{I18n.t(:text_opportunities)}-Pipline}")
		set_sub_caption
	end

  #This will gives the open opportunities which has the probability
	def get_open_opportunities_data
		second_val = @company.opportunity_stage_types.collect do |obj|
			obj.id if ["Prospecting","Negotiation","Proposal","Final Review"].include?(obj.lvalue)
		end
		conditions_hash={:assign_to => @employee_user_id, :company_id =>@company_id,:date=>Time.zone.now.to_date ,:stage=>second_val.compact}
		search='company_id=:company_id AND assigned_to_employee_user_id=:assign_to  AND stage IN (:stage) AND probability is not null'
		search += " and probability  #{@parameters[:probability]}" if @parameters[:probability].present? && @parameters[:probability] == "all"
		open_opp = Opportunity.all(:conditions => [search, conditions_hash])
		opp = open_opp.group_by{|obj| obj.probability}
		opp.sort.each do |key,value|
			amount = 0
			value.each do |obj|
				amount += obj.amount if obj.amount
			end
			@data << {:probability => key, :amount => amount,:title => @title}
		end
		set_title("#{@user.full_name.titleize}'s Open #{I18n.t(:text_opportunities,:locale=>@locale)} - Potential Income")
		set_sub_caption
	end

  #This will gives the closed opportunities
	def get_closed_opportunities_data	
		second_val = @company.opportunity_stage_types.collect do |obj|
			obj.id if ["Closed/Won","Closed/Lost"].include?(obj.lvalue)
		end
		conditions_hash = {:assign_to => @employee_user_id ,:stage=>second_val.compact, :company_id => @company_id }
		conditions_hash = conditions_hash.merge({:date_start => @dates[0],:date_end =>@dates[1]}) if @dates[0]!='' && @dates[1]!=''
		search='company_id=:company_id AND assigned_to_employee_user_id=:assign_to AND stage IN (:stage)'
		search += " AND closed_on Between :date_start AND :date_end" if @dates[0]!='' && @dates[1]!=''

		close_opp = Opportunity.all(:conditions => [search,conditions_hash], :order => "closed_on ASC")
		col = close_opp.group_by{|obj| obj.closed_on.nil? ? Time.zone.now.beginning_of_month : obj.closed_on.beginning_of_month }
		col.each do |label,val|
			opp_close_count,opp_amount=0,0
			val.each do |obj|
				opp_close_count += 1
				opp_amount += obj.amount if obj.amount
			end
			@data << {:opp_date=>label.strftime("%b %y"),:opp_count=>opp_close_count,:opp_amount=>opp_amount,:sub_cap=>@sub_caption,:title=>@title}
		end
		set_title("#{@user.full_name.titleize}'s Closed #{I18n.t(:text_opportunities,:locale=>@locale)}")
		set_sub_caption
	end

  #This is will show the top 5 opportunities
	def top_opportunities_data
		name_amount = {}

		second_val = @company.opportunity_stage_types.collect do |obj|
			obj.id if ["Prospecting","Negotiation","Proposal","Final Review"].include?(obj.lvalue)
		end
		col = Opportunity.all(:conditions => ["(company_id =? AND assigned_to_employee_user_id=? AND stage IN (?))", @company_id, @employee_user_id, second_val.compact], :order => 'stage DESC')
		col[0..8].each do |obj|
			if obj.amount
				amounts = obj.amount.to_i
				names = obj.name
				name_amount = name_amount.merge({names=>amounts})
			end
		end
		name_amount=name_amount.sort{|k,v| v[1]<=>k[1]} if !name_amount.empty?
		name_amount.each do |k,v|
			@data << {:name=>k,:amount=>v,:hname=>k}
		end
		set_title("#{@user.full_name.titleize}'s  Key #{I18n.t(:text_opportunities,:locale=>@locale)} to Focus")
		set_sub_caption
	end

  #This will gives the campaign responsiveness
	def get_campaign_responsiveness_data
		conditions_hash = {:assign_to => @employee_user_id , :company_id => @company_id}
		conditions_hash = conditions_hash.merge({:date_start => @dates[0],:date_end =>@dates[1]}) if @dates[0]!='' && @dates[1]!=''
		search='company_id=:company_id AND owner_employee_user_id=:assign_to'
		search += " AND created_at Between :date_start AND :date_end" if @dates[0]!='' && @dates[1]!=''
		col = Campaign.all(:include => [:opportunities, :members], :conditions => [search, conditions_hash])
		col.each do|obj|
			clength = obj.members.size
			response = obj.get_response
			olength = obj.opportunities.size
			@data << {:name=>(obj.name).slice(0,10)+'...',:hname=>obj.name,:response=>(clength != 0 and response != 0) ? ((response/clength.to_f) * 100).roundf2(2) : 0,:opps=>(clength != 0 and olength != 0 )? ((olength/clength.to_f) * 100).roundf2(2) : 0,:sub_cap=>@sub_caption,:title=>@title}
		end
		set_title("#{@user.full_name.titleize}'s #{I18n.t(:text_campaign,:locale=>@locale)} Response")
		set_sub_caption
	end

  #This will gives the campaign responsiveness with the value
	def get_campaign_response_value_data
		conditions_hash = {:assign_to => @employee_user_id , :company_id => @company_id }
		conditions_hash = conditions_hash.merge({:date_start => @dates[0],:date_end =>@dates[1]}) if @dates[0]!='' && @dates[1]!=''
		search='company_id=:company_id AND owner_employee_user_id=:assign_to'
		search += " AND created_at Between :date_start AND :date_end" if @dates[0]!='' && @dates[1]!=''
		cmp = Campaign.all(:include => :opportunities, :conditions => [search, conditions_hash])
		cmp.each do |obj|
			revenue = 0
			olength = 0
			clength = obj.contact_length
			opp = obj.opportunities
			olength = opp.size if opp
			opp.each do |obj1|
				revenue = revenue + obj1.amount if obj1.amount
			end

			@data << {:name=>(obj.name).slice(0,10)+'...',:hname=>obj.name,:revenue=>revenue.to_i,:opps=>(clength != 0 and olength != 0 )? ((olength/clength.to_f) * 100).roundf2(2) : 0 ,:sub_cap=>@sub_caption,:title=>@title}
		end
		set_title("#{@user.full_name.titleize}'s #{I18n.t(:text_campaign,:locale=>@locale)} Response - Value")
		set_sub_caption
	end

  #This will show Active and InActive Accounts
	def active_inactive_accounts_data
		@dates[1]= Time.zone.now.to_date
		@dates[0]= @dates[1].years_ago(1)
		conditions_hash = {:assign_to => @employee_user_id , :company_id => @company_id,:start_date=>@dates[0],:end_date=>@dates[1]}
		search = 'company_id=:company_id AND assigned_to_employee_user_id=:assign_to AND created_at Between :start_date AND :end_date'
		col = Account.all(:include => [{:contacts => [:opportunities , :matters]}], :conditions => [search, conditions_hash])
		second_val = @company.opportunity_stage_types.collect do |obj|
			obj.id if ["Prospecting","Negotiation","Proposal","Final Review"].include?(obj.lvalue)
		end
		all_accounts,active = {},0
		col.each do |account|
			account.contacts.each do |contact|
				next unless contact
				o_col = contact.opportunities.select do|opp|
					(livia_date(opp.created_at) >= livia_date(@dates[0]) and livia_date(opp.created_at)<= livia_date(@dates[1])) or (second_val.include?(opp.stage)) or (livia_date(opp.closed_on) >= livia_date(@dates[1]))
				end
				if o_col.length > 0
					active += 1
					break
				end
				m_col = contact.matters.select do |matter|
					(livia_date(matter.created_at) >= livia_date(@dates[0]) and livia_date(matter.created_at) <= livia_date(@dates[1])) or (matter.matter_status.lvalue == 'Open') or (livia_date(matter.closed_on) >= livia_date(@dates[1]))
				end
				if m_col.length > 0
					active += 1
					break
				end
			end
		end
		all_accounts = {'Active'=>active ,'InActive'=>col.length - active}
		all_accounts.each do |k,v|
			@data << {:name=>k,:amount=>v,:conatact_color=>@dashboard.colors[k],:sub_cap=>@sub_caption,:title=>@title}
		end
		set_title("#{@user.full_name.titleize}'s Active and InActive #{I18n.t(:label_accounts,:locale=>@locale)}")
		set_sub_caption
	end

  # Operational Efficiency Graph
  # This will returns the Time billing, month wise from the last one year
	def billing_amount_graph_data
		@dates[0]=Time.zone.now.to_date.last_year.beginning_of_month
		@dates[1]=Time.zone.now.to_date.beginning_of_month
		conditions_hash = {:assign_to => @employee_user_id , :company_id => @company_id}
		conditions_hash = conditions_hash.merge({:date_start => @dates[0],:date_end =>@dates[1]}) if @dates[0]!='' && @dates[1]!=''
		search='company_id=:company_id AND employee_user_id=:assign_to'
		search += " AND time_entry_date Between :date_start AND :date_end" if @dates[0]!='' && @dates[1]!=''
		col = Physical::Timeandexpenses::TimeEntry.all(:conditions => [search, conditions_hash], :include => [:performer])
		col = col.group_by{|obj| obj.time_entry_date.beginning_of_month}
		col.each do |label,gcol|
			t_hours,famount = 0,0
			gcol.each do|obj|
				key = obj.performer.try(:full_name).try(:titleize) unless key
				t_hours += obj.actual_duration
				famount += obj.final_billed_amount
			end
			@data << {:billing_amount_date=>label.strftime("%b %y"),:billing_amount=>famount,:bill_date=>label,:partial_name=>'billing_amount.builder',:chart_type=>'FCF_Area2D.swf',:template=>'billing_amount_graph',:upper_thresholds=>@threshold["'upper_threshold'"],:lower_thresholds=>@threshold["'lower_threshold'"],:sub_cap=>@sub_caption,:title=>@title}
		end
		@data= @data.sort_by do |hash|
			hash[:bill_date]
		end
		set_title("#{@user.full_name.titleize}'s  Time Billed")
		set_sub_caption
	end

  #This method used for time accounted
	def time_accounted(duration, method_name)
		conditions_hash = {:assign_to => @employee_user_id , :company_id => @company_id }
		conditions_hash = conditions_hash.merge({:date_start => @dates[0],:date_end =>@dates[1]}) if @dates[0]!='' && @dates[1]!=''
		search = 'company_id=:company_id AND employee_user_id=:assign_to'
		search += ' and is_billable=true' if (duration=="bill_week" || duration=="bill_month")
		search += " and time_entry_date Between :date_start and :date_end" if @dates[0]!='' && @dates[1]!=''
		time_account = Physical::Timeandexpenses::TimeEntry.all(:include => [:matter , :performer, :contact], :conditions => [search,conditions_hash])
		time_account = time_account.group_by{|obj| obj.time_entry_date.beginning_of_week} if (duration=="week" || duration=="bill_week")
		time_account = time_account.group_by{|obj| obj.time_entry_date.beginning_of_month} if (duration=="month" || duration=="bill_month")
		time_account.sort.each do |label,gtotal|
			t_hours = 0
			gtotal.each do|obj|
        actual_duration = @dur_setng_is_one100th ?  one_hundredth_timediffernce(obj.actual_duration) : one_tenth_timediffernce(obj.actual_duration)
				key = obj.performer.try(:full_name).try(:titleize) unless key
				t_hours += actual_duration
			end
			bill_label=label.strftime("%b %y") if (duration=="month" || duration=="bill_month")
			label_amt=bill_label=label.cweek if (duration=="week" || duration=="bill_week")
			label_amt=label if (duration=="month" || duration=="bill_month")
			@data << {:billing_amount_date=>bill_label,:t_hours=>t_hours,:sub_cap=>@sub_caption,:bill_amt=>label_amt,:tget=>@threshold["'target'"],:title=>@title}
		end

		@data= @data.sort_by do |hash|hash[:bill_amt] 	end
	end

  #This will give Time Accounted Week Wise
	def time_accounted_week_wise_data
		duration,method_name="week",'time_accounted_week_wise'
		time_accounted(duration,method_name)
		set_title("#{@user.full_name.titleize}'s Time Accounted -Week wise")
		set_sub_caption
	end

  #This will give Time Accounted Month Wise
	def time_accounted_month_wise_data
		duration,method_name="month",'time_accounted_month_wise'
		time_accounted(duration,method_name)
		set_title("#{@user.full_name.titleize}'s Time Accounted -Month wise")
		set_sub_caption
	end

  #This will give Time Billed Week Wise
	def time_billed_week_wise_data
		duration,method_name="bill_week",'time_billed_week_wise'
		time_accounted(duration,method_name)
		set_title("#{@user.full_name.titleize}'s Time Billed -Week wise")
		set_sub_caption
	end

  #This will give Time Accounted Month Wise
	def time_billed_month_wise_data
		duration,method_name="bill_month",'time_billed_month_wise'
		time_accounted(duration,method_name)
		set_title("#{@user.full_name.titleize}'s Time Billed -Month wise")
		set_sub_caption
	end

	def time_accounted_and_creditable(duration, method_name)
		conditions_hash = {:assign_to => @employee_user_id , :company_id => @company_id }
		conditions_hash = conditions_hash.merge({:date_start => @dates[0],:date_end =>@dates[1]}) if @dates[0]!='' && @dates[1]!=''
		search = 'company_id=:company_id AND employee_user_id=:assign_to'
		search += " and time_entry_date Between :date_start and :date_end" if @dates[0]!='' && @dates[1]!=''
		time_account = Physical::Timeandexpenses::TimeEntry.all(:include => [:matter, :performer, :contact],:conditions => [search, conditions_hash])
		time_account = time_account.group_by{|obj| obj.time_entry_date.beginning_of_week} if duration=="creditable_week"
		time_account = time_account.group_by{|obj| obj.time_entry_date.beginning_of_month} if duration=="creditable_month"
		time_account.sort.each do |label,gtotal|
			t_hours,b_hours = 0,0
			gtotal.each do|obj|
				key = obj.performer.try(:full_name).try(:titleize) unless key
				t_hours += obj.actual_duration
				b_hours += obj.actual_duration if obj.is_billable == true
			end
			bill_label=label.strftime("%b %y") if duration=="creditable_month"
			label_amt=bill_label=label.cweek if duration=="creditable_week"
			label_amt=label if duration=="creditable_month"
			@data<< {:billing_amount_date=>bill_label,:t_hours=>t_hours,:b_hours=>b_hours,:sub_cap=>@sub_caption,:bill_amt=>label_amt,:title=>@title}
		end
		@data=@data.sort_by do |hash|
			hash[:bill_amt]
		end
	end


  #This will give as the Time Accounted Vs Creditable Month wise
	def time_accounted_and_creditable_month_wise_data
		duration,method_name="creditable_month",'time_accounted_and_creditable_month_wise'
		time_accounted_and_creditable(duration,method_name)
		set_title("#{@user.full_name.titleize}'s Time Accounted vs. Creditable - Month wise")
		set_sub_caption
	end

  #This will give as the Time Accounted Vs Creditable Week wise
	def time_accounted_and_creditable_week_wise_data
		duration,method_name="creditable_week",'time_accounted_and_creditable_week_wise'
		time_accounted_and_creditable(duration,method_name)
		set_title("#{@user.full_name.titleize}'s Time Accounted vs. Creditable - Week wise")
		set_sub_caption
	end

  #This will give the Time Billed Vs Final Amount after Discount
	def time_billed_discount_provided_data
		conditions_hash = {:assign_to => @employee_user_id , :company_id => @company_id }
		conditions_hash = conditions_hash.merge({:date_start => @dates[0],:date_end =>@dates[1]}) if @dates[0]!='' && @dates[1]!=''
		search = 'company_id=:company_id AND employee_user_id=:assign_to'
		search += " and time_entry_date Between :date_start and :date_end" if @dates[0]!='' && @dates[1]!=''
		time_account = Physical::Timeandexpenses::TimeEntry.all(:include => [:matter, :performer, :contact], :conditions => [search,conditions_hash])
		time_account = time_account.group_by{|obj| obj.time_entry_date.beginning_of_month}
		time_account.sort.each do |label,gtotal|
			t_amount,f_amount = 0,0
			gtotal.each do|obj|
				key = obj.performer.try(:full_name).try(:titleize) unless key
				t_amount += obj.actual_activity_rate * obj.actual_duration
				f_amount += obj.final_billed_amount
			end
			@data << {:billing_amount_date=>label.strftime("%b %y"),:t_amount=>t_amount,:f_amount=>f_amount,:sub_cap=>@sub_caption,:bill_amt=>label,:title=>@title}
		end
		@data= @data.sort_by do |hash|
			hash[:bill_amt]
		end
		set_title("#{@user.full_name.titleize}'s Time Billed - Discount Provided - Month wise")
	end

  # This will returns the Matter Tasks
	def matter_task_chart_graph_data
		@today_task="today" if @parameters["today"]=="today"
		@overdue_task="overdue" if @parameters["overdue"]=="overdue"
		@open_task="open_task" if @parameters["open_task"]=="open_task"
		matter_tasks_count(@company_id, @employee_user_id, 'todo')
		task_hash = get_task_and_appointment_series(@all_tasks,false,@params)
    #lawyer_view_all_matter_tasks2(current_company.id,get_employee_user_id,'Task')
		@data << {'upcoming'=>task_hash["upcoming"],'today'=>task_hash["today"],'overdue'=>task_hash["overdue"]} unless task_hash.blank?
		@title = "#{@user.full_name.titleize}'s Open #{I18n.t(:text_menu_matter,:locale=>@locale)}  Tasks"
	end

end
