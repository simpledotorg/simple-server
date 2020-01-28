require File.expand_path('../../../config/boot',  __FILE__)
require 'csv'

from = File.expand_path('../data/bangladesh.csv',  __FILE__)
to = File.expand_path('../data/patients.csv',  __FILE__)

data = CSV.parse(File.open(from), headers: true)

CSV.open(to, 'w') do |csv|
  (0...data.length).each do |row|
    csv << ["patient_key", row]
    data[row].headers.each_with_index do |header, index|
      value = data[row][index]
      csv << [header, value] if value
    end
  end
end
