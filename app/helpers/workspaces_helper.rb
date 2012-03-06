module WorkspacesHelper
  def get_parent_row(folder)
    if folder
      return %Q{

         <tr class="#{cycle("bg1", "bg2")}">
                 <td >
               
                  </td>
                  <td>
                  <img src='/images/folder_close.png #{link_to('.....',folder_list_workspaces_path(:id=>folder.parent_id))}</td>
                  </td> <td> </td>
 <td> </td>
 <td style="text-align: center !important;"></td>
              </tr>}.html_safe!
    end
  end

  def get_folder_name(folder)
    if folder.present?
      truncate_hover(@folder.name ,15)
    else
      'ROOT FOLDER'
    end
  end

  def get_livian_access(folder,current_user)
    if current_user.role?('lawyer')
      if folder.livian_access
        return %Q{
          #{link_to("<div class='icon_lock_open mt3'></div>",'#',{:onclick=>"confirm_access(#{folder.id},0);return false;", :class=>"" , :title=> "Click to Lock"},  :id => "unlocked_image")}
        }.html_safe!
      else
        return %Q{
 #{link_to("<div class='icon_lock mt3'></div>",'#',{:onclick=>"confirm_access(#{folder.id}, 1);return false;", :class=>"" , :title=> "Click to Unlock"}, :id => "locked_image")}

        }.html_safe!
      end
    end
  end

  def access_image(folder,current_user)
    if current_user.role?('lawyer')
      if folder.livian_access
        return %Q{
          #{image_tag('/images/livia_portal/unlock.gif', { :border => 0, :hspace => "0"})}
        }.html_safe!
      else
        return %Q{
 #{image_tag('/images/livia_portal/lock.gif', {:border => 0, :hspace => "0"})}
        }.html_safe!
      end
    end
  end
  
end
