# Feature 6407 - Supriya Surve - 9th May 2011
class CampaignMailerEmailsController < ApplicationController

  def create    
    @campaign_mailer_email = CampaignMailerEmail.new(params[:campaign_mailer_email])
    respond_to do |format|
      if @campaign_mailer_email.save
        flash[:notice] = 'Campaign Mailer Email id was successfully created.'
        format.html { redirect_to(company_settings_path) }
        format.xml  { render :xml => @campaign_mailer_email, :status => :created, :location => @campaign_mailer_email }
      else
        flash[:error] = @campaign_mailer_email.errors.full_messages
        format.html { redirect_to(company_settings_path(:campaign_mailer_email=>params[:campaign_mailer_email])) }
        format.xml  { render :xml => @campaign_mailer_email.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @campaign_mailer_email = CampaignMailerEmail.find(params[:id])
    render :layout=>false
  end

  def update
    @campaign_mailer_email = CampaignMailerEmail.find(params[:id])
    @campaign_mailer_email.attributes = params[:campaign_mailer_email]
    @campaign_mailer_email.valid?
    if @campaign_mailer_email.errors.empty?
      @campaign_mailer_email.save
    end    
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@campaign_mailer_email.errors.empty?
            company = @campaign_mailer_email.company
            @campaign_mailer_emails = company.campaign_mailer_emails
            page.replace_html('list', :partial =>"campaign_mailer_emails/list")
            page<< 'jQuery.facebox.close();'
            page<< "jQuery('a[rel*=facebox]').facebox();"
            page.call('common_flash_message_name_notice', "Campaign Mailer Email was successfully updated")
          else
            page.call('show_msg','nameerror',@campaign_mailer_email.errors.full_messages.to_s)
          end
        end
      }
    end
  end

end
