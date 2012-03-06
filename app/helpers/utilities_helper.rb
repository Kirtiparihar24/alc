module UtilitiesHelper
  def truncate_withscroll_utility(name, str, length)
    if str.length > length
      return %Q{
      <div class="newtooltip">#{name}</div>
      <div id="liquid-roundTT" class="tooltip" style="display:none; padding:0;margin:0;">
          <table width="100%" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td width="10" style="padding:0; margin:0;"><div class="top_curve_left"></div></td>
              <td width="278" style="padding:0; margin:0;"><div class="top_middle"><div class="ap_pixel11"></div></div></td>
              <td width="12" style="padding:0; margin:0;"><div class="top_curve_right"></div></td>
            </tr>
            <tr>
              <td  width="10" class="center_left" style="padding:0; margin:0;"><div class="ap_pixel1"></div></td>
              <td width="278" style="padding:0; margin:0;">
                 <div class="center-contentTT">
                  #{str}
                </div>
              </td>
              <td width="12" class="center_right" style="padding:0; margin:0;"><div class="ap_pixel1"></div></td>
            </tr>
            <tr>
              <td  width="10" valign="top" style="padding:0; margin:0;"><div class="bottom_curve_left"></div></td>
              <td width="278" style="padding:0; margin:0;"><div class="bottom_middle"><div class="ap_pixel12"></div></div></td>
              <td  width="12" valign="top" style="padding:0; margin:0;"><div class="bottom_curve_right"></div></td>
            </tr>
          </table>
        </div>
      }
    else
      return %Q{ #{str} }
    end
  end
end
