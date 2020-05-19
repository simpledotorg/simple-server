class Api::ManifestsController < ApplicationController
  def show
    if ENV['SIMPLE_SERVER_ENV'].in?(%w[development review])
      render json: dynamic_manifest
    else
      manifest_file = "public/manifest/#{ENV['SIMPLE_SERVER_ENV']}.json"
      return head :not_found unless File.exists?(manifest_file)

      render json: File.read(manifest_file)
    end
  end

  private

  def dynamic_manifest
    {
      v1: [
        {
          country_code: "IN",
          endpoint: dynamic_api_endpoint,
          display_name: "India",
          isd_code: "91"
        },
        {
          country_code: "BD",
          endpoint: dynamic_api_endpoint,
          display_name: "Bangladesh",
          isd_code: "880"
        },
        {
          country_code: "ET",
          endpoint: dynamic_api_endpoint,
          display_name: "Ethiopia",
          isd_code: "251"
        }
      ]
    }
  end

  def dynamic_api_endpoint
    "#{ENV['SIMPLE_SERVER_HOST_PROTOCOL']}://#{ENV['SIMPLE_SERVER_HOST']}/api/"
  end
end
