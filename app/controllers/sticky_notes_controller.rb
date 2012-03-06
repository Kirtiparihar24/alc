class StickyNotesController < ApplicationController
  before_filter :authenticate_user!
  cache_sweeper :sticky_note_sweeper, :only => [:create,:update,:destroy]
=begin
date : 11-08-2010
Author : Sanil Naik
References : railscast complex form part 1,2,3,http://www.quirksmode.org/js/cookies.html
overview : On login it checks for current user's sticky note, If its nil it builds 5 times.
           See app/controller/application_controller
           Action- load_sticky_notes
           For sticky textarea onchange event is used to assign onblur events this removes
           the problem of blank create and reduces unnecessary ajax calls
           See public/javascripts/sticky_notes/core.js
           function - setBlurActions()
           All ajax requests are restful.
           See sticky_notes_controller
=end

  def update
    @sticky_note = StickyNote.find(params[:id])
    @sticky_note.update_attributes(params[:sticky_note])
  end

  def create
    params[:sticky_note].merge!(:created_by_user_id =>current_user.id,
      :company_id=>get_company_id,:assigned_to_user_id=>assigned_user)
    @sticky_note=StickyNote.new(params[:sticky_note])
    @sticky_note.save
  end

  def destroy
    @sticky_notes_empty=false
    @sticky_note=StickyNote.find(params[:id])
    if(@sticky_note.assigned_to_user_id == current_user.id)
      @sticky_note.destroy
      deleted = 'deleted'
    else
      deleted = "Access Denied"
    end
    render :text =>deleted
  end
end
