require "rails_helper"

RSpec.describe Analytics::DistrictsController, type: :controller do
  let(:admin) { create(:admin, :owner) }

  let(:district_name) { "Bathinda" }
  let(:organization) { create(:organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let(:facility) { create(:facility, facility_group: facility_group, district: district_name) }
  let(:organization_district) { OrganizationDistrict.new(district_name, organization) }
  let(:sanitized_district_name) { organization_district.district_name.downcase.split(" ").join("-") }

  before do
    #
    # register patients
    #
    registered_patients = Timecop.travel(Date.new(2018, 11, 1)) {
      create_list(:patient, 3, :hypertension, registration_facility: facility)
    }

    #
    # add blood_pressures next month
    #
    Timecop.travel(Date.new(2019, 2, 1)) do
      registered_patients.each { |patient| create(:blood_pressure, :under_control, patient: patient, facility: facility) }
    end

    Patient.where(id: registered_patients.map(&:id))
  end

  before do
    sign_in(admin.email_authentication)
  end

  describe "#show" do
    render_views

    context "dashboard analytics" do
      it "returns relevant analytics keys per facility" do
        Timecop.travel(Date.new(2019, 3, 1)) do
          get :show, params: {organization_id: organization.id, id: district_name}
        end

        expect(response.status).to eq(200)
        expect(assigns(:dashboard_analytics)[facility.id].keys)
          .to(match_array(%i[patients_with_bp_by_period registered_patients_by_period total_patients]))
      end
    end

    context "csv download" do
      it "renders a csv" do
        get :show, params: {organization_id: organization.id, id: district_name}, format: :csv
        expect(response).to be_successful
      end
    end

    it "allow cache to be refreshed forcefully" do
      request_store = {}
      allow(RequestStore).to receive(:store).and_return(request_store)
      get :show, params: {organization_id: organization.id, id: district_name, force_cache: true}
      expect(request_store[:force_cache]).to eq(true)
    end
  end

  describe "#patient_list" do
    render_views

    it "should queue job for line list download" do
      expect(PatientListDownloadJob).to receive(:perform_later).with(admin.email,
        "district",
        district_name: district_name,
        organization_id: organization.id)

      get :patient_list, params: {organization_id: organization.id, district_id: district_name}
    end
  end

  describe "#patient_list_with_history" do
    render_views

    it "should queue job for line list with history download" do
      expect(PatientListDownloadJob).to receive(:perform_later).with(admin.email,
        "district",
        {
          district_name: district_name,
          organization_id: organization.id
        },
        with_medication_history: true)

      get :patient_list_with_history, params: {organization_id: organization.id, district_id: district_name}
    end
  end

  describe "#whatsapp_graphics" do
    render_views

    context "html requested" do
      it "renders graphics_header partial" do
        get :whatsapp_graphics, format: :html, params: {organization_id: organization.id, district_id: district_name}

        expect(response).to be_ok
        expect(response).to render_template("shared/graphics/_graphics_partial")
      end
    end

    context "png requested" do
      it "renders the image template for downloading" do
        get :whatsapp_graphics, format: :png, params: {organization_id: organization.id, district_id: district_name}

        expect(response).to be_ok
        expect(response).to render_template("shared/graphics/image_template")
      end
    end
  end
end
