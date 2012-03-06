class Document < ActiveRecord::Base
  acts_as_paranoid
  acts_as_audited  
  
  belongs_to  :user, :foreign_key =>'created_by_user_id'
  belongs_to  :employee, :foreign_key =>'employee_user_id'  
  has_attached_file :data,
    
  :url  => "assets/company/:company_id/:id_partition",
  :path => ":rails_root/assets/company/:company_id/:id_partition/:basename.:extension"

  has_many :document_bookmarks
  belongs_to :document_home, :with_deleted => true
  belongs_to  :assignee, :class_name => "User", :foreign_key => :employee_user_id
  belongs_to  :assigned_by, :class_name => "User", :foreign_key => :created_by_user_id
  belongs_to :doc_source, :foreign_key => 'doc_source_id'
  belongs_to :category, :class_name => "DocumentCategory", :foreign_key => :category_id
  belongs_to :document_type, :class_name => "DocumentType", :foreign_key => :doc_type_id
  belongs_to :sub_category, :class_name => "DocumentSubCategory"
  belongs_to :company
  belongs_to :photo, :dependent => :destroy, :class_name => 'Photo'
  belongs_to :additional_document, :dependent => :destroy, :class_name => 'AdditionalDocument'
  belongs_to :comment
  belongs_to :phase ,:foreign_key => :phase_id   
  after_create :create_notification
  after_save :bookmark_document
  attr_accessor :file
  attr_reader :SOURCES
  attr_accessor :from_photo
  attr_accessor :from_others
  SOURCES = [
    "",
    "Email",
    "Letter",
    "Fax",
    "Client",
    "Other"
  ]

  Max_Attachments = 5
  Max_Attachment_Size = 104857600 #File size in bytes to be used for max file upload size :Pratik
  Max_multi_file_upload_size= 52428800
  DOCUMENT_TO_PRODUCT={'Matter'=>:Matters, 'MatterRetainer' => :Matters, 'MatterBilling'=>:Matters,'Campaign'=> :Campaigns,'Account'=>:Accounts, 'Opportunity'=>:Opportunity, 'TimeEntry'=> 'Time & Expense','ExpenseEntry'=> 'Time & Expense', 'User'=>:Workspace, 'Company'=>'Document Repository', 'Contact'=>:Contacts, "Physical::Crm::Campaign::Campaign"=> :Campaigns, 'CampaignMail'=> :Campaigns}
  validates_presence_of :data_file_name, :message => 'a file to upload'
  validates_presence_of :name,:message=>"can't be blank", :if => :check_from_others
  validates_attachment_size :data, :less_than => 50.megabytes, :greater_than => 1.bytes,:message=>'should be between 1byte to 50MB'
  validates_attachment_content_type :data,
    :content_type => ['image/jpg', 'image/jpeg', 'image/pjpeg', 'image/gif', 'image/png', 'image/x-png'], :message => 'should be an image', :if => :from_photo
  
  def file_present?
    data_file_name.present?
  end
  after_create :update_respective_doc_for_search

  # Returns name, clipped to a fitter length.
  def clipped_name
    _matter_clip_len = 45
    if self.data_file_name.length > (_matter_clip_len-3)
      self.data_file_name[0, _matter_clip_len - 3] + "..."
    else
      self.data_file_name
    end
  end

  def content_type
    data_content_type
  end 
 
  def file_size
    data_file_size
  end

  def url(*args)
    data.url(*args)
  end

  define_index do
    set_property :delta => true
    indexes :name, :as => :document_name, :prefixes => true, :sortable => true    
    indexes document_home.tags(:name), :as => :doc_tag_name, :prefixes => true, :sortable => true
    indexes :description, :as => :document_description, :prefixes => true, :sortable => true
    indexes :author, :as => :document_author, :prefixes => true, :sortable => true
    indexes doc_source(:lvalue), :as => :source_of_document, :prefixes => true, :sortable => true
    indexes document_home(:mapable_type), :as => :document_mapable_type, :prefixes => true, :sortable => true    
    indexes [document_home.employee.first_name, document_home.employee.last_name], :as => :document_creator_name, :prefixes => true, :sortable => true
    indexes [document_home.owner.first_name, document_home.owner.last_name], :as => :document_owner, :prefixes => true, :sortable => true
    indexes :data_file_name, :as => :document_extension_type, :prefixes => true, :sortable => true
    indexes :privilege, :as => :document_privilege, :prefixes => true, :sortable => true
    indexes document_home(:extension), :as => :document_extension, :prefixes => true, :sortable => true

    has :data_file_size, :as => :document_size, :sortable => true    
    has :employee_user_id, :created_at, :updated_at, :company_id, :document_home_id, :sortable => true
    has document_home(:access_rights), :as => :document_access_rights, :sortable => true    
    has document_home(:mapable_id), :as => :document_mapable_id, :sortable => true
    has document_home(:created_at), :as => :document_created_date, :sortable => true
    has document_home(:upload_stage), :as => :document_upload_stage, :sortable => true
    has :updated_at, :as => :document_updated_date
    has :doc_type_id, :as => :document_category_type #Added By Pratik : To searh document by category.
    # Need to think about law_firm_id in search at above comment
    where "documents.id in (select  max(id)  from documents group by document_home_id)"
  end

  sphinx_scope(:current_company) { |company_id|
    {:with => {:company_id => company_id}}
  }

  def self.filter_documents(docs, mapable_type, mapable_id)
    result = []
    docs.compact.each do|e|
      doc_home = e.document_home
      if doc_home.mapable_type == mapable_type && doc_home.mapable_id == mapable_id
        result << e
      end
    end

    result
  end

  def update_respective_doc_for_search
    docs = Document.all(:conditions => ['document_home_id = ? AND created_at < ?', self.document_home_id, self.created_at], :order => 'created_at DESC', :limit => 2)
    if docs
      if docs.length == 2
        docs.each { |doc |
          doc.delta = true
          doc.save
        }
      end
    end
  end

  def bookmarked?
    lawyer_user_id = User.current_user.verified_lawyer_id_by_secretary || User.current_user.id
    DocumentBookmark.find_all_by_document_id_and_user_id(self.id, lawyer_user_id)[0].nil? == false
  end

  # Create/update bookmark for the current document, relative to current user.
  def bookmark_document
    return if  User.current_user.nil?
    lawyer_user_id = User.current_user.verified_lawyer_id_by_secretary || User.current_user.id
    doc_bookmark = DocumentBookmark.find_all_by_document_id_and_user_id(self.id, lawyer_user_id)[0]
    if self.bookmark
      DocumentBookmark.new({:document_id => self.id, :user_id => lawyer_user_id}).save! if doc_bookmark.nil?
    else
      doc_bookmark.destroy if doc_bookmark
    end
    self.send(:update_without_callbacks)
  end

  # Returns info about document uploader.
  def get_user_details
    @user = User.find(self.created_by_user_id)
    if @user.role?('secretary')
      @user.service_provider.sp_full_name.try(:titleize) + ' on behalf of ' + User.find(self.employee_user_id).full_name.titleize
    else
      @user.full_name.try(:titleize)
    end
  end
  
  HUMANIZED_COLUMNS = {:data_file_name => "Please select ", :data_file_size => 'Document size', :data => 'Document '}

  def self.human_attribute_name(attribute)
    HUMANIZED_COLUMNS[attribute.to_sym] || super
  end

  def check_from_others
    !self.from_others
  end

  # assigning documents of note to the task
  def self.assign_documents(task, note, user_id, share_with_client = false)
    for document_home in note.document_homes
      for document in document_home.documents
        document_home_new = task.document_homes.new(:access_rights=>2, :employee_user_id=>note.assigned_by_employee_user_id,
          :created_by_user_id=>user_id,:company_id=>note.company_id,:upload_stage=>1)
        if File.exists?(document.data.path)
          document_home_new.documents.build(:company_id=>note.company_id,  :employee_user_id=> note.assigned_by_employee_user_id, :created_by_user_id=>user_id, :data => File.new(document.data.path), :name =>document.data_file_name, :share_with_client => document.share_with_client )
          document_home_new.save
        end
      end
    end
  end

  def self.upload_multiple_docs_for_task_or_note(document, obj, user_id, params)
    share_documents_with_client = params[:share_documents_with_client]
    success_count,error_count=0,0
    document[:data].each_with_index do |file, i|
      params[:document_home].merge!(:access_rights=>2, :employee_user_id=>obj.assigned_by_employee_user_id,
        :created_by_user_id=>user_id,:company_id=>obj.company_id,
        :mapable_id=>obj.id,:mapable_type=>obj.class,:upload_stage=>1)
      document_home = obj.document_homes.new(params[:document_home])
      document_home.documents.build(document.merge(:company_id=>obj.company_id,  :employee_user_id=>obj.assigned_by_employee_user_id, :created_by_user_id=>user_id, :data => file, :name =>file.original_filename, :share_with_client=> share_documents_with_client ))
      if document_home.save
        if share_documents_with_client
          lawyers_document_home = document_home.clone
          lawyers_document_home.mapable_type = "User"
          lawyers_document_home.mapable_id = obj.assigned_by_employee_user_id
          lawyers_document_home.documents.build(document.merge(:company_id=>obj.company_id,:employee_user_id=>obj.assigned_by_employee_user_id, :created_by_user_id=>user_id, :data => file, :name =>file.original_filename, :share_with_client=> share_documents_with_client ))
          lawyers_document_home.save
        end
        success_count+=1
      else
        error_count+=1
      end
    end
    msg = {:error=>"",:notice=>""}
    if error_count >0
      msg[:error] = error_count.to_s + " / " +  document[:data].length.to_s  + " failed to upload"
    else
      msg[:notice] = success_count.to_s + " / " +  document[:data].length.to_s  + " files uploaded successfully"
    end
    msg
  end
end

def create_notification
  if(self.document_home.mapable_type == "Communication")
    note = self.document_home.mapable
    user = self.document_home.user
    Notification.create_notification_for_note(note,"Document Upload for Note.",user) if note.logged_by.role?('lawyer')
  elsif(self.document_home.mapable_type == "UserTask")
    task = self.document_home.mapable
    user = self.user
    Notification.create_notification_for_task(task,"Document Upload for Task.",user,self.share_with_client) unless task.communication.status.blank?
  end
end

# == Schema Information
#
# Table name: documents
#
#  id                   :integer         not null, primary key
#  name                 :string(255)
#  phase                :string(255)
#  bookmark             :boolean
#  description          :text
#  author               :string(255)
#  source               :string(255)
#  privilege            :string(255)
#  data_file_name       :string(255)
#  data_content_type    :string(255)
#  data_file_size       :integer
#  created_at           :datetime
#  updated_at           :datetime
#  employee_user_id     :integer
#  document_home_id     :integer
#  delta                :boolean         default(TRUE), not null
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  created_by_user_id   :integer
#  updated_by_user_id   :integer
#  category_id          :integer
#  sub_category_id      :integer
#  doc_source_id        :integer
#  doc_type_id          :integer
#

