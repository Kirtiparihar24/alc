module Physical::Liviaservices::LiviaSecretariesHelper

  def task_created_date(condition)
    @com_notes_entries = Communication.find(:first,:conditions=>["id=?",condition.to_i])
    @com_notes_entries.created_at
    return time_ago_in_words(@com_notes_entries.created_at)
  end

  def task_urgent(condition)
    @com_notes_entries =Communication.find(:first,:conditions=>["id=?",condition.to_i])
    unless @com_notes_entries.nil?
      if @com_notes_entries.note_priority.eql?(2)
        return true
      else
        return false
      end
    end
  end
  
end
