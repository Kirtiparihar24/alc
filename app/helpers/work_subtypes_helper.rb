module WorkSubtypesHelper
  def fields_for_work_subtype_complexity(work_subtype_complexity, &block)
    prefix = work_subtype_complexity.new_record? ? 'new' : 'existing'
    fields_for("work_subtype[#{prefix}_work_subtype_complexity_attributes][]", work_subtype_complexity, &block)
  end

  def add_work_subtype_complexity_link(name)
    link_to_function name do |page|
      page.insert_html :bottom, :complexity_div, :partial => 'complexity' , :object => WorkSubtypeComplexity.new,:locals=>{:from=>"add"}
    end
  end

  def render_work_subtype_links
    if params[:filter]
      case params[:filter]
      when "Back Office"
        return %Q{&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;#{link_to("#{t(:text_view_all_work_subtypes)}", work_subtypes_path())}
        |&nbsp;&nbsp;&nbsp;#{link_to("#{t(:text_view_livian_work_subtypes)}", work_subtypes_path(:filter =>'Livian'))}}.html_safe!
      when "Livian"
        return %Q{&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;#{link_to("#{t(:text_view_all_work_subtypes)}", work_subtypes_path())}
        |&nbsp;&nbsp;&nbsp;#{link_to("#{t(:text_view_backoffice_work_subtypes)}", work_subtypes_path(:filter =>'Back Office'))}}.html_safe!
      end
    else
      return %Q{&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;#{link_to("#{t(:text_view_livian_work_subtypes)}", work_subtypes_path(:filter =>'Livian'))}
      |&nbsp;&nbsp;&nbsp;#{link_to("#{t(:text_view_backoffice_work_subtypes)}", work_subtypes_path(:filter =>'Back Office'))}}.html_safe!
    end
  end

end
