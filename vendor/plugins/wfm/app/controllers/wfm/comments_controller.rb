class Wfm::CommentsController < WfmApplicationController
  before_filter :authenticate_user!
  layout 'wfm'
  def new
    @comment = Comment.new
    @commentable_object = params[:commentable_class].constantize.find(params[:commentable_id])
    render :layout=>false
  end

  def create
    @comment = Comment.new(params[:comment])
    render :update do |page|
      if @comment.save
        Notification.create_notification_for_task(@comment.commentable,"Comment on Task.",@comment.user,@comment.share_with_client) if @comment.commentable_type == "UserTask" && @comment.commentable.status != "complete"
        page << "tb_remove();"
        flash[:notice] = "Comment saved successfully."
        page.redirect_to edit_wfm_user_task_path(@comment.commentable_id)
      else
        page << "enableAllSubmitButtons('buttons_to_disable');show_error_msg('modal_new_task_errors','Comment cannot be blank','message_error_div');"
      end
    end
  end

  def edit
    @comment = Comment.find(params[:id])
    render :layout=>false
  end

  def update
    @comment = Comment.find(params[:id])
    render :update do |page|
      if @comment.update_attributes(:share_with_client =>params[:share_with_client])
        #page.redirect_to edit_wfm_user_task_path(@comment.commentable_id)
        page << "show_error_msg('comment_errors','Comment updated successfully','message_success_div');"
      else
        page << "show_error_msg('comment_errors','There was error updating comment. Please try again','message_error_div');"
      end
    end
  end
end