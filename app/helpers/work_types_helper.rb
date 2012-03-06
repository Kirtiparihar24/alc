module WorkTypesHelper
  def render_work_type_links
    if params[:filter]
      case params[:filter]
      when "Back Office"
        return %Q{&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;#{link_to("#{t(:text_view_all_worktypes)}", work_types_path())}
        |&nbsp;&nbsp;&nbsp;#{link_to("#{t(:text_view_livian_worktypes)}", work_types_path(:filter =>'Livian'))}}.html_safe!
      when "Livian"
        return %Q{&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;#{link_to("#{t(:text_view_all_worktypes)}", work_types_path())}
        |&nbsp;&nbsp;&nbsp;#{link_to("#{t(:text_view_backoffice_worktypes)}", work_types_path(:filter =>'Back Office'))}}.html_safe!
      end
    else
      return %Q{&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;#{link_to("#{t(:text_view_livian_worktypes)}", work_types_path(:filter =>'Livian'))}
      |&nbsp;&nbsp;&nbsp;#{link_to("#{t(:text_view_backoffice_worktypes)}", work_types_path(:filter =>'Back Office'))}}.html_safe!
    end
  end
end