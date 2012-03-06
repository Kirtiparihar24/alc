class Communication < ActiveRecord::Base
  set_table_name "notes"
  belongs_to :company  
  belongs_to :receiver, :class_name => "User", :include => :company, :foreign_key => 'assigned_by_employee_user_id'
  belongs_to :logged_by, :class_name => "User", :foreign_key => 'created_by_user_id'
  belongs_to :assigned_to, :class_name => "User", :foreign_key => 'assigned_to_user_id'
  belongs_to :matter
  belongs_to :contact
  has_many :notifications, :as => :notification, :order => 'created_at DESC',:dependent => :destroy
  # this association was changed as the name "tasks" was conflicting with tasks in rake - sania wagle mar 1 2011
  #  has_many   :tasks
  has_many   :user_tasks, :foreign_key => 'note_id'
  has_many :document_homes, :as => :mapable
  delegate :clusters, :to => :receiver
  
  validate do |note|
    note.errors.add_to_base("Note description can not be blank") if note.description.blank?
    note.errors.add_to_base("Please select a Lawyer") if note.assigned_by_employee_user_id.blank?
  end

  acts_as_paranoid

  named_scope :count_lawyer_assigned_user_notes,lambda{|user_ids|{:select=>'count(*) as new_notes', :conditions=>['assigned_by_employee_user_id in (?) and status IS NULL', user_ids]}}
  named_scope :get_cluster_notes,lambda{|user_ids|{:conditions=>['assigned_by_employee_user_id in (?) and status IS NULL', user_ids], :order => 'updated_at DESC'}}
  named_scope :completed, lambda{|user_ids|{:conditions=>['assigned_by_employee_user_id in (?) and status = ?', user_ids, 'complete'], :order => 'updated_at DESC'}}
  named_scope :more_than_2_days, lambda{|user_ids|{:conditions=>['assigned_by_employee_user_id in (?) and status IS NULL and date(created_at) + 2 < ?', user_ids, Date.today], :order => 'updated_at DESC'}}
  named_scope :today, lambda{|user_ids|{:conditions=>['assigned_by_employee_user_id in (?) and status IS NULL and date(created_at) = ?', user_ids, Date.today], :order => 'updated_at DESC'}}
  named_scope :count_lawyer_and_current_user_created,lambda{|user_ids,current_user_id|{:select=>'count(*) as new_notes', :conditions=>['(created_by_user_id in (?) or assigned_to_user_id = ? ) and status IS NULL', user_ids, current_user_id]}}
  named_scope :open_notes, :conditions => ["status IS NULL OR status != 'complete'"], :order => 'created_at DESC'
  named_scope :count_for_manager,lambda{|lawyer_ids,livian_ids|{:select=>'count(*) as new_notes', :conditions=>['(assigned_by_employee_user_id in (?) or assigned_to_user_id in (?) or created_by_user_id in (?)) and status IS NULL', lawyer_ids,livian_ids,livian_ids]}}
  named_scope :notes_for_secretary,lambda{|lawyer_ids,current_user_id|{:select=>'DISTINCT assigned_by_employee_user_id,company_id,id',:conditions=>['(assigned_to_user_id in (?) or created_by_user_id in (?)) and status IS NULL', current_user_id,lawyer_ids]}}
  named_scope :notes_for_manager,lambda{|lawyer_ids,livian_ids|{:select=>'DISTINCT assigned_by_employee_user_id,company_id,id',:conditions=>['(assigned_by_employee_user_id in (?) or assigned_to_user_id in (?) or created_by_user_id in (?)) and status IS NULL', lawyer_ids,livian_ids,livian_ids]}}

  # Below code is use in manager portal page to get all the notes details of that secratary
  def self.get_secratary_details_notes_list(secratary)
    all(:conditions => ["status IS NULL AND assigned_to_user_id = ?", secratary], :include => [:receiver => [:service_provider_employee_mappings => :service_provider]])
  end

  # Return instructions created by the given employee.
  def self.get_my_instructions(cid, eid)
    @communication = Communication.all(
      :conditions => [
        "company_id = ? AND assigned_by_employee_user_id = ? AND (status IS NULL OR status != 'complete')",
        cid, eid
      ],:order => 'created_at desc'
    )
  end

  def self.get_notes(params, user_ids, secretary, current_user, livian_ids)
    if params[:search].present?
      if !(params[:search][:employee_user_id].blank?)
        ids = params[:search][:employee_user_id]
      elsif !(params[:search][:cluster_id].blank?)
        cluster = Cluster.find(params[:search][:cluster_id])
        ids = cluster.lawyers.map(&:id).join(',')
      else
        ids = user_ids.join(',')
      end
    else
      ids = user_ids.join(',')
    end
    ids = [0] if ids.blank?
    if secretary
      if params[:search].present? && !(params[:search][:employee_user_id].blank?)
        conditions= "(created_by_user_id in (#{user_ids.join(',')}) or assigned_to_user_id = #{current_user.id}) and assigned_by_employee_user_id in (#{ids})"
      else
        conditions= "(created_by_user_id in (#{ids}) or assigned_to_user_id = #{current_user.id})"
      end
    else
      conditions= "assigned_by_employee_user_id in (#{ids})"
      if current_user.belongs_to_common_pool || current_user.belongs_to_back_office
        if params[:search].present? && !(params[:search][:employee_user_id].blank?)
          conditions = "(" + conditions + " and (created_by_user_id in (#{livian_ids.join(',')}) or assigned_to_user_id in (#{livian_ids.join(',')})))" unless livian_ids.blank?
        else
          conditions = "(" + conditions + " or created_by_user_id in (#{livian_ids.join(',')}) or assigned_to_user_id in (#{livian_ids.join(',')}))" unless livian_ids.blank?
        end
      else
        unless (params[:search].present? && !(params[:search][:employee_user_id].blank?))
          conditions = "(" + conditions + " or created_by_user_id in (#{livian_ids.join(',')}) or assigned_to_user_id in (#{livian_ids.join(',')}))" unless livian_ids.blank?
        end
      end
    end
    if params[:search].present?
      if params[:search][:user_id].present?
        conditions += " and created_by_user_id = #{params[:search][:user_id]}"
      end
      if params[:search][:company_id].present?
        conditions += " and company_id = '#{params[:search][:company_id]}'"
      end
      unless params[:search][:priority].blank?
        conditions = "(" + conditions + ")" + " and note_priority = '#{params[:search][:priority]}'"
      end
      if params[:search][:status].present? &&  params[:search][:status] == "More-than-2-days"
        conditions += " and date(created_at) < '#{Time.zone.now.utc.to_date-2}'"
      end
    end
    conditions = "(" + conditions + ")" +  " and status IS NULL"
    paginate :conditions => conditions, :order => 'updated_at DESC', :page => params[:page], :per_page => params[:per_page] || 10
  end

  def validate_note_docs(params)
    errors =""
    errors += "<li>Comment can not be blank</li>" if !params[:complete].blank? && params[:complete_comment].blank?
    errors += "<li>Comment can not be blank</li>" if !params[:assign].blank? && params[:assign_comment].blank?
    unless self.valid?
      errors += self.errors.full_messages.collect {|e| "<li>"+ e + "</li>" }.join(" ")
    end
    if params[:document_home].present?
      document=params[:document_home][:document_attributes]
      total_size=0
      document[:data].each do |file|
        total_size+=file.size
      end
      if total_size > Document::Max_multi_file_upload_size
        errors += "<li>File size is not in the correct range [0.1- 15 Mb].</li>"
      end
    end
    errors
  end

  def complete_note(params, user_id)
    params[:task].merge!(:created_by_user_id =>user_id,:assigned_by_employee_user_id =>self.assigned_by_employee_user_id,
      :company_id=>self.company_id,:note_id=>self.id,:status=>"complete",:name=>self.description,:assigned_to_user_id=>user_id,
      :completed_by_user_id=>user_id,:assigned_by_user_id=>user_id,:completed_at=>Time.now)
    task = UserTask.new(params[:task])
    unless task.work_subtype_id.nil?
      work_subtype = WorkSubtype.find(task.work_subtype_id)
      task.category_id = work_subtype.work_type.category_id
      if task.work_subtype_complexity_id.nil? && !work_subtype.work_subtype_complexities.blank?
        task.work_subtype_complexity_id = work_subtype.work_subtype_complexities.first.id
      end
    end
    task.save
    self.update_attribute(:status,"complete")
    Document.assign_documents(task,self,user_id)
    Comment.create(:commentable_type=>"UserTask",:commentable_id=>task.id,:created_by_user_id=>user_id,
      :comment=>params[:comment],:company_id=>task.company_id,:title=>"UserTask")
  end

  def self.find_notes_created_by_or_assigend_to(user_id)
    all(:conditions => ["created_by_user_id = ? OR assigned_to_user_id = ?", user_id, user_id])
  end

  def self.get_notes_count(lawyer_ids, livian_user_ids, secretary, current_user)
    created_by_user_ids = lawyer_ids
    if secretary
      created_by_user_ids << current_user.id
      count_lawyer_and_current_user_created(created_by_user_ids,current_user.id)[0].new_notes
    else
      count_for_manager(lawyer_ids,livian_user_ids)[0].new_notes
    end
  end

  def logged_by_with_destroyed
    User.find_with_deleted(self.created_by_user_id)
  end

end

# == Schema Information
#
# Table name: notes
#
#  id                           :integer         not null, primary key
#  created_at                   :datetime        not null
#  updated_at                   :datetime
#  assigned_by_employee_user_id :integer         not null
#  created_by_user_id           :integer         not null
#  description                  :text            not null
#  note_priority                :integer
#  is_actionable                :boolean         default(FALSE)
#  more_action                  :boolean         default(FALSE)
#  matter_id                    :integer
#  assigned_to_user_id          :integer
#  deleted_at                   :datetime
#  status                       :text
#  contact_id                   :integer
#  company_id                   :integer
#  updated_by_user_id           :integer
#  permanent_deleted_at         :time
#  call_id                      :string(255)
#

