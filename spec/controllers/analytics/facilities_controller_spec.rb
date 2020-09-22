require "rails_helper"

RSpec.describe Analytics::FacilitiesController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:admin, :owner) }

  let(:district_name) { "Bathinda" }
  let(:organization) { create(:organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let(:facility) { create(:facility, facility_group: facility_group, district: district_name) }

  let(:may_2019) { Date.new(2019, 5, 1) }
  let(:apr_2019) { Date.new(2019, 4, 1) }
  let(:mar_2019) { Date.new(2019, 3, 1) }
  let(:feb_2019) { Date.new(2019, 2, 1) }
  let(:jan_2019) { Date.new(2019, 1, 1) }
  let(:dec_2018) { Date.new(2018, 12, 1) }
  let(:nov_2018) { Date.new(2018, 11, 1) }
  let(:oct_2018) { Date.new(2018, 10, 1) }
  let(:sep_2018) { Date.new(2018, 9, 1) }

  let!(:registered_patients) do
    travel_to(feb_2019) {
      create_list(:patient,
        3,
        :hypertension,
        registration_facility: facility,
        registration_user: user)
    }
  end

  before do
    #
    # add blood_pressures next month
    #
    travel_to(mar_2019) do
      registered_patients.each do |patient|
        blood_pressure = create(:blood_pressure, :under_control, patient: patient, facility: facility, user: user)
        create(:encounter, :with_observables, patient: patient, observable: blood_pressure, facility: facility)
      end
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
        Timecop.travel(apr_2019) do
          get :show, params: {id: facility.id}
        end

        expect(response.status).to eq(200)
        expect(assigns(:dashboard_analytics)[user.id].keys)
          .to(match_array(%i[registered_patients_by_period total_registered_patients]))
      end
    end

    it "renders the cohort chart view" do
      get :show, params: {id: facility.id}
      expect(response).to render_template(partial: "shared/_cohort_charts")
    end

    it "renders the recent BP view" do
      get :show, params: {id: facility.id}
      expect(response).to render_template(partial: "shared/_recent_bp_log")
    end

    context "Recent bps" do
      it "shouldn't include discarded patient's blood pressures" do
        registered_patients.first.discard_data

        get :show, params: {id: facility.id}
        expect(assigns(:recent_blood_pressures).count).to eq(2)
      end
    end

    context "csv download" do
      it "renders a csv" do
        get :show, params: {id: facility.id}, format: :csv
        expect(response).to be_successful
      end
    end
  end

  describe "#patient_list" do
    render_views
    it "should queue job for line list download" do
      expect(PatientListDownloadJob).to receive(:perform_later).with(admin.email, "facility", facility_id: facility.id)

      get :patient_list, params: {facility_id: facility.id}
    end
  end

  describe "#patient_list_with_history" do
    render_views

    it "should queue job for line list with history download" do
      expect(PatientListDownloadJob).to receive(:perform_later).with(admin.email,
        "facility",
        {facility_id: facility.id},
        with_medication_history: true)

      get :patient_list_with_history, params: {facility_id: facility.id}
    end
  end

  describe "#whatsapp_graphics" do
    render_views

    context "html requested" do
      it "renders graphics_header partial" do
        get :whatsapp_graphics, format: :html, params: {facility_id: facility.id}

        expect(response).to be_ok
        expect(response).to render_template("shared/graphics/_graphics_partial")
      end
    end

    context "png requested" do
      it "renders the image template for downloading" do
        get :whatsapp_graphics, format: :png, params: {facility_id: facility.id}

        expect(response).to be_ok
        expect(response).to render_template("shared/graphics/image_template")
      end
    end
  end
end
