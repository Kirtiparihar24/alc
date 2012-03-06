module Paperclip
  module Interpolations
    # Returns the basename of the file. e.g. "file" for "file.jpg"
    # Escapes the speical characters (which have different meaning in RegEx)
    def basename attachment, style_name
      orig_fname = attachment.original_filename
      orig_fname.gsub!('(', '')
      orig_fname.gsub!(')', '')
      orig_fname.gsub(/#{File.extname(orig_fname)}$/, "")
    end
  end
end

