class Opportunity < ActiveRecord::Base
  include GeneralFunction
  belongs_to  :user
  belongs_to  :contact
  belongs_to  :company
  belongs_to  :campaign, :counter_cache => true
  belongs_to  :assignee, :class_name => "User", :foreign_key => :assigned_to_employee_user_id
  has_many    :matters
  belongs_to  :opportunity_stage_type , :class_name => "OpportunityStageType", :foreign_key => :stage
  has_many    :activities, :as => :subject, :order => 'created_at DESC'
  has_many :document_homes, :as => :mapable
  attr_accessor :new_record, :follow_up_done, :follow_up_time
  before_validation :format_name
  belongs_to :company_source, :foreign_key =>:source
  before_save :responsible_person_changed
  after_save  :send_mail_to_associates
  before_update :check_status_change

  acts_as_commentable
  acts_as_paranoid
  named_scope :current_company, lambda { |company_id|
    { :conditions=>["company_id = ?",company_id] }
  }
  named_scope :letter_search, lambda { |letter|
    { :conditions => ["UPPER(opportunities.name) like ?",letter + '%']}
  }
  named_scope :get_open_opportunities_in_order, lambda{|contact_ids,company_id,ord|
    {:joins => [:contact,:opportunity_stage_type], :conditions => ["contact_id in (?) and stage not in (?)",contact_ids,get_closed_stage_id(company_id)], :order => ord}
  }
  #strip_attributes!

  validates_presence_of :name ,:message=>:opp_name_msg
  validates_length_of :name, :maximum => 60, :message => "is too long it should not exceed 60 char."
  validates_format_of :name, :with =>/^[A-Za-z\s0-9]*$/,:message=>"Special characters are not allowed."
  validates_presence_of :contact_id, :message=>:opp_contact
  validates_numericality_of  :amount ,:message => :opp_amount, :allow_nil => true
  validates_numericality_of  :probability , :allow_nil => true, :less_than => 101, :greater_than => -1, :message => 'is not a valid percentage (0-100)'
  validates_numericality_of  :estimated_hours, :allow_nil => true, :message => 'is not a valid number'
  validate :validate_closure_date  
  validate :validate_follow_up_date
  
  attr_accessor  :reason,:current_user_name
	before_save :format_name,:validate_source
  before_destroy :change_status#,:add_deactivate_comment
  named_scope :order_by, lambda { |ord| { :order=>ord}}
  default_scope :order => 'opportunities.created_at ASC'
  PROBABILITY = [['10%' , 10], ['20%' , 20], ['30%' , 30], ['40%' , 40], ['50%' , 50], ['60%' , 60], ['70%' , 70], ['80%' , 80], ['90%' , 90], ['100%' , 100]]

  #This method is used in Sphinx search
  define_index do
    set_property :delta => true

    indexes :name, :as => :opportunity_name, :prefixes => true
    indexes contact.first_name, :as => :contact_first_name, :prefixes => true
    indexes contact.middle_name, :as => :contact_middle_name, :prefixes => true
    indexes contact.last_name, :as => :contact_last_name, :prefixes => true
    indexes contact.email, :as => :contact_email, :prefixes => true
    indexes contact.accounts.name, :as => :opportunity_conatct_account_name, :prefixes => true

    has :id, :company_id,:assigned_to_employee_user_id, :stage

    where "opportunities.deleted_at is null and opportunities.stage NOT in (select id from lookups where lookups.type = 'OpportunityStageType' and (lookups.lvalue = 'Closed/Lost' or lookups.lvalue = 'Closed/Won'))"

  end




  sphinx_scope(:current_company) { |company_id|
    {:with => {:company_id => company_id}}
  }

  def confirm_message
    if self.follow_up.nil? || self.follow_up > Time.zone.now.to_date
      "Follow-up is pending for this opportunity.\nDo you still want to deactivate this Opportunity?"
    else
      'Are you sure you want to deactivate this Opportunity?'
    end
  end

  def check_status_change

    if self.stage_changed?
      self.status_updated_on = Time.zone.now
      if self.reason.blank?
        self.errors.add(:reason,:opp_reason)

        false
      else
        self.closed_on = Time.zone.now if [5,6].include?(self.stage.to_i)
        self.comments.create(:title=> 'Status Update', :created_by_user_id=> self.updated_by_user_id,:comment =>"Opportunity Updated from #{CompanyLookup.find(self.stage_was).lvalue} to #{CompanyLookup.find(self.stage).lvalue} reason being #{self.reason}", :company_id=> self.company_id )

        true
      end
    end
  end




  #This method returns all the opportunities of a company
  def self.find_all_opportunity(params,closed_array,perpage,company_id = nil)
    search = ""
    if params[:search_items] and search_hash = params[:search]
      hash = {}
      search_hash.each do |key,value|
        next if value.blank?
        search[key] = search[key].gsub(FILTTER_PATTERN, '')  if search[key]
        if key == "contacts.last_name"
          split = value.upcase.split(' ')
          contact_name = "upper(contacts.first_name || ' ' || coalesce(contacts.last_name,'') || ' ' || coalesce(contacts.middle_name,''))"
          if split.length == 3
            search += " AND ( #{contact_name} LIKE '%#{split.first}%' AND #{contact_name} LIKE '%#{split.second}%' AND #{contact_name} LIKE '%#{split.third}%')"
          elsif split.length == 2
            search += " AND ( #{contact_name} LIKE '%#{split.first}%' AND #{contact_name} LIKE '%#{split.second}%')"
          elsif split.length == 1
            search += " AND (#{contact_name} LIKE E'%#{split.first}%')"
          end
        elsif key == "users.first_name"
          if search[key]
            search[key].split.each_with_index do |value,index|
              search += " AND  (users.first_name ILIKE E'%#{value}%' or users.last_name ILIKE E'%#{value}%')"
            end
          else
            search += " AND  ((users.first_name ||' '|| users.last_name) ILIKE '%#{value.strip}%')"
          end

        elsif key =="opportunities.probability" ||  key == "opportunities.amount"
          search += " AND #{key} = #{value.to_f} "
        elsif key == "opportunities.follow_up" || key == "opportunities.closes_on"
          
          begin
            if value[-3,1] == "/"
              value = value.split "/"
              value[2] = "20" +value[2]
              value= value.join "/"             
            end
            value = value.upcase.strip
            
            if (value[-6,1]== ":" && value[2,1] == "/")
              if(value[-2,2]=="AM" || value[-2,2]=="PM")
                meridian = value[-2,2]
                search += "AND to_char(#{key} AT TIME ZONE 'UTC','MM-DD-YY HH12:MI #{meridian}') LIKE '#{DateTime.parse(value).utc.strftime("%m-%d-%y %I:%M %p").to_s}'"
              else
                search += "AND (to_char(#{key} AT TIME ZONE 'UTC','MM-DD-YY HH12:MI PM') LIKE '%#{Time.parse(value).utc.strftime("%m-%d-%y %I:%M %p").to_s}%' OR to_char(#{key},'MM-DD-YY HH12:MI AM') LIKE '%#{Time.parse(value).utc.strftime("%m-%d-%y %I:%M AM").to_s}%')"
              end
            elsif (value[2,1] == ":")
              if(value[-2,2]=="AM" || value[-2,2]=="PM")
                meridian = value[-2,2]
                search += "AND (to_char(#{key} AT TIME ZONE 'UTC','HH12:MI #{meridian}') LIKE '%#{Time.parse(value).strftime("%I:%M %p").to_s}%')"
              end
            
              search += "AND (to_char(#{key},'HH12:MI PM') LIKE '%#{Time.parse(value).utc.strftime("%I:%M PM").to_s}%' OR to_char(#{key},'HH12:MI AM') LIKE '%#{Time.parse(value).utc.strftime("%I:%M AM").to_s}%')"
            elsif (value[2,1] == "/")
              if key == "opportunities.follow_up"
                search += "AND to_char(#{key} AT TIME ZONE 'UTC','MM-DD-YY') LIKE '%#{Date.parse(value).strftime("%m-%d-%y").to_s}%'"
              else
                search += " AND #{key} = '#{DateTime.parse(value)}' "
              end            
            end
            
          rescue Exception => e
            hash[key.sub(".","--")] = ""
            next
          end       
        
        elsif key == "opportunities_stage"
          new_key = key.sub("_",".")
          search += "AND #{new_key} in (#{value}) "
        else
          search += " #{key} ILIKE '%#{value.strip}%' "
        end
        hash[key.sub(".","--")] = value
      end
      params[:search] = hash
    end
    
    unless params[:opp_stage].blank?      
      search = "stage = #{params[:opp_stage]}"
    end
    
      if params[:letter] # in case sorting is carried out on the letter search
        if params[:col].eql?('opportunities_stage') || params[:secondary_sort].eql?('opportunities_stage')
          self.letter_search(params[:letter]).paginate(:select => 'opportunities.* ,(select alvalue from company_lookups where id = opportunities.stage) as opportunities_stage',
            :joins=>[:opportunity_stage_type],
            :conditions =>"#{search}",
            :order =>params[:order],:page => params[:page],:per_page =>perpage
          )
        else
           #if opp_stage is present then check condition for opportunity stage else for all open stages
          if params[:opp_stage].present?
            conditions = "stage = #{params[:opp_stage]}"
          else
            conditions = ["opportunities.stage NOT in (?) ",closed_array]
          end
          self.letter_search(params[:letter]).paginate(:include=>[:assignee,{:contact=>[:accounts,{:company => :opportunity_stage_types}]}],
            :conditions =>conditions,
            :order =>params[:order],
            :page =>params[:page],
            :per_page =>perpage)
        end
      else
        if params[:load_popup]
          self.all(
            :include            =>[:assignee,{:contact=>[:accounts,{:company => :opportunity_stage_types}]}],
            :conditions         =>"#{search}",
            :order              =>params[:order]
          )
        else
          if params[:col].eql?('opportunities_stage') || params[:secondary_sort].eql?('opportunities_stage')
            #TODO: joins produces lot of queries , need to re factor
            self.paginate(:select => 'opportunities.* ,(select alvalue from company_lookups where id = opportunities.stage) as opportunities_stage',
              #:joins=>[:accounts,:opportunity_stage_type],
              :include => [:assignee,{:contact=>[:accounts,{:company => :opportunity_stage_types}]}],
              :conditions =>"#{search}",
              :order =>params[:order],:page => params[:page],:per_page =>perpage
            )           
          else
            if params[:opp_stage]
              conditions = "#{search}"
            else
              conditions = ["opportunities.stage NOT in (?)  #{search}",closed_array]
            end
            self.paginate(:include=>[:assignee,{:contact=>[:accounts,{:company => :opportunity_stage_types}]}],
              
              :conditions => conditions,
              :order =>params[:order],:page => params[:page],:per_page =>perpage
            )            
          end
        end        
    end
  end

  # Below code will find opportunities assigned to a lawyer
  def self.find_my_opportunity(params,employee_user_id ,closed_array,perpage, company_id = nil)
    search = ""

    if params[:search_items] and search_hash = params[:search]
      hash = {}
      search_hash.each do |key,value|
        value = value.gsub(/[?''""]/, '')
        next if value.blank?
        if key == "contacts.last_name"
          split = value.upcase.split(' ')
          
          contact_name = "upper(contacts.first_name || ' ' || coalesce(contacts.last_name,'') || ' ' || coalesce(contacts.middle_name,''))"
          if split.length == 3
            search += " AND ( #{contact_name} LIKE '%#{split.first}%' AND #{contact_name} LIKE '%#{split.second}%' AND #{contact_name} LIKE '%#{split.third}%')"
           elsif split.length == 2
            search += " AND ( #{contact_name} LIKE '%#{split.first}%' AND #{contact_name} LIKE '%#{split.second}%' )"
          elsif split.length == 1
            search += " AND (#{contact_name} LIKE E'%#{split.first}%')"
          end
          #search += " AND  (concat(contacts.first_name ,concat(' ', contacts.last_name)) ILIKE E'%#{value.strip}%')"
        elsif key == "users.first_name"
          #search += " AND  (users.first_name ILIKE '%#{value}%' or users.last_name ILIKE '%#{value}%') "
          search += " AND  ((users.first_name ||' '|| users.last_name) ILIKE '%#{value.strip}%')"
          #          search += " AND  (concat(users.first_name ,concat(' ', users.last_name)) ILIKE '%#{value.strip}%')"
        
        elsif key =="opportunities.probability" ||  key == "opportunities.amount"
          search += " AND #{key} = #{value.to_f} "
        elsif key == "opportunities.follow_up" || key == "opportunities.closes_on"
          begin
            if value[-3,1] == "/"
              value = value.split "/"
              value[2] = "20" +value[2]
              value= value.join "/"
            end
          
            value = value.upcase.strip
        
            if (value[-6,1]== ":" && value[2,1] == "/")
              if(value[-2,2]=="AM" || value[-2,2]=="PM")
                meridian = value[-2,2]
                search += "AND to_char(#{key},'MM-DD-YY HH12:MI #{meridian}') ILIKE '#{Time.zone.at(Time.parse(value)-Time.zone.utc_offset).utc.strftime("%m-%d-%y %I:%M %p").to_s}'"
                # WARNING -----  PLEASE DON'T REMOVE THESE TWO COMMENTS  ----- WARNING
                # IN CASE IF THE REQUIREMENT COMES TO CHECK THIS CONDITON THEN WE CAN UNCOMMENT THIS
                #              else
                #                search += "AND (to_char(#{key},'MM-DD-YY HH12:MI PM') ILIKE '%#{Time.zone.at(Time.parse(value)-Time.zone.utc_offset).utc.strftime("%m-%d-%y %I:%M %p").to_s}%' OR to_char(#{key},'MM-DD-YY HH12:MI AM') LIKE '%#{Time.parse(value).utc.strftime("%m-%d-%y %I:%M AM").to_s}%')"
                #   This code will go in "else" of the condition of only yime
                #   search += "AND (to_char(#{key},'HH12:MI PM') LIKE '%#{Time.parse(value).utc.strftime("%I:%M PM").to_s}%' OR to_char(#{key},'HH12:MI AM') LIKE '%#{Time.parse(value).utc.strftime("%I:%M AM").to_s}%')"
              end
              #if value is only time
            elsif (value[2,1] == ":")
              if(value[-2,2]=="AM" || value[-2,2]=="PM")
                meridian = value[-2,2]
                search += "AND (to_char(#{key} ,'HH12:MI #{meridian}') ILIKE '%#{Time.zone.at(Time.parse(value)-Time.zone.utc_offset).utc.strftime("%I:%M %p").to_s}%')"
              end
            elsif (value[2,1] == "/")
              if key == "opportunities.follow_up"
                search += "AND to_char(#{key},'MM-DD-YY') LIKE '%#{Date.parse(value).strftime("%m-%d-%y").to_s}%'"
              else
                search += " AND #{key} = '#{DateTime.parse(value)}' "
              end            
            end

            rescue Exception => e
             hash[key.sub(".","--")] = ""
             next
            end
           elsif key == "opportunities_stage"
            new_key = key.sub("_",".")
            search += " AND #{new_key} in (#{value}) "
           else
            search += " AND #{key} ILIKE '%#{value.strip}%' "
           end

           hash[key.sub(".","--")] = value
        end
        params[:search] = hash
    end

    unless params[:opp_stage].blank?
      search = "AND stage = #{params[:opp_stage]}"
    end
    if params[:letter] # in case sorting is carried out on the letter search
       if params[:col].eql?('opportunities_stage')
          self.letter_search(params[:letter]).paginate(:select => 'opportunities.*,(select alvalue from company_lookups where id = opportunities.stage) as opportunities_stage',
            :joins=>[:assignee,:opportunity_stage_type, {:contact => [:accounts]}],
            :conditions         =>["opportunities.assigned_to_employee_user_id = ? #{search}",employee_user_id],
            :order              =>params[:order],:page => params[:page],:per_page =>perpage
          )
         else
           #if opp_stage is present then check condition for opportunity stage else for all open stages
           if params[:opp_stage].present?
            conditions = "opportunities.assigned_to_employee_user_id = ? and stage = ?", employee_user_id, params[:opp_stage]
          else
            conditions = "opportunities.assigned_to_employee_user_id = ? and opportunities.stage NOT in (?)",employee_user_id,closed_array
          end
        self.letter_search(params[:letter]).paginate(:include=>[:assignee,{:contact=>[:accounts,{:company => :opportunity_stage_types}]}],
            :conditions         =>conditions,
            :order              =>params[:order],
            :page     =>params[:page],
            :per_page =>perpage)
         end
      else
        if (params[:col].eql?('opportunities_stage') || params[:secondary_sort].eql?('opportunities_stage') ) && params[:opp_stage].blank?
          #TODO: joins produces lot of queries , need to re factor
          self.paginate(:select => 'DISTINCT(opportunities.*), contacts.last_name, accounts.name, users.first_name,(select alvalue from company_lookups where id = opportunities.stage) as opportunities_stage',
            :joins=>"LEFT OUTER JOIN contacts ON contacts.id = opportunities.contact_id
LEFT OUTER JOIN account_contacts ON (contacts.id = account_contacts.contact_id)
LEFT OUTER JOIN accounts ON (accounts.id = account_contacts.account_id)
LEFT OUTER JOIN users ON users.id = opportunities.assigned_to_employee_user_id
LEFT OUTER JOIN company_lookups ON company_lookups.id = opportunities.stage AND (company_lookups.type = 'OpportunityStageType' ) ",
            :conditions         =>["opportunities.assigned_to_employee_user_id = ? and opportunities.stage NOT in (?) #{search} ",employee_user_id,closed_array],
            :order              =>params[:order],:page => params[:page],:per_page =>perpage
          )
        else
          if params[:opp_stage]
            conditions = ["opportunities.assigned_to_employee_user_id = ?  #{search}", employee_user_id]
          else
            conditions = ["opportunities.assigned_to_employee_user_id = ? and opportunities.stage NOT in (?) #{search}", employee_user_id,closed_array]
          end
          self.paginate(
            :include           =>[:assignee,{:contact=>[:accounts,:company]}],
            :order              => params[:order],
            :conditions         => conditions,
            :page     =>params[:page],
            :per_page =>perpage)
        end
      end
  end

  #This method retrieves records from DB based on user selection of parameters in Reports
  #include or select options for below find method is passed as hash 'include_hash'
  def self.find_for_rpt(search,conditions_hash,include_hash = {})
    include_hash.merge!(:conditions => [search,conditions_hash], :order => "name ASC")
    find(:all, include_hash)
  end

  #This method validates the closure date of an opportunity.This date should be after created date and present date
  def validate_closure_date
    self.errors.add(:closes_on,:closer_date)if self.id  && self[:closes_on].present? &&  self[:closes_on].to_date < self.created_at.to_date
    self.errors.add(:closes_on,:closer_today)if !self.id && self[:closes_on].present? && self[:closes_on].to_date < Time.zone.now.to_date
  end


  #This method validates the follow up date of an opportunity.This date should be after created date

  def validate_follow_up_date
    self.errors.add(:follow_up,:follow_up_date) if self.created_at && self.follow_up &&  self.follow_up.to_date < self.created_at.to_date
    self.errors.add(:follow_up,:follow_up_date)if !self.id && self[:follow_up].present? && self[:follow_up].to_date < Time.zone.now.to_date

  end

  def change_status
    self.update_attributes(:stage => CompanyLookup.find_by_company_id_and_lvalue(self.company_id,"Closed/Lost").id, :status_updated_on => Time.zone.now, :reason => 'Opportunity deactivated')
  end

  
  #Custom verification to check presence of reason on status change
  def validate_source
    if self.company_source && self.company_source.lvalue!='Campaign'
      self.campaign_id=nil
    end
  end

  #This method returns the full name of the lawyer to which an opportunity is assigned
  def get_assigned_to
    if self.assigned_to_employee_user_id
      if self.assignee
        self.assignee.try(:full_name).try(:titleize)
      end
    end
  end

  #This method returns the probability of the opportunity
  def get_probabilty
    if self.probability
      self.probability.to_s
    else
      '0'
    end
  end


  def get_days_in_current_status
    if self.status_updated_on
      Time.zone.now.to_date - self.status_updated_on.to_date
    else
      Time.zone.now.to_date - self.created_at.to_date
    end
  end


  # Backend handler for [Create New Opportunity] form (see opportunity/create).
  #----------------------------------------------------------------------------

  def save_with_contact(params)
    self.contact_id = params[:contact][:id].to_i unless  params[:contact][:id].blank?
    self.save
  end

  
  #TODO: Need to remove
  def update_contact_status
    begin
      #current_user = User.current_user
      company = Company.find_by_id(self.company_id, :include => :contact_stages)
      contact_stage_hash = company.contact_stages.array_to_hash('lvalue')
      new_status= contact_stage_hash['Prospect'].id
      won = company.opportunity_stage_types.find_by_lvalue('Closed/Won').id
      if open_matter
        new_status= contact_stage_hash['Client'].id
      elsif self.stage == won
        new_status = contact_stage_hash['Client'].id
      elsif(self.contact && self.contact.contact_stage_id == contact_stage_hash['Lead'].id)
        new_status= contact_stage_hash['Prospect'].id
      elsif self.stage == won && all_opportunities_lost(company)
        new_status= contact_stage_hash['Lead'].id
      end
      self.contact.update_attribute('contact_stage_id', new_status) if self.contact

      # return false
    end
  end
  
  def open_matter
    begin
      op_matter = self.contact.matters.all :join => "INNER JOIN company_lookups ON company_lookups.id = matters.status_id", :conditions => "company_lookups.lvalue = 'Open' AND company_lookups.company_id = #{self.company_id}"
      op_matter.nil? && op_matter.size > 0 ? true : false
    rescue
      false
    end
  end

  # Return opportunities assigned to lawyer, which are not closed(won/lost) yet.
  def self.my_open_opportunities(cid,eid)
    Opportunity.all(:conditions => ["company_lookups.lvalue NOT IN (?) AND opportunities.company_id = ? AND opportunities.assigned_to_employee_user_id = ? ", ['Closed/Won','Closed/Lost'], cid, eid], :joins => [:opportunity_stage_type], :include => :contact)
  end

  # In single request in dashboard/home page 4 time is called so memoize is used for
     class << self; extend ActiveSupport::Memoizable; self; end.memoize :my_open_opportunities

  # Return opportunities assigned to lawyer, which are not closed(won/lost) yet
  # AND whose follow up date is given.
  def self.my_followup_open_opportunities(cid, eid)
	  #Opportunity.find(:all,:joins=>[:opportunity_stage_type],
		 #                      :conditions => ["company_lookups.lvalue not in (?) AND opportunities.company_id = ?
     # AND opportunities.assigned_to_employee_user_id = ? ",['Closed/Won','Closed/Lost'],cid, eid])

    self.my_open_opportunities(cid, eid).find_all {|e| e.follow_up }
  end

  def followup_today?
    self.follow_up && self.follow_up.to_date == Time.zone.now.to_date #((self.follow_up.to_date - Time.zone.now.to_date).to_i == 0)
  end

  def followup_upcoming?
    self.follow_up && self.follow_up > Time.zone.now.to_date && self.follow_up <= (Time.zone.now.to_date+7.days)
  end

  def followup_overdue?
    self.follow_up && self.follow_up < Time.zone.now.to_date
  end
  

  # Return opportunities assigned to lawyer, which are not closed(won/lost) yet
  # AND whose follow up date is past.
  def self.my_followup_overdue_open_opportunities(cid, eid)
    today = Time.zone.now.to_date
    self.my_open_opportunities(cid, eid).find_all {|e|
      e.follow_up && e.follow_up.to_date < today
    }
  end
  
  # Return opportunities assigned to lawyer, which are not closed(won/lost) yet
  # AND whose follow up date is coming up.
  def self.my_followup_upcoming_open_opportunities(cid, eid, user_setting)
    today = Time.zone.now.to_date
    future_count = user_setting.setting_value.to_i
    future_date = today + future_count
    self.my_open_opportunities(cid, eid).find_all {|e|
      e.follow_up && ((e.follow_up.to_date > today) && (e.follow_up.to_date <= future_date))
    }
  end

  # Return opportunities assigned to lawyer, which are not closed(won/lost) yet
  # AND whose follow up date is today!
  def self.my_followup_todays_open_opportunities(cid, eid)
    today = Time.zone.now.to_date
    self.my_open_opportunities(cid, eid).find_all {|e|
      e.follow_up && e.follow_up.to_date == today
    }
  end
  
  def get_stage
    User.current_company.opportunity_stage_types.find(self.stage).lvalue

  end
  def all_opportunities_lost(company)
    flag=true
    self.contact.opportunities.each do |opportunity|
      if opportunity.stage != company.opportunity_stage_types.find_by_lvalue('Closed/Lost').id
        flag=false
      end
    end

    flag
  end

  def self.find_all_for_sorting(params,lookup_type, order_state)
    if params[:mode_type] == 'MY'
      all(:include => [{ :contact => :accounts}, :assignee],
          :conditions => ['opportunities.assigned_to_employee_user_id = ?', params[:emp_user_id]],
          :order => order_state)
    else
      all(:include => [{:contact => :accounts}, :assignee],
          :order => order_state)
    end
    
  end

  def self.find_my_for_sorting(params,lookup_type, order_state)
    # column sorting - Supriya 3/8/2010
    if params[:letter]
      self.letter_search(params[:letter]).all(
        :include => [{:contact => :accounts}, :assignee],
        :conditions => ["assigned_to_employee_user_id = ?", params[:emp_user_id]],
        :order => order_state)
    else
      all(:include => [{:contact => :accounts}, :assignee],
          :conditions => ["opportunities.assigned_to_employee_user_id = ?", params[:emp_user_id]],
          :order => order_state)
    end


    #find(:all,:include=>[{:contact=>:accounts}, :assignee],:conditions=>['stage=?', Lookup.find_by_lvalue(lookup_type).id],:order=>order_state)
  end

  # Get Opportunities for manage opportunities as per the stage.  - Ketki 3/5/2011
  def self.get_opportunities(data = nil, company_id = nil,user_id = nil)
    conditions = "opportunities.company_id = #{company_id}"
    conditions << " and opportunities.assigned_to_employee_user_id = #{user_id}" if data[:mode_type].eql?('MY')
    if !data[:opp_stage].blank?
      conditions << " and opportunities.stage = #{data[:opp_stage]}"
    end
    conditions << " and upper(substr(opportunities.name, 1,1)) = '#{data[:letter]}'" if data[:letter]
    paginate(:conditions => conditions,:include=>[{:contact=>:accounts}, :assignee], :order => data[:order], :page => data[:page],:per_page => data[:per_page])
  end

  def format_name
    self.name.strip!
  end

  #Counts opportunities for each opportunity stage - Ketki 05/05/2011
  def self.count_stage_wise_opportunity(company, status,mode_type,emp_user_id, lookups)
    lookups.each do |status|
      if mode_type.eql?('MY')
        camp_count = company.opportunities.count(:all, :conditions =>["stage =? and assigned_to_employee_user_id=?", status[1],emp_user_id])
      else
        camp_count = company.opportunities.count(:all, :conditions =>["stage =?", status[1]])
      end
      status[0] = "#{status[0]} (#{camp_count})"
    end

    lookups
  end

  def self.get_closed_stage_id(company_id)
    CompanyLookup.find(:all,:select => [:id],:conditions => ["company_id = ? and lvalue in (?)",company_id,["Closed/Won", "Closed/Lost"]]).map(&:id)
  end

  def self.get_open_opportunity(contact_ids,company_id)
    find(:all,:conditions => ["contact_id in (?) and stage not in (?)",contact_ids,get_closed_stage_id(company_id)])
  end

  private
  # Make sure at least one user has been selected if the contact is being shared.
 
  #Send Mail to Opportunity Assigned to
  def send_mail_to_associates
    user = self.assignee
    if(@is_changed && user && User.current_user!=user)
      send_notification_to_responsible(user,self,User.current_user)
      @is_changed = false

      true
    end
  end



  def responsible_person_changed
    @is_changed = self.changed.include?("assigned_to_employee_user_id")
    true
  end
end

# == Schema Information
#
# Table name: opportunities
#
#  id                           :integer         not null, primary key
#  employee_user_id             :integer
#  campaign_id                  :integer
#  assigned_to_employee_user_id :integer
#  name                         :string(64)      default(""), not null
#  source                       :integer
#  stage                        :integer
#  probability                  :integer
#  amount                       :decimal(12, 2)
#  discount                     :decimal(12, 2)
#  closes_on                    :date
#  deleted_at                   :datetime
#  created_at                   :datetime
#  updated_at                   :datetime
#  description                  :text
#  contact_id                   :integer
#  estimated_hours              :decimal(12, 2)
#  delta                        :boolean         default(TRUE), not null
#  company_id                   :integer         not null
#  permanent_deleted_at         :datetime
#  created_by_user_id           :integer
#  updated_by_user_id           :integer
#  closed_on                    :datetime
#  follow_up                    :datetime
#  status_updated_on            :datetime
#

