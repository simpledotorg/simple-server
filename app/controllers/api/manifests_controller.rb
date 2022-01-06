# frozen_string_literal: true

class Api::ManifestsController < ApplicationController
  def show
    if ENV["SIMPLE_SERVER_ENV"].in?(%w[development profiling review android_review])
      @countries = %w[IN BD ET US UK]
    else
      manifest_file = "public/manifest/#{ENV["SIMPLE_SERVER_ENV"]}.json"
      return head :not_found unless File.exist?(manifest_file)

      render json: File.read(manifest_file)
    end
  end
end
