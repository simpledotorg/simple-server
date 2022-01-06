# frozen_string_literal: true

require "rails_helper"

describe ApplicationHelper, type: :helper do
  context "page_title" do
    after { ENV["SIMPLE_SERVER_ENV"] = "test" }

    it "defaults to prefix and default title if no explicit title is set" do
      expect(helper.page_title).to eq("[TEST] Simple Dashboard")
      stub_const("SIMPLE_SERVER_ENV", "sandbox")
      ENV["SIMPLE_SERVER_ENV"] = "sandbox"
      expect(helper.page_title).to eq("[SBX] Simple Dashboard")
    end

    it "uses page_title content when set" do
      helper.content_for(:title) { "My Custom Title" }
      expect(helper.page_title).to eq("[TEST] My Custom Title")
    end

    it "has no prefix in production" do
      ENV["SIMPLE_SERVER_ENV"] = "production"
      helper.content_for(:title) { "My Custom Title" }
      expect(helper.page_title).to eq("My Custom Title")
    end
  end

  describe "#bootstrap_class_for_flash" do
    specify { expect(helper.bootstrap_class_for_flash("success")).to eq("alert-success") }
    specify { expect(helper.bootstrap_class_for_flash("error")).to eq("alert-danger") }
    specify { expect(helper.bootstrap_class_for_flash("alert")).to eq("alert-warning") }
    specify { expect(helper.bootstrap_class_for_flash("notice")).to eq("alert-primary") }
    specify { expect(helper.bootstrap_class_for_flash("something-else")).to eq("something-else") }
  end

  describe "#display_date" do
    let(:date) { Date.new(2020, 1, 15) }

    it "returns a standard formatted date" do
      expect(helper.display_date(date)).to eq("15-JAN-2020")
    end

    context "when date is nil" do
      let(:date) { nil }

      it "returns nil" do
        expect(helper.display_date(date)).to eq(nil)
      end
    end
  end

  describe "#rounded_time_ago_in_words" do
    it "should return Today if date is less than 24 hours" do
      date = Date.current
      expect(helper.rounded_time_ago_in_words(date)).to eq("Today")
    end

    it "should return Yesterday if date is from yesterday" do
      date = Date.yesterday
      expect(helper.rounded_time_ago_in_words(date)).to eq("Yesterday")
    end

    it "should return date in dd-MMM-yyyy format if date is more than a day ago" do
      date = Date.parse("31-12-2016")
      expect(helper.rounded_time_ago_in_words(date)).to eq("on 31-DEC-2016")
    end
  end

  describe "#handle_impossible_registration_date" do
    before :each do
      allow(ENV).to receive(:[]).with("PROGRAM_INCEPTION_DATE").and_return("2018-01-01")
    end

    it "returns the formatted registraion data if it is greater than the program inception date" do
      expect(helper.handle_impossible_registration_date(Date.new(2019, 0o1, 0o1))).to eq("01-JAN-2019")
    end

    it "returns 'unclear' if the date is lesser than the program inception date" do
      expect(helper.handle_impossible_registration_date(Date.new(2017, 0o1, 0o1))).to eq("Unclear")
    end
  end

  describe "#show_last_interaction_date_and_result" do
    context "When at least one previous visit exists" do
      it 'returns "Agreed to visit" if the last visit exists and has agreed_to_visit set' do
        patient = FactoryBot.create(:patient)
        appointment1 = FactoryBot.create(:appointment, :overdue, patient_id: patient.id)
        appointment1.status = "visited"
        appointment1.agreed_to_visit = true
        appointment1.remind_on = nil
        appointment1.save

        appointment2 = FactoryBot.create(:appointment, :overdue, patient_id: patient.id)
        appointment2.scheduled_date = 60.days.from_now
        appointment2.save

        expect(show_last_interaction_date_and_result(patient)).to include("Agreed to visit")
      end

      it 'returns "Remind to call later" if the last visit exists and remind_on is not nil' do
        patient = FactoryBot.create(:patient)

        appointment1 = FactoryBot.create(:appointment, :overdue, patient_id: patient.id)
        appointment1.status = "visited"
        appointment1.agreed_to_visit = false
        appointment1.remind_on = Date.current
        appointment1.save

        appointment2 = FactoryBot.create(:appointment, :overdue, patient_id: patient.id)
        appointment2.scheduled_date = 60.days.from_now
        appointment2.save

        expect(show_last_interaction_date_and_result(patient)).to include("Remind to call later")
      end
    end
  end
end
