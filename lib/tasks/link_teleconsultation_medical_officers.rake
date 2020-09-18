require "tasks/scripts/link_teleconsultation_medical_officers"

desc "Link teleconsult MOs to facilities"
task link_teleconsultation_medical_officers: :environment do
  LinkTeleconsultationMedicalOfficers.call
end
