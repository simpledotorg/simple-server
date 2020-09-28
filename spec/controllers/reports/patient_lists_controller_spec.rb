require "rails_helper"

RSpec.describe Reports::PatientListsController, type: :controller do
  let(:user) { create(:user) }
  let(:non_admin) { create(:admin, :viewer_reports_only) }
  let(:admin) { create(:admin, :owner, :viewer_all) }
  let(:organization) { FactoryBot.create(:organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let(:facility_group_2) { create(:facility_group) }
  let(:facility) { create(:facility, facility_group: facility_group) }
  let(:cvho) do
    create(:admin, :supervisor, organization: organization).tap do |user|
      user.user_permissions << build(:user_permission, permission_slug: :view_cohort_reports, resource: organization)
    end
  end

  before do
    Timecop.freeze("April 15th 2020") do
      patients_with_controlled_bp = create_list(:patient, 2, recorded_at: 1.month.ago, registration_facility: facility, registration_user: user)
      patients_with_controlled_bp.map do |patient|
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: Time.current, user: user)
      end
    end
  end

  context "show" do
    before do
      Flipper.disable(:new_permissions_system_aug_2020)
    end

    it "rejects admins without proper authorization" do
      expect(PatientListDownloadJob).to_not receive(:perform_later)
      analyst = create(:admin, :analyst)
      sign_in(analyst.email_authentication)
      get :show, params: {id: facility.slug, report_scope: "facility"}
      expect(response).to redirect_to(root_url)
    end

    it "returns CSV of registered patients in facility" do

      expect(PatientListDownloadJob).to receive(:perform_later).with(admin.email,
        "facility", {facility_id: facility.id})
      sign_in(admin.email_authentication)
      get :show, params: {id: facility.slug, report_scope: "facility"}
      expect(response).to redirect_to(reports_region_path(facility.slug, report_scope: "facility"))
    end

    it "returns CSV of registered patients in facility_group" do
      expect(PatientListDownloadJob).to receive(:perform_later).with(admin.email,
        "facility_group", {id: facility_group.id})
      sign_in(admin.email_authentication)
      get :show, params: {id: facility_group.slug, report_scope: "district"}
      expect(response).to redirect_to(reports_region_path(facility_group.slug, report_scope: "district"))
    end
  end

  context "show (with permissions_v2 enabled)" do
    before do
      Flipper.enable(:new_permissions_system_aug_2020)
    end

    it "works for facility groups the admin has acces to" do
      expect(PatientListDownloadJob).to receive(:perform_later).with(admin.email,
        "facility_group", {id: facility_group.id})
      admin.accesses.create!(resource: facility_group)
      sign_in(admin.email_authentication)
      get :show, params: {id: facility_group.slug, report_scope: "district"}
      expect(response).to redirect_to(reports_region_path(facility_group.slug, report_scope: "district"))
    end

    it "rejects attempts for facility groups admin does not have access to" do
      expect(PatientListDownloadJob).to_not receive(:perform_later)
      admin.accesses.create!(resource: facility_group)
      sign_in(admin.email_authentication)
      expect {
        get :show, params: {id: facility_group_2.slug, report_scope: "district"}
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "rejects attempts for users w/o proper access" do
      expect(PatientListDownloadJob).to_not receive(:perform_later)
      non_admin.accesses.create!(resource: facility_group)
      sign_in(non_admin.email_authentication)
      expect {
        get :show, params: {id: facility_group_2.slug, report_scope: "district"}
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
