require 'json'

class Api::ManifestsController < ApplicationController
  def show
    manifest_file = "public/manifest/production.json"
    return head :not_found unless File.exist?(manifest_file)

    @manifest = JSON.parse(File.read(manifest_file))
  end
end

