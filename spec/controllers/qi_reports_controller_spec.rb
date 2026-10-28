require "rails_helper"

RSpec.describe QiReportsController, type: :controller do
  describe "QI reports" do
    render_views

    before { sign_in(admin.email_authentication) }

    let(:facility_group) { create(:facility_group, name: "Kalutara") }
    let(:allowed) { QiReport.parse("Titration - Kalutara - Sep 2026.pdf") }
    let(:other) { QiReport.parse("Titration - Galle - Sep 2026.pdf") }

    before do
      allow(QiReport).to receive(:all).and_return([allowed, other])
      allow(allowed).to receive(:path).and_return(Rails.root.join("spec/fixtures/files/qi_report.pdf"))
    end

    context "with Titration and Statins reports" do
      let(:admin) { create(:admin, :power_user) }
      let(:statins) { QiReport.parse("Statins - Kalutara - Sep 2026.pdf") }

      before { allow(QiReport).to receive(:all).and_return([allowed, statins]) }

      it "shows Titration reports by default" do
        get :index

        expect(response.body).to include("Titration reports", "Statins report", "Titration · Sep 2026")
        expect(response.body).not_to include("Statins · Sep 2026")
      end

      it "shows Statins reports on the Statins tab" do
        get :index, params: {report: "Statins"}

        expect(response.body).to include("Statins · Sep 2026")
        expect(response.body).not_to include("Titration · Sep 2026")
      end

      it "shows an empty state when a tab has no reports" do
        allow(QiReport).to receive(:all).and_return([allowed])

        get :index, params: {report: "Statins"}

        expect(response.body).to include("No Statins report available yet.")
      end
    end

    context "with reports for several districts" do
      let(:admin) { create(:admin, :power_user) }

      before do
        create(:facility_group, name: "Kalutara", state_name: "Western")
        create(:facility_group, name: "Galle", state_name: "Southern")
        allow(QiReport).to receive(:all).and_return([allowed, other])
      end

      it "asks for a district instead of listing every report" do
        get :index

        expect(response.body).to include("Select a division and district")
        expect(response.body).not_to include(allowed.label)
      end

      it "shows the chosen district's report" do
        get :index, params: {district: "Galle"}

        expect(response.body).to include(other.label)
        expect(response.body).not_to include(allowed.label)
      end

      it "only offers districts in the chosen division" do
        get :index, params: {division: "Western"}

        expect(response.body).to include("Kalutara")
        expect(response.body).not_to include("Galle")
      end
    end

    context "when reports are per state region (state-level countries such as Ethiopia)" do
      let(:western) { QiReport.parse("Titration - Western - Sep 2026.pdf") }
      let(:southern) { QiReport.parse("Titration - Southern - Sep 2026.pdf") }
      let(:district_named_like_region) { QiReport.parse("Titration - Kalutara - Sep 2026.pdf") }

      before do
        allow(QiReport).to receive(:settings).and_return(QiReport::DEFAULT_SETTINGS.merge(level: "state", place_label: "Region"))
        allow(QiReport).to receive(:all).and_return([western, southern, district_named_like_region])
        allow(western).to receive(:path).and_return(Rails.root.join("spec/fixtures/files/qi_report.pdf"))
      end

      context "as a power user" do
        let(:admin) { create(:admin, :power_user) }

        it "shows a single Region dropdown and no division dropdown" do
          get :index

          expect(response.body).to include("Region", "Select a region to view the report.")
          expect(response.body).not_to include("Division")
        end
      end

      context "as a manager with access to a district in the Western region" do
        let(:facility_group) { create(:facility_group, name: "Kalutara", state_name: "Western") }
        let(:admin) { create(:admin, :manager, :with_access, resource: facility_group) }

        it "lists only their region, not other regions or a district with a different level" do
          get :index

          expect(response.body).to include("Western · Titration · Sep 2026")
          expect(response.body).not_to include("Southern")
          expect(response.body).not_to include("Kalutara · Titration")
        end

        it "refuses another region's file and a district-level file" do
          get :file, params: {file: southern.filename}
          expect(response).to redirect_to(root_path)

          get :file, params: {file: district_named_like_region.filename}
          expect(response).to redirect_to(root_path)
        end

        it "serves their region's file" do
          get :file, params: {file: western.filename}

          expect(response).to be_successful
        end
      end
    end

    context "as a manager with access to one district" do
      let(:admin) { create(:admin, :manager, :with_access, resource: facility_group) }

      it "lists only reports for their districts" do
        get :index

        expect(response).to be_successful
        expect(response.body).to include("Kalutara")
        expect(response.body).not_to include("Galle")
      end

      it "serves a permitted PDF" do
        get :file, params: {file: allowed.filename}

        expect(response).to be_successful
        expect(response.media_type).to eq("application/pdf")
      end

      it "refuses a PDF for another district" do
        get :file, params: {file: other.filename}

        expect(response).to redirect_to(root_path)
      end

      it "refuses unknown paths" do
        get :file, params: {file: "../../config/database.yml"}

        expect(response).to redirect_to(root_path)
      end
    end
  end
end
