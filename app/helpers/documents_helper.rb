module DocumentsHelper

  def get_privilege(id)
    privilege = CompanyLookup.find(id) unless id.blank?
    privilege.blank? ? '' : (privilege.lvalue != "Not privileged") ? "<span class='icon_privilaged_indicator fl mt3 vtip' title='Privilege'></span>" : ''
  end

end
