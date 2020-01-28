require File.expand_path('../../../config/boot',  __FILE__)
require 'roo'

from = File.expand_path('../data/bangladesh.xlsx',  __FILE__)
to = File.expand_path('../data/bangladesh.csv',  __FILE__)

spreadsheet = Roo::Spreadsheet.open(from)
sheet = spreadsheet.sheet(spreadsheet.sheets.first)

first_row = sheet.first_row
last_row = sheet.last_row
first_column = sheet.first_column
last_column = sheet.last_column

CSV.open(to, 'w') do |csv|
  (first_row..last_row).each do |row|
    row_data = sheet.row(row)[first_column..last_column]

    csv << row_data
  end
end
