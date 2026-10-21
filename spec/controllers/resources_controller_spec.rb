require "rails_helper"

RSpec.describe ResourcesController, type: :controller do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin.email_authentication)
  end

  describe "GET #index" do
    render_views

    it "returns a success response" do
      get :index, params: {}

      expect(response).to be_successful
    end
  end

  describe "GET #qi_reports" do
    render_views

    it "lists the PDFs and shows a viewer" do
      get :qi_reports, params: {}

      expect(response).to be_successful
      expect(response.body).to include("sample-qi-report-q1.pdf", "sample-qi-report-q2.pdf", "Download", "Print")
    end

    it "ignores unknown file params" do
      get :qi_reports, params: {file: "../../secret.pdf"}

      expect(response).to be_successful
      expect(response.body).not_to include("secret.pdf")
    end
  end
end
