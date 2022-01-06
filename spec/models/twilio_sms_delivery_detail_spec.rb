# frozen_string_literal: true

require "rails_helper"

describe TwilioSmsDeliveryDetail, type: :model do
  subject(:twilio_sms_delivery_detail) { create(:twilio_sms_delivery_detail) }

  describe "Associations" do
    it { should have_one(:communication) }
  end
end
