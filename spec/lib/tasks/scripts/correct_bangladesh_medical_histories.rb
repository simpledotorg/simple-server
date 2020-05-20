require "rails_helper"
require "tasks/scripts/correct_bangladesh_medical_histories"

RSpec.describe CorrectBangladeshMedicalHistories do
  describe "#call" do
    it "set only unknown hypertensions to yes" do
      original_country = Rails.application.config.country[:abbreviation]
      Rails.application.config.country[:abbreviation] = "BD"

      yeses = create_list(:medical_history, 2, :hypertension_yes)
      nos = create_list(:medical_history, 3, :hypertension_no)
      unknowns = create_list(:medical_history, 4, :hypertension_unknown)

      CorrectBangladeshMedicalHistories.call(verbose: false)

      unknowns.each do |medical_history|
        medical_history.reload
        expect(medical_history.hypertension).to eq("yes")
        expect(medical_history.diagnosed_with_hypertension).to eq("yes")
      end

      yeses.each do |medical_history|
        expect(medical_history.reload.hypertension).to eq("yes")
      end

      nos.each do |medical_history|
        expect(medical_history.reload.hypertension).to eq("no")
      end

       Rails.application.config.country[:abbreviation] = original_country
    end

    context "outside of Bangladesh" do
      it "does not modify any drugs" do
        original_country = Rails.application.config.country[:abbreviation]
        Rails.application.config.country[:abbreviation] = "IN"

        yes = create(:medical_history, :hypertension_yes)
        no = create(:medical_history, :hypertension_no)
        unknown = create(:medical_history, :hypertension_unknown)

        CorrectBangladeshMedicalHistories.call(dryrun: true, verbose: false)

        expect(yes.hypertension).to eq("yes")
        expect(no.hypertension).to eq("no")
        expect(unknown.hypertension).to eq("unknown")

        Rails.application.config.country[:abbreviation] = original_country
      end
    end

    context "with dryrun" do
      it "does not modify any drugs" do
        original_country = Rails.application.config.country[:abbreviation]
        Rails.application.config.country[:abbreviation] = "BD"

        yes = create(:medical_history, :hypertension_yes)
        no = create(:medical_history, :hypertension_no)
        unknown = create(:medical_history, :hypertension_unknown)

        CorrectBangladeshMedicalHistories.call(dryrun: true, verbose: false)

        expect(yes.hypertension).to eq("yes")
        expect(no.hypertension).to eq("no")
        expect(unknown.hypertension).to eq("unknown")

        Rails.application.config.country[:abbreviation] = original_country
      end
    end
  end
end
