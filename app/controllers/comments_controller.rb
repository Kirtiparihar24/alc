class CommentsController < ApplicationController
  include GeneralFunction
  verify :method => :post , :only => [:create,:comment_with_file]
  verify :method => :put , :only => [:update]
  before_filter :authenticate_user!
  COMMENTABLE = %w(account_id campaign_id contact_id lead_id opportunity_id task_id).freeze

  def new
    @comment = Comment.new
    render :layout => false
  end

  def matter_create
    @comment = Comment.new(params[:comment])        
    # Check if this is a matter task client comment and should be shown to client.
    unless params[:for_client].blank?
      @comment.title = "MatterTask Client"
    end
    if @comment.commentable
      @comment.commentable_type.constantize.find(@comment.commentable.id)
    else
      raise ActiveRecord::RecordNotFound
    end
    @comment.company_id = get_company_id
    respond_to do |format|
      if @comment.save        
        checktype = @comment.commentable_type!="MatterIssue"&&@comment.commentable_type!="MatterRisk"&&@comment.commentable_type!="MatterFact"&&@comment.commentable_type!="MatterResearch"
        format.js {
          render :update do |page|
            line = %Q{<tr class=bg1><td>#{truncate_hover(@comment.comment, 100)}</td><td>#{@comment.user.try(:full_name)}</td>#{'<td>' +@comment.get_title + '</td>' if checktype}<td align=center>#{@comment.created_at.to_time.strftime("%m/%d/%Y %H:%M")}</td></tr>}.html_safe!
            page << "jQuery(#{line.to_json}).insertAfter('#matter_comments')"
            page << "tb_remove()"
            page << "jQuery('#loader').hide();"
            page << "jQuery('#modal_matter_comment').hide()"
            page << "jQuery('#comment_comment').val('')"
            page << "jQuery('#comment_err').hide()"
            page << "set_bgclass()"
            page << "update_comment_count()"            
          end
        }
        format.html {}        
      else        
        format.js {
          render :update do |page|
            errs = "<ul>" + @comment.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
            page << "jQuery('#loader').hide();"
            page << "show_error_msg('comment_err', \"#{errs}\", 'message_error_div')"            
          end
        }
      end
    end
  rescue ActiveRecord::RecordNotFound # Kicks in if commentable asset was not found.
    respond_to_related_not_found(params[:comment][:commentable_type].downcase, :js, :xml)
  end
  
  # POST /comments
  # POST /comments.xml                                                     AJAX
  #----------------------------------------------------------------------------
  def create
    params[:comment][:comment]=CGI::escapeHTML(params[:comment][:comment])
    @comment = Comment.new(params[:comment])
    # Make sure commentable object exists and is accessible to the current user.
    # Check if this is a matter task client comment and should be shown to client.
    unless params[:for_client].blank?
      @comment.title = "MatterTask Client"
    end
    if @comment.commentable
      @comment.commentable_type.constantize.find(@comment.commentable.id)
    else
      raise ActiveRecord::RecordNotFound
    end
    @comment.company_id = get_company_id
    @comment.share_with_client = true if params[:comment][:commentable_type] == "UserTask"
    respond_to do |format|
      if @comment.save
        Notification.create_notification_for_task(@comment.commentable,"Comment on Task.",@comment.user,@comment.share_with_client) if @comment.commentable_type == "UserTask" && @comment.commentable.status != "complete"
        if params[:comment][:title] == 'MatterTask Client'
          mattertask = MatterTask.find(@comment.commentable.id)
          user = mattertask.matter.user
          send_notification_from_client(user,@comment,User.current_user,mattertask)
        end
        notice ="#{t(:text_comment)} " "#{t(:flash_was_successful)} " "#{t(:text_saved)}"
        format.html {
          redirect_to :back
        }
        params[:id] = params[:comment][:commentable_id]
        params[:commentable_type] = params[:comment][:commentable_type]
        params[:from] = "create"
        add_comment_with_grid
        format.js {
          render :update do |page|
            page.replace_html("TB_ajaxContent", :partial => "common/comment");
            page << "jQuery('#comment_success_div').html(' <span class=\"icon_message_sucess fl mlr8 negativemt5\" ></span>#{notice}');"
            page << "jQuery('#comment_success_div').show();"
            page << "jQuery('#comment_success_div').animate({opacity: 1.0}, 5000);jQuery('#comment_success_div').fadeOut('slow');"
            unless params[:refresh_page].blank?
              page << "window.location.reload()"
            end
          end
        }
      else
        format.html {
          flash[:error]=t(:flash_comments_before_submitting)
          redirect_to :back
        }
        format.js {
          render :update do |page|
            errs = "<ul>" + @comment.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
            page << "jQuery('#comment_errors').html(\"#{errs}\");"
            page << "jQuery('#comment_errors').show();"           
            page << "jQuery('#comment_submit').show();"
            page << "jQuery('#disable_submit_tag').hide();"
            page << "jQuery('#cancel_btn').show();"
            page << "jQuery('#cancel_btn_hidden').hide();"
            page << "jQuery('#loader').hide();"
            
          end
        }
      end      
    end
  rescue ActiveRecord::RecordNotFound # Kicks in if commentable asset was not found.
    respond_to_related_not_found(params[:comment][:commentable_type].downcase, :js, :xml)
  end
  
  def add_new_comment
    if params[:comment].nil? or params[:comment].blank?
      render :text => "<div class='errorCont'>'#{t(:text_comment)} ' '#{t(:flash_not_blank)}'</div>"
      return
    end
    params.delete 'id' if params.key? 'id'
    params.delete 'controller' if params.key? 'controller'
    params.delete 'action' if params.key? 'action'
    params.delete 'locale' if params.key? 'locale'    
    unless params[:company_id].present?
      params.merge!(:company_id=>current_company.id)
    end
    comment = Comment.new(params)
    if comment.save      
      render :text => %Q!OK
        #{comment.title}|#{comment.comment}|#{comment.created_at.to_time.strftime('%m/%d/%y')}
      !
    else      
      render :text => "<div class='errorCont'>'#{t(:flash_comment_failed)}'</div>"
    end
  end

  def mark_read
    @comment = Comment.find(params[:id])
    if params[:newstatus].eql?("read")
      @comment.update_attribute(:is_read, true)
      render :partial => "physical/clientservices/home/client_comment_read", :locals => {:comment => @comment}
    else
      @comment.update_attribute(:is_read, false)
      render :partial => "physical/clientservices/home/client_comment_unread", :locals => {:comment => @comment}
    end
  end

  def order_rows
    params[:order] += params[:dir]
    col = Comment.scoped_by_commentable_type(params[:commentable_type]).scoped_by_commentable_id(params[:commentable_id]).find_with_deleted(:all, :include => :user, :order => params[:order])
    @comments = col.collect do |obj|
      [obj.title,obj.user.nil? ? '' : obj.user.try(:full_name),obj.comment,obj.created_at.to_time.strftime('%m/%d/%y %H:%M:%S')]
    end
    if params[:dir] == " asc"
      @icon = "sort_asc.png"
      params[:dir] = " desc"
    else
      @icon = "sort_desc.png"
      params[:dir] = " asc"
    end
    render :file => "comments/order_rows.js.erb"
  end

  def sort_rows
    col = Comment.scoped_by_commentable_type(params[:commentable_type]).scoped_by_commentable_id(params[:commentable_id]).find_with_deleted(:all, :include => :user)
    @comments = col.collect do |obj|
      [obj.title,obj.user.nil? ? '' : obj.user.try(:full_name),obj.comment,obj.created_at.to_time.strftime('%m/%d/%y %H:%M:%S')]
    end
    index = 1
    @comments.sort! do|a,b|
      if params[:dir] == " asc"
        a[index] <=> b[index]
      else
        b[index] <=> a[index]
      end
    end
    if params[:dir] == " asc"
      @icon = "sort_asc.png"
      params[:dir] = " desc"
    else
      @icon = "sort_desc.png"
      params[:dir] = " asc"
    end
    render :file => "comments/order_rows.js.erb"
  end

  def history
    sort_column_order
    @ord = @ord.nil? ? 'users.first_name DESC':@ord
    history = Comment.find_with_deleted(:all, :joins => [:user], :conditions=>{:commentable_type=>params[:commentable_type],:commentable_id=>params[:id]}, :order => @ord)
    render :partial=>'/common/history', :layout => false,:locals=>{:histories=>history}
  end

  def add_comment_with_grid
    case params[:commentable_type]
    when 'Account'
      object = current_company.accounts.find_with_deleted(params[:id])
    when 'Contact'
      object = Contact.scoped_by_company_id(current_company.id).find_with_deleted(params[:id])
    when 'Opportunity'
      object = current_company.opportunities.find_with_deleted(params[:id])
    when 'Matter'
      object = current_company.matters.find_with_deleted(params[:id])
    when 'MatterTask'
      object = MatterTask.find_with_deleted(params[:id])
    when 'MatterIssue'
      object = MatterIssue.find_with_deleted(params[:id])
    when 'MatterFact'
      object = MatterFact.find_with_deleted(params[:id])
    when 'MatterRisk'
      object = MatterRisk.find_with_deleted(params[:id])
    when 'MatterResearch'
      object = MatterResearch.find_with_deleted(params[:id])
    when 'Campaign'
      object = Campaign.find_with_deleted(params[:id])
    when 'UserTask'
      object = UserTask.find(params[:id])
    end
    if params[:commentable_type].eql?("MatterTask")      
      @notes = object.comments.all(:conditions => "title = 'Comment'").collect{|e| e if e.lawyer_can_see?(get_employee_user_id,object.matter.id, object, get_company_id)}      
    elsif params[:commentable_type].eql?('UserTask')
      if is_secretary_or_team_manager?
        @notes = object.comments.all(:order =>"created_at DESC")
      else
        @notes = object.comments.all(:conditions => "share_with_client = true", :order => "created_at DESC")
      end
    else
     sort_column_order
      @ord = @ord.nil? ? 'users.first_name DESC':@ord
      @notes = object.comments.find_with_deleted(:all, :joins =>[:user], :conditions => "title in ('Comment','Note')",:order =>@ord)
    end
    @comment = Comment.new
    @commentable = object
    @return_path = params[:path]
    unless params[:from].eql?('create')
      if params[:sort]
        render :partial => "tabular_listing", :locals => {:type => params[:commentable_type]}, :layout => false
      else
        render :partial => "common/comment", :locals => {:type => params[:commentable_type]}, :layout => false
      end
    end
  end

  private  
  def extract_commentable_name(params)
    commentable = (params.keys & COMMENTABLE).first
    commentable.sub("_id", "") if commentable
  end

  def update_commentable_session
    if params[:cancel] == "true"
      session.delete("#{@commentable}_new_comment")
    else
      session["#{@commentable}_new_comment"] = true
    end
  end
  
end
