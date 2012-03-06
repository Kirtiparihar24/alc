class ImportHistory < ActiveRecord::Base
  belongs_to :company
  after_destroy :cleanup_folder
  
  def cleanup_folder
    dir = self.error_filename || self.original_filename
    if dir.present?    
      dir = dir.split("/")
      dir = dir[0...dir.length].join("/")
      FileUtils.remove_dir(dir) rescue "Directory is not remove "
    end 
  end
  
  def uploaded_for
    User.find(self.employee_user_id).username rescue "" 
  end
  def uploaded_by
    User.find(self.owner_id).username rescue ""
  end
end
