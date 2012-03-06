class Campaign < ActiveRecord::Base
  include LiviaMailConfig
  #------------------------------------Associations start here--------------------------------------------------
  belongs_to :company
  has_many   :members, :class_name => "CampaignMember" #, :dependent=>:destroy
  has_many   :campaign_mails, :class_name => "CampaignMail"
  belongs_to :status, :class_name => "CampaignStatusType", :foreign_key => :campaign_status_type_id
  belongs_to :user , :foreign_key =>'owner_employee_user_id'
  has_many   :contacts, :through => :members, :uniq => true
  has_many   :opportunities , :class_name => 'Opportunity'
  has_many   :document_homes, :as => :mapable
  before_validation :format_name
  before_update :check_status_change
  before_save :responsible_person_changed
  after_save :send_mail_to_associates
  default_scope :order => 'campaigns.name ASC'
  #------------------------------------Associations ends here----------------------------------------------------

  #------------------------------------Plugins Used----------------------------------------------------
  acts_as_commentable
  acts_as_paranoid
  #----------------------------------------------------------------------------------------------------

  #---------------------------------------Named scopes------------------------------------------------------------
  attr_accessor :reason, :copy, :current_user_name,:camp_radio
  named_scope :only, lambda { |filters| { :conditions => [ "status IN (?)" + (filters.delete("other") ? " OR status IS NULL" : ""), filters ] } }
  
  named_scope :letter_search, lambda { |letter|
    { :conditions => ["UPPER(campaigns.name) like ?",letter+'%']}
  }
  #------------------------------------Named scopes ends here-----------------------------------------------------

  #------------------------------------validations starts here---------------------------------------------------
  validates_presence_of :parent_id, :if => :create_from_existing?,:message => :camp_existing
  validates_presence_of :name, :message => :camp_name
  validates_length_of :name, :maximum => 200, :message => "Should Not Exceed 200 Characters"
  validates_uniqueness_of :name,:scope=>[:company_id], :message => :camp_unique, :case_sensitive => false
  validate :start_and_end_dates
  #-------------------------------------validations ends here -----------------------------------------------------------

  cattr_reader :per_page
  @@per_page=25

  def create_from_existing?
    self.camp_radio.eql?("1")
  end

  def self.get_content(obj, url)
    content=obj
    result=[]
    content.each_line { |line|
      if line.include?('src')
        image_url=line.split('src="')
        if image_url[1].include?('http' || 'https')
          result.push(line)
        else
          final_url="#{url}" << image_url[1]
          image_url[0] << "src=" << '"' << final_url
          result.push(image_url[0])
        end
      else
        result.push(line)
      end
    }
    %Q{
              #{result}
    }.html_safe!

  end
  
  def check_status_change
    if self.campaign_status_type_id_changed?
      if self.reason.blank?
        self.errors.add(:reason,:camp_status_change)

        false
      else     
        self.comments.create(:title=> 'Status Update', :created_by_user_id=> self.updated_by_user_id,:comment =>"Campaign Updated from #{CampaignStatusType.find(self.campaign_status_type_id_was).lvalue} to #{self.status.lvalue} reason being #{self.reason}", :company_id=> self.company_id )

        true
      end
    end
  end

  #This method is used in Sphinx search
  define_index do
    set_property :delta => true
    indexes :name, :as => :campaign_name, :prefixes => true
    indexes user.first_name, :as => :contact_first_name, :prefixes => true
    indexes user.last_name, :as => :contact_last_name, :prefixes => true
    indexes members.contact.first_name, :as => :contact_first_name, :prefixes => true
    indexes members.contact.last_name, :as => :contact_last_name, :prefixes => true
    indexes :starts_on, :as => :campaign_start_date, :prefixes => true
    has :id, :company_id, :employee_user_id, :owner_employee_user_id

    where "campaigns.deleted_at is null and campaign_status_type_id not in (select id from company_lookups where company_lookups.type = 'CampaignStatusType' and ( company_lookups.lvalue = 'Completed' or company_lookups.lvalue = 'Aborted')) and campaign_members.deleted_at is null"

  end

  sphinx_scope(:current_company) { |company_id|
    {:with => {:company_id => company_id}}
  }


  #This method retrieves records from DB based on user selection of parameters in Reports
  #include or select options for below find method is passed as hash 'include_hash'
  def self.find_for_rpt(search, conditions_hash, include_hash = {})
    include_hash.merge!(:conditions =>[search,conditions_hash],:order => "name asc")
    find(:all , include_hash)
  end

  #This method returns the username of the lawyer to whom the campaign is assigned
  def get_assigned_to
    if self.owner_employee_user_id
      if self.user
        self.user.full_name.try(:titleize)
      end
    end
  end

  def self.get_invalid_emails
    last_message_read = LastMessageRead.first || "2009-01-01 10:00:40".to_date
    emails = Mail.all
    emails.each_with_index do |email, i|
      unless email.date < last_message_read
        if email.bounced?
          email_address = email.final_recipient.split(' ')
          email_address= email_address[1]
          members = CampaignMember.all(:conditions => ['campaign_member_status_type_id = ?', Lookup.find_by_type_and_lvalue('CampaignMemberStatusType', 'Contacted').id])
          members.each do |member|
            if member.contact_email == email_address
              member.update_attribute(:campaign_member_status_type_id, Lookup.find_by_type_and_lvalue('CampaignMemberStatusType','Invalid Email').id)
            end
          end
        end
      end
      if i==emails.length-1
        message_date.message= email.date
        message_date.save
      end
    end

  end

  #It returns the number of members in this campaign
  def contact_length   
    members.size
  end

  # This method will return the 1st mailed date in a campaign. This date marks the actual start of the campaign
  # Modified By -- Hitesh Rawal , Now This funciton not in use we can remove it
  def get_campaign_mail_date
    if self.members.length>0
      firstmaileddate = self.members.first(:conditions => ['first_mailed_date IS NOT NULL'], :order => 'first_mailed_date ASC')
      unless firstmaileddate.nil?
        firstmaileddate.first_mailed_date
      else
        ''
      end
    else
      ''
    end
  end
  
  #This method returns all the campaigns that are assigned to the current lawyer
  def self.find_my_campaign(user_id, params, current_company)
    search = set_filter_conditions(params,current_company)
    @campaigns = params[:letter].present? ? self.letter_search(params[:letter]) : self
    # Modified By -- Hitesh Rawal
    if params[:camp_status].eql?('deactivated')
      @campaigns.paginate(:with_deleted=>true,:select => "campaigns.*,(select first_mailed_date from campaign_members where first_mailed_date is not null and campaign_id = campaigns.id limit 1) as first_mailed_date,(select alvalue from company_lookups where id = campaigns.campaign_status_type_id) as campaign_status ,(select username from users where id = campaigns.owner_employee_user_id) as username,(select count(*) from campaign_members where campaign_id = campaigns.id) as member_count, (select count(responded_date) from campaign_members where campaign_id = campaigns.id and responded_date is not null)  as responded_date, (select count(campaign_member_status_type_id) from campaign_members where campaign_id = campaigns.id and campaign_member_status_type_id = (select id from company_lookups where company_id = #{current_company.id} and type ='CampaignMemberStatusType' and lvalue = 'Responded')) as campaign_member_status_type_id, (select count(*) from opportunities where campaign_id = campaigns.id)  as opportunity, COALESCE((select sum(amount) from opportunities where campaign_id = campaigns.id), '0')  as opportunity_amount",:conditions=>["campaigns.owner_employee_user_id in (?) and campaigns.deleted_at is NOT NULL #{search}",user_id  ],:include=>[:company,:user,:members],:order=>params[:order],:page=>params[:page],:per_page=>params[:per_page])
    else
      @campaigns.paginate(:select => "campaigns.*,(select first_mailed_date from campaign_members where first_mailed_date is not null and campaign_id = campaigns.id limit 1) as first_mailed_date,(select alvalue from company_lookups where id = campaigns.campaign_status_type_id) as campaign_status ,(select username from users where id = campaigns.owner_employee_user_id) as username,(select count(*) from campaign_members where campaign_id = campaigns.id and deleted_at is null) as member_count, (select count(responded_date) from campaign_members where campaign_id = campaigns.id and responded_date is not null)  as responded_date, (select count(campaign_member_status_type_id) from campaign_members where campaign_id = campaigns.id and campaign_member_status_type_id = (select id from company_lookups where company_id = #{current_company.id} and type ='CampaignMemberStatusType' and lvalue = 'Responded')) as campaign_member_status_type_id, (select count(*) from opportunities where campaign_id = campaigns.id and deleted_at is null)  as opportunity, COALESCE((select sum(amount) from opportunities where campaign_id = campaigns.id), '0')  as opportunity_amount",:conditions=>["campaigns.owner_employee_user_id in (?) #{search}",user_id  ],:include=>[:company,:user,:members],:order=>params[:order],:page=>params[:page],:per_page=>params[:per_page])
    end
  end  

  def self.set_filter_conditions(params, current_company_id)
    conditions = ""
    if params[:search_items] and search = params[:search]
      hash = {}
      search.each do |key,value|
        next if value.blank?
        if key == "campaigns.starts_on" || key == "campaigns.ends_on"
          begin
            conditions += "AND #{key} = '#{value}' "
          rescue Exception => e
            hash[key] = ""
            next
          end
        elsif key == "users.username"
          conditions += " AND  (users.first_name ILIKE '%#{value}%' or users.last_name ILIKE '%#{value}%') "
        else
          conditions += " AND #{key} ILIKE '%#{value}%' "
        end
        hash[key.sub(".","--")] = value
      end
      params[:search] = hash
    end    
    if params[:camp_status].eql?('active')||params[:camp_status].nil?
      conditions += "AND campaigns.campaign_status_type_id NOT IN(#{CampaignStatusType.completed_or_aborted(current_company_id).collect(&:id).join(',')})"
    elsif  params[:camp_status].eql?('deactivated')
      conditions += "AND campaigns.campaign_status_type_id IN(#{current_company_id.campaign_status_types.collect(&:id).join(',')})"
    end
    conditions
  end

  #This method returns all the campaign of the company
  # Modified By -- Hitesh Rawal
  def self.find_all_campaign(params, current_company)
    search = "1=1 "
    search += set_filter_conditions(params,current_company)
    letter = params[:letter].present? ? params[:letter] : ''
    if params[:camp_status].eql?('deactivated')    
      self.letter_search(letter).paginate(:only_deleted=>true,:select => "campaigns.*,(select first_mailed_date from campaign_members where first_mailed_date is not null and campaign_id = campaigns.id limit 1) as first_mailed_date,(select alvalue from company_lookups where id = campaigns.campaign_status_type_id) as campaign_status ,(select username from users where id = campaigns.owner_employee_user_id) as username,(select count(*) from campaign_members where campaign_id = campaigns.id) as member_count, (select count(responded_date) from campaign_members where campaign_id = campaigns.id and responded_date is not null)  as responded_date, (select count(campaign_member_status_type_id) from campaign_members where campaign_id = campaigns.id and campaign_member_status_type_id = (select id from company_lookups where company_id = #{current_company.id} and type ='CampaignMemberStatusType' and lvalue = 'Responded')) as campaign_member_status_type_id, (select count(*) from opportunities where campaign_id = campaigns.id)  as opportunity, COALESCE((select sum(amount) from opportunities where campaign_id = campaigns.id), '0')  as opportunity_amount",:conditions => search,:order=>params[:order],:page=>params[:page],:per_page=>params[:per_page],:include=>[:company,:user,:members])
    else
      if params[:action]['new'] ||  params[:action]['create'] || params[:action]['search_campaign']
        #Commented By Pratik AJ : For Bug #9673 - Which states that all campaigns(eben completed and Aboted campaigns )should also be listed in Parent campaigns list.
        #self.find(:all, :select => "campaigns.*,(select first_mailed_date from campaign_members where first_mailed_date is not null and campaign_id = campaigns.id limit 1) as first_mailed_date,(select alvalue from company_lookups where id = campaigns.campaign_status_type_id) as campaign_status ,(select username from users where id = campaigns.owner_employee_user_id) as username,(select count(*) from campaign_members where campaign_id = campaigns.id and deleted_at is null) as member_count, (select count(responded_date) from campaign_members where campaign_id = campaigns.id and responded_date is not null)  as responded_date, (select count(campaign_member_status_type_id) from campaign_members where campaign_id = campaigns.id and campaign_member_status_type_id = (select id from company_lookups where company_id = #{current_company.id} and type ='CampaignMemberStatusType' and lvalue = 'Responded')) as campaign_member_status_type_id, (select count(*) from opportunities where campaign_id = campaigns.id and deleted_at is null)  as opportunity, COALESCE((select sum(amount) from opportunities where campaign_id = campaigns.id), '0')  as opportunity_amount",:conditions => search,:order=>params[:order],:include=>[:company,:user,:members])
        current_company.campaigns
      else
        self.letter_search(letter).paginate(:select => "campaigns.*,(select first_mailed_date from campaign_members where first_mailed_date is not null and campaign_id = campaigns.id limit 1) as first_mailed_date,(select alvalue from company_lookups where id = campaigns.campaign_status_type_id) as campaign_status ,(select username from users where id = campaigns.owner_employee_user_id) as username,(select count(*) from campaign_members where campaign_id = campaigns.id and deleted_at is null) as member_count, (select count(responded_date) from campaign_members where campaign_id = campaigns.id and responded_date is not null)  as responded_date, (select count(campaign_member_status_type_id) from campaign_members where campaign_id = campaigns.id and campaign_member_status_type_id = (select id from company_lookups where company_id = #{current_company.id} and type ='CampaignMemberStatusType' and lvalue = 'Responded')) as campaign_member_status_type_id, (select count(*) from opportunities where campaign_id = campaigns.id and deleted_at is null)  as opportunity, COALESCE((select sum(amount) from opportunities where campaign_id = campaigns.id), '0')  as opportunity_amount",:conditions => search,:order=>params[:order],:page=>params[:page],:per_page=>params[:per_page],:include=>[:company,:user,:members])        
      end
    end
  end

  def self.find_assignee(assignee_id)
    self.find_all {|o|
      o.owner_employee_user_id ? o.owner_employee_user_id == assignee_id.to_i : false
    }
  end

  def self.find_completed_or_aborted(campaign_status)
    self.all(:conditions => ["campaign_status_type_id IN (?)", campaign_status])
  end

  #This method checks whether a mail has been sent in a campaign or not.
  def mail_sent
    self.first_email_sent
  end

  # This method checks the number of members whose email id is invalid
  def get_invalid_mails_length
    invalid_mails = self.members.all(:conditions => ['campaign_member_status_type_id = ?', CampaignMemberStatusType.find_by_value('Invalid Email') ]).length
    if invalid_mails > 0
      invalid_mails.to_s
    else
      '0'
    end
  end

  def get_response_details(member, response)
    if response.to_i > 0
      per =  (response.to_f/member.to_f)*100
      response.to_s + '(' + sprintf("%.2f", per).to_f.to_s + '%)'
    else
      '0'
    end
  end
  
  #This method returns the success rate of a campaign responses without %
  def get_response
    (self.members.select do |obj|
        obj.responded_date
      end).length
  end

  #This method returns the success rate of a campaign based on the opportunities created from it .These details are displayed on the home page.
  def get_opportunity_details(member, opportunity)
    if opportunity.to_i > 0
      per = (opportunity.to_f / member.to_f) * 100
      opportunity.to_s + '(' + sprintf("%.2f", per).to_f.to_s + '%)'
    else  
      '0'
    end
  end

  #returning opportunities
  def get_opportunities
    Opportunity.all(:conditions => ['campaign_id = ? AND company_id = ?', self.id, self.company_id]).length
  end

  #returning revenue of opportunities closed/won
  def get_opp_closed_and_revenue(lookup)
    revenue = 0
    col = self.opportunities.select do |obj|
      obj.stage = lookup
    end
    col.each do |obj|
      revenue=revenue +obj.amount if obj.amount
    end
    [col.length, revenue]
  end

  def get_unattended_response_count
    responded_id = self.company.campaign_member_status_types.find_by_lvalue("Responded").id
    self.members.all(:conditions => ['campaign_member_status_type_id = ?', responded_id]).count
  end  
  
  #This method returns the total value of the opportunities which are created from a campaign  .
  def get_total_revenue
    revenue = 0
    self.opportunities.each do |opportunity|
      revenue = revenue + opportunity.amount if opportunity.amount
    end
    revenue
  end

  #Send Mail to Matter_task Associates
  def send_mail_to_associates
    user = self.user
    if(@is_changed && user && User.current_user!=user)
      send_notification_to_responsible(user,self,User.current_user)
      @is_changed = false
      true
    end
  end

  #Counts campaigns for each campaign-status-type - Ketki 05/05/2011
  def self.count_stage_wise_campaigns(company, status,mode_type,emp_user_id, lookups)
    lookups.each do |status|
      if mode_type.eql?('MY')
        camp_count = company.campaigns.count(:all, :conditions =>["campaign_status_type_id =? and owner_employee_user_id=?", status[1],emp_user_id])
      else
        camp_count = company.campaigns.count(:all, :conditions =>["campaign_status_type_id =?", status[1]])
      end
      status[0] = "#{status[0]} (#{camp_count})"
    end
    lookups
  end

  # Gets campaigns for managed campaigns - Ketki 4/5/2011
  def self.get_campaigns(data = nil, company_id = nil,user_id = nil)
    conditions = "campaigns.company_id = #{company_id} "
    conditions << " and campaigns.owner_employee_user_id = #{user_id}"  if data[:mode_type].eql?('MY')
    conditions << " and campaigns.campaign_status_type_id = #{data[:stage]} " if data[:stage].present?
    conditions << " and upper(substr(campaigns.name, 1, 1)) = '#{data[:letter]}' " unless data[:letter].blank?
    paginate(:select => "campaigns.*,(select first_mailed_date from campaign_members where first_mailed_date is not null and campaign_id = campaigns.id limit 1) as first_mailed_date,(select alvalue from company_lookups where id = campaigns.campaign_status_type_id) as campaign_status ,(select username from users where id = campaigns.owner_employee_user_id) as username,(select count(*) from campaign_members where campaign_id = campaigns.id and deleted_at is null) as member_count, (select count(responded_date) from campaign_members where campaign_id = campaigns.id and responded_date is not null)  as responded_date, (select count(campaign_member_status_type_id) from campaign_members where campaign_id = campaigns.id and campaign_member_status_type_id = (select id from company_lookups where company_id = #{current_company.id} and type ='CampaignMemberStatusType' and lvalue = 'Responded')) as campaign_member_status_type_id, (select count(*) from opportunities where campaign_id = campaigns.id and deleted_at is null)  as opportunity, COALESCE((select sum(amount) from opportunities where campaign_id = campaigns.id), '0')  as opportunity_amount",:conditions => conditions,:include=>:user, :order => data[:order], :page => data[:page],:per_page => data[:per_page])
  end

  # Gets the first mail date for each campaign on manage campaign by selecting first member - Ketki 5/5/2011
  def self.get_all_first_mail_date(company, campaigns)
    first_mail_date = []
    camps_id = campaigns.collect{|camps| camps.id}
    camps_id.each do |cid|
      first_mail_date << company.campaign_members.get_first_mailed_date(cid).first unless camps_id.blank?
    end
    first_mail_date = first_mail_date.flatten
  end


  def self.save_docs(document_data,additional_documents_data,campaign_email,employee_user_id,emp_user_id, company_id,current_company_id,current_user_id)
    document_error = 0
    additional_documents = document = nil
    document_data[:data].each do |doc|
      additional_documents_data.merge!(:created_by_user_id => current_user_id,
        :upload_stage => 1,
        :employee_user_id=>emp_user_id,
        :company_id => current_company_id,
        :access_rights => 2
      )
      additional_documents = campaign_email.document_homes.new(additional_documents_data)
      document = additional_documents.documents.build(document_data.merge(:data => doc, :name => doc.original_filename,:company_id=>company_id,  :employee_user_id=> employee_user_id, :created_by_user_id=>current_user_id ))
      unless additional_documents.save
        document_error += 1
      end      
    end
    
    return document_error,additional_documents,document
  end

  def self.copy_attachments_from_campgs(copy_email, current_user_id,campaign_email_id,employee_user_id,current_company_id)
    copy_email.document_homes.each do |copy_doc_home|
      additional_documents = copy_doc_home.clone
      additional_documents.mapable_id = campaign_email_id
      additional_documents.created_by_user_id = current_user_id
      additional_documents.employee_user_id = employee_user_id
      additional_documents.save
      unless copy_doc_home.documents.empty?
        copy_doc_home.documents.each do |document|
          # ADD CODE to see if not deleted = true
          new_document = document.clone
          new_document.created_by_user_id = employee_user_id
          new_document.company_id = current_company_id
          new_document.document_home_id = additional_documents.id
          new_document.save
          path ="#{new_document.data.path.gsub(/\/\w+[.][^.]+$/,"")}"
          system "mkdir #{path}"
          system "cp #{document.data.path} #{path}"
        end
      end
    end
  end


  private

  def responsible_person_changed
    @is_changed = self.changed.include?("owner_employee_user_id")
    true
  end

  # This method is a custom validation to check whether start date is before end date
  def start_and_end_dates
    if (self.starts_on && self.ends_on) && (self.starts_on >= self.ends_on)
      errors.add(:ends_on, :camp_date)
    end
  end

  def format_name
    self.name.strip!
  end

end

# == Schema Information
#
# Table name: campaigns
#
#  id                      :integer         not null, primary key
#  created_at              :datetime        not null
#  updated_at              :datetime
#  name                    :string(200)     not null
#  details                 :text
#  campaign_status_type_id :integer
#  parent_id               :integer
#  owner_employee_user_id  :integer
#  employee_user_id        :integer
#  opportunities_count     :integer
#  starts_on               :date
#  ends_on                 :date
#  deleted_at              :datetime
#  delta                   :boolean         default(TRUE), not null
#  company_id              :integer         not null
#  permanent_deleted_at    :datetime
#  updated_by_user_id      :integer
#  created_by_user_id      :integer
#

