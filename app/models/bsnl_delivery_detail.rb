class BsnlDeliveryDetail < DeliveryDetail
  enum message_status: {
    :created => "0",
    :input_error => "1",
    :inserted_in_queue => "2",
    :submitted_to_smsc => "3",
    :rejected_by_smsc => "4",
    :accepted_by_carrier => "5",
    :delivery_failed => "6",
    :delivered => "7"
  }

  def unsuccessful?
    input_error? || rejected_by_smsc? || delivery_failed?
  end

  def successful?
    delivered?
  end

  def in_progress?
    created? || inserted_in_queue? || submitted_to_smsc? || accepted_by_carrier?
  end
end
