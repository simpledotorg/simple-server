class ManifestsController < ApplicationController
  def show
    render file: "public/manifest/#{ENV['SIMPLE_SERVER_ENV']}.json", status: :ok
  end
end
