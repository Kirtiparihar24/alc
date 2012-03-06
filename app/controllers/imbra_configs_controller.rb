class ZimbraConfigsController < ApplicationController

  layout 'admin'

  def index
    @zimbra_configs = ZimbraConfig.all
  end

  def create
    @zimbra_config = ZimbraConfig.create(:domain=>params[:domain],:url=>params[:url],:domain_key=>params[:domain_key])
    redirect_to zimbra_configs_path
  end

  def modify
    field = params[:id].split("_")
    id = field.pop
    field = field.join("_")
    @zimbra_config = ZimbraConfig[id]
    @zimbra_config.update(field=>params[:value]) if @zimbra_config
    value = @zimbra_config.send(field)
    render :text=>value
  end

end
