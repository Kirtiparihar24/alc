class LiviaMailer < ActionMailer::Base

  def send_company_creation_details_mail(url,cc, to,email)
    @subject    = "Creation of " + email[:company_name] + " in Livia Portal"
    @body       = {}
    @recipients = "venu.gopal@livialegal.com"
    #@cc = cc
    @from       = ENV["HOST_NAME"].include?('liviaservices') ? "noreply@liviaservices.com" : "support.test@liviatech.com"
    @content_type = "text/html"
    @sent_on = Time.zone.now.to_date
    @body[:email] = email
    @body[:logo_img] = "<img src='#{url}/images/livia_portal/login_logo.gif'/>"
  end

  def send_user_login_details_mail(url,cc,to,email)
    @subject    = "Creation of new login in Livia Portal"
    @body       = {}
    @recipients = "venu.gopal@livialegal.com"
    #@cc = cc
    @from       = ENV["HOST_NAME"].include?('liviaservices') ? "noreply@liviaservices.com" : "support.test@liviatech.com"
    @content_type = "text/html"
    @sent_on = Time.zone.now.to_date
    @body[:email] = email
    @body[:logo_img] = "<img src='#{url}/images/livia_portal/login_logo.gif'/>"
  end

  def licence_assign_unassign_deactivate_mail(url,cc,to,subject,email)
    @subject    = subject
    @body       = {}
    @recipients = "venu.gopal@livialegal.com"
    #@cc = cc
    @from       = ENV["HOST_NAME"].include?('liviaservices') ? "noreply@liviaservices.com" : "support.test@liviatech.com"
    @content_type = "text/html"
    @sent_on = Time.zone.now.to_date
    @body[:email] = email
    @body[:logo_img] = "<img src='#{url}/images/livia_portal/login_logo.gif'/>"
  end

  def service_provider_assignment_unassignment_mail(url,cc,to,subject,email)
    @subject    = subject
    @body       = {}
    @recipients = "venu.gopal@livialegal.com"
    #@cc = cc
    @from       = ENV["HOST_NAME"].include?('liviaservices') ? "noreply@liviaservices.com" : "support.test@liviatech.com"
    @content_type = "text/html"
    @sent_on = Time.zone.now.to_date
    @body[:email] = email
    @body[:logo_img] = "<img src='#{url}/images/livia_portal/login_logo.gif'/>"
  end


  def licences_purchase_mail(url,cc,to,subject,email)
    @subject    = subject
    @body       = {}
    @recipients = "venu.gopal@livialegal.com"
    #@cc = cc
    @from       = ENV["HOST_NAME"].include?('liviaservices') ? "noreply@liviaservices.com" : "support.test@liviatech.com"
    @content_type = "text/html"
    @sent_on = Time.zone.now.to_date
    @body[:email] = email
    @body[:logo_img] = "<img src='#{url}/images/livia_portal/login_logo.gif'/>"
  end

  def modules_assignment_unassignment_mail(url,cc,to,subject,email)
    @subject    = subject
    @body       = {}
    @recipients = "venu.gopal@livialegal.com"
    #@cc = cc
    @from       = ENV["HOST_NAME"].include?('liviaservices') ? "noreply@liviaservices.com" : "support.test@liviatech.com"
    @content_type = "text/html"
    @sent_on = Time.zone.now.to_date
    @body[:email] = email
    @body[:logo_img] = "<img src='#{url}/images/livia_portal/login_logo.gif'/>"
  end
end
