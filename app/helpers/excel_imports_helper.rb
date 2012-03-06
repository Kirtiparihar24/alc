module ExcelImportsHelper
  def set_col_ratio(module_type)
    if module_type == "contact"
      "[300, 190, 100, 110, 155, 110, 110, 110, 110, 110, 75, 115, 115, 75, 75, 155, 155, 80, 70, 75, 75, 75, 75, 75, 75, 75, 155, 155, 75, 75, 75, 155, 70, 190, 75, 75, 75, 155, 70, 190]"
    elsif module_type == "time"
      "[300, 170, 230, 170, 250, 200, 200, 90, 120, 210, 150, 200, 150,150]"
    elsif module_type == "expense"
      "[300, 170, 230, 170, 250, 200, 200, 200, 200, 210, 200, 200, 200,200]"
    elsif module_type == "matter"
      "[300, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200,200]"
    elsif module_type == "campaign_member"
      "[150, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200,200,100,100,100]"
    end
  end

  def format_module_name(module_name)
    module_name.gsub("_"," ").capitalize
  end
end
