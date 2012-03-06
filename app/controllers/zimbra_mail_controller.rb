class ZimbraMailController < ApplicationController
  before_filter :authenticate_user!  
  require 'openssl'
  require 'digest'
  require 'digest/sha1'
  add_breadcrumb I18n.t(:text_mail), :zimbra_mail_index_path

  layout 'application'

  authorize_resource :class => :zimbra_mail

  def index
    begin
      if params[:app].eql?("contacts")
        @pagenumber=200
      else
        @pagenumber=9
      end
      params[:portal_loc]=request.host
      @email_id = get_lawyer_email_for_mail.to_s.strip
      @email_id =  "mdickinson@mdick.liviaservices.com" if @email_id.eql?("mkd@ddiplaw.com")
      tmpparams=''
      params.each do |key, value|
        tmpparams=tmpparams +"&#{key}=#{value}" if params[key].present?
      end
      @url1 = generate_url(@email_id,tmpparams)
      authorize!(:index,current_user) unless current_user.has_access?(:Mail)
      if params[:app]=="calendar"
        render :layout => 'calendars'
      end
    rescue => e
      flash[:error] = "Your email is not configured yet. Please contact Livia Helpdesk."
      redirect_to :back
    end
  end

  def savefiletoportal
    render :layout=> false
  end


  def business_contacts
    params[:portal_loc]=request.host
    @email_id = get_lawyer_email.to_s.strip
    @email_id =  "mdickinson@mdick.liviaservices.com" if @email_id.eql?("mkd@ddiplaw.com")

    tmpparams=''
    params.each do |key, value|
      tmpparams=tmpparams +"&#{key}=#{value}" if params[key].present?
    end
    @url2 = generate_url_contact(@email_id,'?app=Contacts')
    domain = get_domain(@email_id)
    key = get_key(domain)
    status =false
    authorize!(:business_contacts,current_user) unless current_user.has_access?(:Mail)

  end

  def generate_url_contact(email_id,params)
    domain = get_domain(email_id)
    @time_stamp = get_timestamp
    preauth_value = (get_key(domain) && get_url(domain))? compute_preauth(email_id, @time_stamp, get_key(domain)): nil
    url = preauth_value ? "#{get_url(domain)}/service/preauth?account=#{email_id}&expires=0&timestamp=#{@time_stamp}&preauth=#{preauth_value}" : nil
    url=url+params
    return url
  end


  private

  def compute_preauth(name, time_stamp, key)
    plaintext="#{name}|name|0|#{time_stamp}"
    hmacd=OpenSSL::HMAC.new(key,OpenSSL::Digest::Digest.new('sha1'))
    hmacd.update(plaintext)
    return hmacd.to_s
  end

  def get_timestamp
    time_stamp = (((Time.zone.now.to_f.to_i)*1000)+1000)
    return time_stamp
  end

  def get_key(domain)
    zc = ZimbraConfig.find(:domain=>domain).first
    key = zc ? zc.domain_key : nil
  end

  def get_url(domain)
    zc = ZimbraConfig.find(:domain=>domain).first
    url = zc ? zc.url : nil
  end

  def get_domain(email_id)
    domain = email_id.split('@')[1]
    return domain
  end

  def generate_url(email_id,params)
    domain = get_domain(email_id)
    @time_stamp = get_timestamp
    preauth_value = (get_key(domain) && get_url(domain))? compute_preauth(email_id, @time_stamp, get_key(domain)): nil
    url = preauth_value ? "#{get_url(domain)}/service/preauth?account=#{email_id}&expires=0&timestamp=#{@time_stamp}&preauth=#{preauth_value}" : nil
    url=url+params
    return url
  end

  def get_lawyer_email_for_mail
    if is_secretary_or_team_manager?
      current_service_session.assignment.nil? ? current_service_session.user.email : current_service_session.assignment.user.email
    else
      current_user.email
    end
  end
  
end
