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

  let(:analytics_cohort_cache_key) { "analytics/facilities/#{facility.id}/cohort/month" }
  let(:analytics_dashboard_cache_key) { "analytics/facilities/#{facility.id}/dashboard/month" }

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
        expect(assigns(:dashboard_analytics)[user.id].keys).to match_array(%i[follow_up_patients_by_period
          registered_patients_by_period
          total_registered_patients])
      end
    end

    it "renders the cohort chart view" do
      get :show, params: {id: facility.id}
      expect(response).to render_template(partial: "shared/_cohort_charts")
    end

    it "renders the analytics table view" do
      get :show, params: {id: facility.id}
      expect(response).to render_template(partial: "shared/_analytics_table")
    end

    it "renders the recent BP view" do
      get :show, params: {id: facility.id}
      expect(response).to render_template(partial: "shared/_recent_bp_log")
    end

    context "analytics caching for facilities" do
      before do
        Rails.cache.delete(analytics_cohort_cache_key)
        Rails.cache.delete(analytics_dashboard_cache_key)
        travel_to(may_2019)
      end

      after do
        travel_back
      end

      it "caches the facility correctly" do
        create_list(:patient,
          3,
          :hypertension,
          registration_facility: facility,
          registration_user: user,
          recorded_at: mar_2019)

        expected_cache_value =
          {
            cohort: {
              [mar_2019, apr_2019] => {
                registered: {:total => 3, facility.id.to_sym => 3},
                followed_up: {total: 0},
                defaulted: {:total => 3, facility.id.to_sym => 3},
                controlled: {total: 0},
                uncontrolled: {total: 0}
              },
              [feb_2019, mar_2019] => {
                registered: {:total => 3, facility.id.to_sym => 3},
                followed_up: {:total => 3, facility.id.to_sym => 3},
                defaulted: {:total => 0, facility.id.to_sym => 0},
                controlled: {:total => 3, facility.id.to_sym => 3},
                uncontrolled: {:total => 0, facility.id.to_sym => 0}
              },
              [jan_2019, feb_2019] => {
                registered: {total: 0},
                followed_up: {total: 0},
                defaulted: {total: 0},
                controlled: {total: 0},
                uncontrolled: {total: 0}
              },
              [dec_2018, jan_2019] => {
                registered: {total: 0},
                followed_up: {total: 0},
                defaulted: {total: 0},
                controlled: {total: 0},
                uncontrolled: {total: 0}
              },
              [nov_2018, dec_2018] => {
                registered: {total: 0},
                followed_up: {total: 0},
                defaulted: {total: 0},
                controlled: {total: 0},
                uncontrolled: {total: 0}
              },
              [oct_2018, nov_2018] => {
                registered: {total: 0},
                followed_up: {total: 0},
                defaulted: {total: 0},
                controlled: {total: 0},
                uncontrolled: {total: 0}
              }
            },

            dashboard: {
              user.id => {
                registered_patients_by_period: {feb_2019 => 3, mar_2019 => 3},
                total_registered_patients: 6,
                follow_up_patients_by_period: {mar_2019 => 3}
              }
            }
          }

        get :show, params: {id: facility.id}

        expect(Rails.cache.exist?(analytics_cohort_cache_key)).to be true
        expect(Rails.cache.fetch(analytics_cohort_cache_key).deep_symbolize_keys).to eq expected_cache_value[:cohort]

        expect(Rails.cache.exist?(analytics_dashboard_cache_key)).to be true
        expect(Rails.cache.fetch(analytics_dashboard_cache_key)).to eq expected_cache_value[:dashboard]
      end

      it "never ends up querying the database when cached" do
        get :show, params: {id: facility.id}

        expect_any_instance_of(Facility).to_not receive(:cohort_analytics)
        expect_any_instance_of(Facility).to_not receive(:dashboard_analytics)

        # this get should always have cached values
        get :show, params: {id: facility.id}
      end
    end

    context "Recent bps" do
      it "shouldn't include discarded patient's blood pressures" do
        registered_patients.first.discard_data

        get :show, params: {id: facility.id}
        expect(assigns(:recent_blood_pressures).count).to eq(2)
      end
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
