class OneOff::CPHCEnrollment::Demo
  attr_reader :service

  def initialize
    @service = CPHCEnrollment::Service.new
  end

  def start(count = 5, offset = 0)
    time = Time.now
    patients = ::Patient.all.limit(count).offset(offset)
    encounter_counts = []
    patients.each_with_index do |patient, index|
      encounter_counts << patient.encounters.count
      print "Sending information for Patient (#{index + 1}/#{count}): #{patient.full_name}... "
      STDOUT.flush
      service.call(patient)
      puts "Done!\n"
    end

    puts "Sent #{encounter_counts.sum} encounters for #{patients.count} patients in #{Time.now - time} seconds"
  end
end
