module FileUploadable
  extend ActiveSupport::Concern

  VALID_MIME_TYPES = %w[text/csv application/vnd.openxmlformats-officedocument.spreadsheetml.sheet].freeze

  def read_xlsx_or_csv_file(file)
    file_contents = ""
    if file.content_type == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      xlsx = Roo::Spreadsheet.open(file.path)
      file_contents = xlsx.to_csv
    elsif file.content_type == "text/csv"
      file_contents = file.read
    end
  end

  def initialize_upload
    @errors = []
    @file = params.require(:file)
  end

  def validate_file_type
    @errors << "File type not supported, please upload a csv or xlsx file instead" if
        VALID_MIME_TYPES.exclude?(@file.content_type)
  end

  def validate_file_size
    @errors << "File is too big, must be smaller than 5MB" if @file.size > 5.megabytes
  end
end
