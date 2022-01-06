# frozen_string_literal: true

require "rails_helper"
require_relative "../../lib/generators/data_script/data_script_generator"

RSpec.describe "DataScripts", type: :generator do
  let(:script) { Rails.root.join("lib", "data_scripts", "widget_renamer_script.rb") }
  let(:spec) { Rails.root.join("spec", "lib", "data_scripts", "widget_renamer_script_spec.rb") }

  after do
    script.delete if script.exist?
    spec.delete if spec.exist?
  end

  it "creates the script and the spec" do
    generator = DataScriptGenerator.new(["widget_renamer"])
    generator.create_data_script

    expect(script).to exist
    expect(spec).to exist
  end
end
