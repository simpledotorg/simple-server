class Api::V1::AppointmentTransformer < Api::Current::Transformer
  class << self
    def new_keys_mapping
      { invalid_phone_number: :other,
        public_hospital_transfer: :other,
        moved_to_private: :other }.with_indifferent_access
    end

    def to_response(model)
      h =  model.attributes.with_indifferent_access
      h[:cancel_reason] = new_keys_mapping[h[:cancel_reason]]
      h
    end
  end
end