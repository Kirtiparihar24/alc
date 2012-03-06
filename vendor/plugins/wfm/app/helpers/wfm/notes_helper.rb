module Wfm::NotesHelper
  
  def get_clusters(note)
    clusters = note.receiver.clusters.map(&:name)
    return clusters.blank? ? " " : clusters.join(", ")
  end

  def assigned_to_user(note)
    user = note.assigned_to
    return user.blank? ? '' : user.full_name
  end
end