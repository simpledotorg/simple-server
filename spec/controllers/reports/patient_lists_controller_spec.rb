# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::PatientListsController, type: :controller do
  let(:user) { create(:user) }
  let(:admin_without_pii) { create(:admin, :viewer_reports_only) }
  let(:admin_with_pii) { create(:admin, :viewer_all) }
  let(:organization) { FactoryBot.create(:organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let(:facility_group_2) { create(:facility_group) }
  let(:facility) { create(:facility, facility_group: facility_group) }
  let(:cvho) { create(:admin, :manager, :with_access, resource: organization) }

  before do
    Timecop.freeze("April 15th 2020") do
      patients_with_controlled_bp = create_list(:patient, 2, recorded_at: 1.month.ago, registration_facility: facility, registration_user: user)
      patients_with_controlled_bp.map do |patient|
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: Time.current, user: user)
      end
    end
  end

  context "show" do
    it "works for facility groups the admin has access to" do
      expect(PatientListDownloadJob).to receive(:perform_later).with(
        admin_with_pii.email,
        "facility_group",
        {id: facility_group.id},
        with_medication_history: false
      )
      admin_with_pii.accesses.create!(resource: facility_group)
      sign_in(admin_with_pii.email_authentication)
      get :show, params: {id: facility_group.slug, report_scope: "district"}
      expect(response).to redirect_to(reports_region_path(facility_group.slug, report_scope: "district"))
    end

    it "rejects attempts for facility groups admin does not have access to" do
      expect(PatientListDownloadJob).to_not receive(:perform_later)
      admin_with_pii.accesses.create!(resource: facility_group)
      sign_in(admin_with_pii.email_authentication)
      expect {
        get :show, params: {id: facility_group_2.slug, report_scope: "district"}
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "rejects attempts for users w/o proper access" do
      expect(PatientListDownloadJob).to_not receive(:perform_later)
      admin_without_pii.accesses.create!(resource: facility_group)
      sign_in(admin_without_pii.email_authentication)
      expect {
        get :show, params: {id: facility_group_2.slug, report_scope: "district"}
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should queue line list with medication history if medication_history is true" do
      expect(PatientListDownloadJob).to receive(:perform_later).with(
        admin_with_pii.email,
        "facility_group",
        {id: facility_group.id},
        with_medication_history: true
      )
      admin_with_pii.accesses.create!(resource: facility_group)
      sign_in(admin_with_pii.email_authentication)
      get :show, params: {id: facility_group.slug, report_scope: "district", medication_history: true}
    end

    it "works for facilities where the region slug does not match the facility slug" do
      facility = create(:facility)
      facility.update(slug: "a-facility-slug")
      facility.region.update(slug: "a-facility-region-slug")
      expect(PatientListDownloadJob).to receive(:perform_later)
      admin_with_pii.accesses.create!(resource: facility)
      sign_in(admin_with_pii.email_authentication)
      get :show, params: {id: facility.region.slug, report_scope: "facility", medication_history: true}
      expect(response).to redirect_to(reports_region_path(facility.region.slug, report_scope: "facility"))
    end
  end
end
