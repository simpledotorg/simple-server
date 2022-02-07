class NhfStudyExportScript < DataScript
  attr_reader :logger

  def self.call(*args)
    new(*args).call
  end

  def initialize(dry_run: true)
    super(dry_run: dry_run)

    fields = {module: :data_script, class: self.class}
    @logger = Rails.logger.child(fields)
  end

  def call
    patients = Patient.where("full_name ILIKE ? OR full_name ILIKE ?", "%XYZ", "%XYX")

    csv = PatientsWithHistoryExporter.csv(patients, display_blood_pressures: 12)

    File.open(File.join(Rails.root, "nhf_study_line_list.csv"), "w") do |f|
      f.write(csv)
    end
  end
end
