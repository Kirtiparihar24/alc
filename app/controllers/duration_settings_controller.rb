# Feature 10282 - Rahul P. - 17th Nov 2011
class DurationSettingsController < ApplicationController

 
  def edit
    @duration_setting = DurationSetting.find(params[:id])
    render :layout=>false
  end

  def update
    @duration_setting = DurationSetting.find(params[:id])
    @duration_setting.update_attributes(params[:duration_setting])
    respond_to do |format|
      format.js 
    end
  end

end
