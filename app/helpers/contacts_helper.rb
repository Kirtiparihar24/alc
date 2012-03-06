module ContactsHelper
  
  def rating_select(name, options = {})
    rating_str =  current_company.rating_type.lvalue
    rating_str = rating_str == "*" ? "&#9733;" : rating_str
    stars = (1..3).inject({}) { |hash, star| hash[star] = rating_str * star; hash }.sort
    options_for_select = %Q(<option value="0"#{options[:selected].to_i == 0 ? ' selected="selected"' : ''}>--None--</option>)
    options_for_select << stars.inject([]) {|array, star| array << %(<option value="#{star.first}"#{options[:selected] == star.first ? ' selected="selected"' : ''}>#{star.last}</option>); array }.join
    select_tag name, options_for_select, options
  end

  def contact_hover_link(contact)
    unless contact.nil?
      email = contact.email ? "<b>Email:</b> #{contact.email}" : ''
      phone = contact.phone ? "<b>Phone:</b> #{contact.phone}" : ''
      info = "#{email}<br/>#{phone}"
      return %Q{
            <span class="newtooltip">
              #{link_to(contact.full_name, edit_contact_path(contact))}
              <span class="newtooltip" style="display:none;">#{info}</span>
            </span>
            <div id="liquid-roundTT" class="tooltip" style="display:none;">
                <table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td width="10"><div class="top_curve_left"></div></td>
                  <td width="278"><div class="top_middle"><div class="ap_pixel11"></div></div></td>
                  <td width="12"><div class="top_curve_right"></div></td>
                </tr>
                <tr>
                  <td class="center_left"><div class="ap_pixel1"></div></td>
                  <td>
                     <div class="center-contentTT">
                      #{info}
                    </div>
                  </td>
                  <td class="center_right"><div class="ap_pixel1"></div></td>
                </tr>
                <tr>
                  <td valign="top"><div class="bottom_curve_left"></div></td>
                  <td><div class="bottom_middle"><div class="ap_pixel12"></div></div></td>
                  <td valign="top"><div class="bottom_curve_right"></div></td>
                </tr>
                </table>
            </div>
      }.html_safe!
    else
      ''
    end
  end

  def contact_comment
    "User #{@current_user.full_name.try(:titleize)} created <span color ='blue'> #{@contact.contact_stage.alvalue.try(:titleize)} #{@contact.full_name.titleize}</span>. Comment : #{params[:comment]}"
  end

  def check_contact_matter_people(contact)
    mtr_people = contact.matter_peoples.find_by_can_access_matter(true)
    return !mtr_people.blank?
  end
  
end
