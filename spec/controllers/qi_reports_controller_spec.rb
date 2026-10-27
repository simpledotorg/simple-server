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
