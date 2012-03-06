class ZimbraActivitiesController < ApplicationController
  # GET /zimbra_activities
  # GET /zimbra_activities.xml
  skip_before_filter :verify_authenticity_token

  def create
    data = params
    unless data[:lawyer_email].blank?
      usr = User.find_by_email(data[:lawyer_email])
      @company = @company || usr.company
    else
      @company = @company || current_company
    end
    if data['category'].eql?("appointment")
      from_zimbra = true unless data[:mode].blank?
      data = ZimbraActivity.zimbra_appointment_params(data)
      assigned_to_id, companyid = ZimbraActivity.get_user_id(data[:lawyer_email])
      data.delete(:future_instance)
      data.delete(:lawyer_email)
      data.delete(:task_id)
      data.delete(:mode)
      @zimbra_activity = ZimbraActivity.new(data)
      @zimbra_activity.assigned_to_user_id = assigned_to_id
      @zimbra_activity.company_id = @company.id
      @zimbra_activity.from_zimbra = true if from_zimbra
      if @zimbra_activity.save
        render :xml=>{:success => "Activity is sucessfully updated"}
      else
        render :xml=>{:error => @zimbra_activity.errors}
      end
    elsif data['category'].eql?("todo")
      assigned_to_id, companyid = ZimbraActivity.get_user_id(data[:lawyer_email])
      data = ZimbraActivity.zimbra_task_params(data)
      @zimbra_activity = ZimbraActivity.new(data)
      @zimbra_activity.assigned_to_user_id = assigned_to_id
      @zimbra_activity.company_id = @company.id
      if @zimbra_activity.save!
        render :xml=>{:success => "Activity is sucessfully created"}
      else
        render :xml=>{:error => @zimbra_activity.errors}        
      end
    else
      @zimbra_activity = ZimbraActivity.new(data[:zimbra_activity])
      if data[:zimbra_activity][:start_date_appointment].present?
        sd = Time.zone.parse(data[:zimbra_activity][:start_date_appointment] + ' ' + data[:zimbra_activity][:start_time]).getutc
        ed = Time.zone.parse(data[:zimbra_activity][:end_date_appointment] + ' ' + data[:zimbra_activity][:end_time]).getutc
        @zimbra_activity.start_date_appointment = sd
        @zimbra_activity.end_date_appointment = ed
      end
      if data[:zimbra_activity] [:category].eql?('todo')
        @zimbra_activity.start_date_todo =Time.zone.parse(data[:zimbra_activity][:start_date_todo] + ' 12:00 PM') if !data[:zimbra_activity][:start_date_todo].blank?
        @zimbra_activity.end_date_todo =Time.zone.parse(data[:zimbra_activity][:end_date_todo] + ' 12:00 PM') if !data[:zimbra_activity][:end_date_todo].blank?
      end
      @zimbra_activity.company_id = @company.id
      @zimbra_activity.assigned_to_user_id = get_employee_user.id
      respond_to do |format|
        if @zimbra_activity.save
          flash[:notice] = 'Activity was successfully created.'
          format.js{
            render :update do |page|
              page << "tb_remove();"
              page << "window.location.reload();"
            end
          }
        else
          format.js{
            render :update do |page|
              format_ajax_errors(@zimbra_activity, page, 'zimbra_activities_errors')
              page << "jQuery('#loadingimg').hide();"
              page << "enableAllSubmitButtons('modal_activity');"
              page<<"jQuery('#loader').hide();"
            end
          }
        end
      end
    end
  end

  # PUT /zimbra_activities/1
  # PUT /zimbra_activities/1.xml
  def update
    data = params
    @zimbra_activity = ZimbraActivity.find(data[:id])
    data[:zimbra_activity][:start_time] = Time.parse(data[:zimbra_activity][:start_time]).strftime("%I:%M %p")
    data[:zimbra_activity][:end_time] = Time.parse(data[:zimbra_activity][:end_time]).strftime("%I:%M %p")

    if data[:zimbra_activity][:start_date_appointment].present?
      data[:zimbra_activity][:start_date_appointment] = Time.zone.parse(data[:zimbra_activity][:start_date_appointment] + ' ' + data[:zimbra_activity][:start_time])
      data[:zimbra_activity][:end_date_appointment] = Time.zone.parse(data[:zimbra_activity][:end_date_appointment] + ' ' + data[:zimbra_activity][:end_time])

    end
    if data[:zimbra_activity] [:category].eql?('todo')
      data[:zimbra_activity][:start_date_todo] =Time.zone.parse(data[:zimbra_activity][:start_date_todo] + ' 12:00 PM')
      data[:zimbra_activity][:end_date_todo] =Time.zone.parse(data[:zimbra_activity][:end_date_todo] + ' 12:00 PM')
    end
    data[:request_from].present?? @request_from = data[:request_from] : @request_from = nil
    respond_to do |format|
      if @zimbra_activity.update_attributes(data[:zimbra_activity].merge!({:zimbra_status => true}))
        flash[:notice] = 'Activity was successfully updated.'
        format.js{
          render :update do |page|
            page << "tb_remove();"
            page << "window.location.reload();"
          end
        }
      else
        format.js{
          render :update do |page|
            format_ajax_errors(@zimbra_activity, page, 'zimbra_activities_errors')
            page << "jQuery('#loadingimg').hide();"
          end
        }
      end
    end
  end

  # DELETE /zimbra_activities/1
  # DELETE /zimbra_activities/1.xml
  def destroy
    @zimbra_activity = ZimbraActivity.find(params[:id])
    @zimbra_activity.destroy
    respond_to do |format|
      flash[:notice] = "Activity was deleted successfully."      
      format.js{
        render :update do |page|
          page << "tb_remove();"
          page << "window.location.reload();"
        end
      }
      format.html{redirect_to :back}
      format.xml  { head :ok }
    end
  end
  
end
