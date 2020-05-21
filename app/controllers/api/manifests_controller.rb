class Api::ManifestsController < ApplicationController
  def show
    manifest_file = "public/manifest/#{ENV["SIMPLE_SERVER_ENV"]}.json"
    return head :not_found unless File.exist?(manifest_file)
    render json: File.read(manifest_file),
           status: :ok
  end
end
