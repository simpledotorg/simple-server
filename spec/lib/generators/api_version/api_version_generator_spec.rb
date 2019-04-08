require 'rails_helper'
require 'generator_spec'

require 'generators/api_version/api_version_generator'

RSpec.describe ApiVersionGenerator, "using custom matcher", type: :generator do
  CURRENT_VERSION = 'v2'
  NEW_VERSION = 'v3'

  let(:spec_root) { Rails.root.join('spec') }

  destination(Rails.root.join('spec', 'tmp'))
  arguments ['--current-version', CURRENT_VERSION, '--new-version', NEW_VERSION]

  before(:all) do
    prepare_destination
    run_generator
  end

  after(:all) do
    prepare_destination
  end

  describe 'generates the scaffold required to migrate to a new API version' do
    it 'creates a copy of the current api specs for the given current_version' do
      current_spec_files = Dir[spec_root.join('api', 'current', '**', '*')].map do |path|
        path.split('/').last
      end

      expect(destination_root).to have_structure {
        directory 'spec' do
          directory 'api' do
            directory CURRENT_VERSION do
              current_spec_files.each do |file_name|
                file file_name do
                  contains "#{CURRENT_VERSION}/swagger.json"
                end
              end
            end
          end
        end
      }
    end

    it 'renames current to the new current_version in the copied api specs, if existing file contains it' do
      current_spec_paths = Dir[spec_root.join('api', 'current', '**', '*')]

      current_spec_paths.each do |path|
        current_file_contents = File.readlines(path)
        new_file_path = path.sub('current', CURRENT_VERSION)

        assert_file(new_file_path, CURRENT_VERSION.capitalize) if current_file_contents.include?('Current')
        assert_file(new_file_path, CURRENT_VERSION) if current_file_contents.include?('current')
      end
    end
  end
end