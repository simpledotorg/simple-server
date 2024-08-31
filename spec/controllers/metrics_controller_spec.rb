# spec/controllers/metrics_controller_spec.rb
require "rails_helper"

RSpec.describe MetricsController, type: :controller do
  let(:sendgrid_service) { instance_double(SendgridService) }
  let(:metrics) do
    {
      total: 1000,
      remain: 500,
      used: 500,
      plan_completion_status: 1,
      exceeded_limit_status: 0,
      http_return_code: 200,
      http_response_time: 0.23
    }
  end

  before do
    allow(SendgridService).to receive(:new).and_return(sendgrid_service)
  end

  describe "GET #index" do
    context "when the SendGrid service call is successful" do
      before do
        allow(sendgrid_service).to receive(:check_credits).and_return(metrics)
        get :index
      end

      it "returns a successful response" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the correct metrics format" do
        expect(response.body).to include("sendgrid_email_limit_count #{metrics[:total]}")
        expect(response.body).to include("sendgrid_emails_remaining_count #{metrics[:remain]}")
        expect(response.body).to include("sendgrid_email_used_count #{metrics[:used]}")
        expect(response.body).to include("sendgrid_plan_limit_expire #{metrics[:plan_completion_status]}")
        expect(response.body).to include("sendgrid_email_limit_exceeded_by_threshold_limit #{metrics[:exceeded_limit_status]}")
        expect(response.body).to include("sendgrid_monitoring_http_return_code #{metrics[:http_return_code]}")
        expect(response.body).to include("sendgrid_monitoring_http_response_time_seconds #{metrics[:http_response_time]}")
      end
    end

    context "when the SendGrid service call fails" do
      before do
        allow(sendgrid_service).to receive(:check_credits).and_return({error: "Some error"})
        get :index
      end

      it "returns an unprocessable entity status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns the correct error message" do
        expect(response.body).to include("Error fetching metrics: Some error")
      end
    end
  end
end
