# To change this template, choose Tools | Templates
# and open the template in the editor.

class StickyNoteSweeper < ActionController::Caching::Sweeper
  observe StickyNote

  # If our sweeper detects that a StickyNote was created call this
  def after_create(sticky_note)
    expire_cache_for(sticky_note)
  end

  # If our sweeper detects that a StickyNote was updated call this
  def after_update(sticky_note)
    expire_cache_for(sticky_note)
  end

  # If our sweeper detects that a StickyNote was deleted call this
  def after_destroy(sticky_note)
    expire_cache_for(sticky_note)
  end

  private
  def expire_cache_for(sticky_note)
    # Expire a fragment
    expire_fragment("sticky_notes_#{sticky_note.assigned_to_user_id}")
  end
end
