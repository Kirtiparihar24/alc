class Comment < ActiveRecord::Base
  belongs_to  :user, :foreign_key =>'created_by_user_id'
  belongs_to  :commentable, :polymorphic => true
  has_many    :activities, :as => :subject, :order => 'created_at DESC'
  has_many :document_homes, :as => :mapable
  has_one :document
  acts_as_paranoid
  validates_presence_of :created_by_user_id, :commentable_id, :commentable_type, :comment, :message=>"can't be blank"
  attr_accessor :file
  
  def matter_client_comment?
    self.title.eql?("MatterTask Client") || self.title.eql?("MatterTask CGC")
  end

  # A lawer can see only those client comments which were entered for task assigned to him.
  # He can see all other task comments.
  def lawyer_can_see?(uid, mid, matter_task, cid)
    me = MatterPeople.me(uid,mid,cid)
    if self.title.eql?("MatterTask Client")
      matter_task.assigned_to_matter_people_id == me.id || client_comment_accesible?(matter_task.matter,uid)
    else
      true
    end
  end
  
  def matter_and_task_from_comment
    mt = MatterTask.find(self.commentable_id, :include => :matter)
    m = mt.matter

    [m,mt]
  end

  # Returns customized text for title if the comment was made for matter task.
  def get_title
    if self.commentable_type.eql?("MatterTask")
      if self.title.eql?("MatterTask Client")
        "Client message"
      else
        "Internal comment"
      end
    else
      self.title
    end
  end

  def client_comment_accesible?(matter, emp_user_id)
    team_member = matter.get_team_member(emp_user_id)
    if team_member
      team_member.can_view_client_comments?
    else
      false
    end
  end
  

  private
  
  def log_activity
    authentication = Authentication.find
    if authentication
      current_user = authentication.record
      Activity.log(current_user, commentable, :commented) if current_user
    end
  end

end

# == Schema Information
#
# Table name: comments
#
#  id                   :integer         not null, primary key
#  created_by_user_id   :integer
#  commentable_id       :integer
#  commentable_type     :string(255)
#  private              :boolean
#  title                :string(255)     default("")
#  comment              :text            default("")
#  created_at           :datetime
#  updated_at           :datetime
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  is_read              :boolean
#  share_with_client    :boolean
#

