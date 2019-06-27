module FileUploadable
  extend ActiveSupport::Concern

  def read_xlsx_or_csv_file(file)
    file_contents = ''
    if file.content_type == 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      xlsx = Roo::Spreadsheet.open(file.path)
      file_contents = xlsx.to_csv
    elsif file.content_type == 'text/csv'
      file_contents = file.read
    end
  end
end