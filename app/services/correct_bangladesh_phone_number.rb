class CorrectBangladeshPhoneNumber
  def self.perform(patient)
    new(patient).perform
  end

  attr_reader :patient

  def initialize(patient)
    @patient = patient
  end

  def perform
    return unless Rails.application.config.country[:name] == 'Bangladesh'

    patient.phone_numbers.each do |phone_number|
      phone_number.update!(number: correct(phone_number.number))
    end
  end

  def correct(number)
    new_number = number

    new_number = new_number.start_with?('0') ? new_number : "0#{new_number}"
    new_number.gsub!('-', '')

    new_number
  end
end
