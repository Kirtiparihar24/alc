# To change this template, choose Tools | Templates
# and open the template in the editor.

module CommunicationsHelper
  
  # Below helper is used in header_tabs layouts.
  def get_communications_link_path
    unless session[:service_session].nil?
      new_communication_path
    else
      physical_liviaservices_livia_secretaries_url
    end
  end
  
end