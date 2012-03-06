module ImportHistoriesHelper
  def link_to_orig_filename(import_history)
    if import_history.original_filename.present?  
      link_to("import_history.original_filename",download_original_import_file_path(import_history))
    end
  end
  def link_to_error_filename(import_history)
    if import_history.error_filename.present?  
      link_to("import_history.error_filename",download_invalid_import_file_path(import_history))
    end
  end
  def display_valid_record(import_history)
    import_history.valid_records ? import_history.valid_records : 0
  end
  def display_invalid_record(import_history)
    import_history.invalid_records ? import_history.invalid_records : 0
  end
  def display_total_record(import_history)
    display_valid_record(import_history)+display_invalid_record(import_history)
  end
end
