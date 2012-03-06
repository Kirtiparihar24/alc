
class DocumentBookmark < ActiveRecord::Base
  belongs_to :user, :foreign_key => :user_id
  belongs_to :document, :foreign_key => :document_id
  
end

# == Schema Information
#
# Table name: document_bookmarks
#
#  id               :integer         not null, primary key
#  document_home_id :integer
#  document_id      :integer
#  user_id          :integer
#

