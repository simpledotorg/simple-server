class DeleteBangladeshDemoFacility
  REAL_PATIENT_IDS= %w[
    9bb850d0-f5c8-4e25-9be5-3009b3fef6e9 3d414801-8a29-47fb-829a-0f458e3305a8 bcbf62b9-3ab7-4016-9569-bbe301438fab
    69993b18-8f0b-4ee3-8518-34b0cfb506ac 59824f20-3151-4a4e-a87f-12af27634e5f 7feecba3-6373-4070-a4cb-a87465f0d0b7
    957774df-9474-4faa-ac64-ba4b04fafd42 e81d68ad-42e0-488b-8b88-351249924497 9d322959-0664-4e5a-8779-9d37e6d90ae5
    41b0c483-c1ac-47bd-bc9d-0d2bccd032ff 50b89bf9-81f9-45ba-ab00-ba6a195a4405 d4f8a018-97ee-4356-929b-9ed643ec73bf
    4e3f9f73-4bf3-404e-b80b-3b6f51c88cbe 0a3d475c-deb5-4d18-939e-b1d0daa9a448 948d8a27-b202-41ef-8850-e29211d0b009
    721271c4-bcf6-4634-8ec3-fc1a454a2011 090b7a39-59d5-4190-a57c-02473618f006 77f00ec2-9483-4361-ab87-f9ac2bc29880
    d6e045d0-6ea0-4642-bf69-dfb33aa90518 65062d24-993d-4641-8396-df7028ea0a2e df910915-6e37-4d17-b201-f927ee6a0321
    0294e0d4-7f01-40b1-8974-d32b2c9b6895 bff39e72-deb5-483c-9938-a42c0a824dc7 1a8b5edc-0d76-4771-8dcb-de5fc0e6beb9
    8693955f-e597-4300-a307-b640d1c3eb25 78dcc832-863a-4c61-b141-303ab2c123d6 d9ee260a-df08-423c-b5b2-0c7da025d76a
    9a6c7f32-f04e-4922-ba0f-e169786643a6 9199242a-d470-435a-b30b-71c2a307fc05 9084c8e6-f2ed-4672-bd3f-4dd12a7c46d3
    355a4c8b-691a-4bd9-8fa2-2cfc5a1e2b71 30bbfdd7-a02e-49ab-a732-01a4b1868193 d33ecd72-5c4f-4a0f-a4b8-1d6fbce26b4a
    a54a2254-4cbc-4c22-b8c0-88d96a6db18d 09091bdc-2be5-49c9-b0cf-6e4e4821c3ab cf3e3356-6861-4a35-8f94-b65c17608456
    10045a89-412a-469d-80ba-f3147bd4c491 9f44e3f5-d37b-4749-9392-d1ee69b086aa 367a6c26-0650-4ed8-8b10-f59e91f7b7ed
    63f4502e-c5d0-4e9f-b911-8db515a891c1 f5817166-3211-489b-a00f-6bd82bb712a9 2c92f2c0-e9b7-4856-96ca-2fa52cc98388
    c0d90c86-287d-4f9e-88e3-8e43b1ef009c 6b32512c-e208-435d-aeb6-36147b976fdc b8ce634c-fc41-4819-b822-e3110f090423
    4bc49fae-ffb0-493e-9020-989d25481f4b bd21264b-8c4f-412e-9328-e31606c9af67 5ab68241-490c-44ec-afea-0c00e33b42e7
    0c72b76e-1d98-48be-8cb7-ae1c57dde0c6 9475d4da-e220-4f27-8961-b6fea0c0481e e350d0ac-66c6-4c34-af6b-aa533438e5a2
    279ae0c0-33c1-490e-9c52-92f3143d2464 4d9c5b98-5ddc-4dbf-9479-8c73af509c10 bc25422f-921b-4304-9888-c1a636b93de4
    daeebf54-0785-4165-9ab3-76374d4cb686 f338fd7e-3258-469b-9e6a-cd5c7d3e1e74 1162272c-190f-45c4-b6f7-a877fceed28c
    13a746ac-46c6-4d3f-96aa-aa6d7996b621
  ].freeze

  def self.call(*args)
    new(*args).call
  end

  attr_reader :verbose, :dryrun

  def initialize(verbose: true, dryrun: false)
    @verbose = verbose
    @dryrun = dryrun
  end

  def call
    log "Moving real patients to Beanibazar..."
    move_real_patients_to_beanibazar

    log "Discarding test patients..."
    discard_test_patients

    log "Discarding demo facility..."
    discard_demo_facility

    log "Complete. Goodbye."
  end

  private

  def move_real_patients_to_beanibazar
    real_patients.update(registration_facility: beanibazar)
  end

  def discard_test_patients
    demo_facility.reload.patients.each(&:discard_data)
  end

  def discard_demo_facility
    demo_facility.discard
  end

  def real_patients
    @real_patients ||= Patient.where(id: REAL_PATIENT_IDS)
  end

  def beanibazar
    @beanibazar ||= Facility.find_by!(name: "UHC Beanibazar")
  end

  def demo_facility
    @demo_facility ||= Facility.find_by!(name: "Demo Hospital")
  end

  def log(message)
    puts message if verbose
  end
end
