namespace :seed do
  desc 'Add punjab hypertension protocol'
  task protocols: :environment do
    protocol_data = {
      name:           'Punjab Hypertension Protocol',
      follow_up_days: 30
    }

    protocol_drugs_data = [
      {
        name:   'Amlodipine',
        dosage: '5 mg'
      },
      {
        name:   'Amlodipine',
        dosage: '10 mg'
      },
      {
        name:   'Telmisartan',
        dosage: '40 mg'
      },
      {
        name:   'Telmisartan',
        dosage: '80 mg'
      },
      {
        name:   'Chlorthalidone',
        dosage: '12.5 mg'
      },
      {
        name:   'Chlorthalidone',
        dosage: '25 mg'
      }
    ]

    protocol = Protocol.create(protocol_data)
    protocol_drugs_data.each do |drug_data|
      ProtocolDrug.create(drug_data.merge(protocol_id: protocol.id))
    end
  end
end
