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

  def files_in_directory(directory)
    Dir[directory.join('**', '*.rb')]
      .map { |file| file.to_s.remove(Rails.root.to_s) }
  end

  describe 'generates the scaffold required to migrate to a new API version' do
    describe 'copy current specs for the give current version' do
      it 'api specs' do
        current_spec_files = files_in_directory(spec_root.join('api', 'current'))


        current_spec_files.each do |path|
          new_file_path = path.sub('current', CURRENT_VERSION)
          assert_file(destination_root.to_s + new_file_path, Regexp.new("#{CURRENT_VERSION}/swagger.json"))
          assert_file(destination_root.to_s + new_file_path, Regexp.new(CURRENT_VERSION.capitalize))
        end
      end


      it 'controller specs' do
        current_spec_files = files_in_directory(spec_root.join('controllers', 'api', 'current'))

        current_spec_files.each do |path|
          new_file_path = path.sub('current', CURRENT_VERSION)
          assert_file(destination_root.to_s + new_file_path, Regexp.new("Api::#{CURRENT_VERSION.capitalize}"))
        end
      end

      it 'payload specs ' do
        current_spec_files = files_in_directory(spec_root.join('payloads', 'api', 'current'))

        current_spec_files.each do |path|
          new_file_path = path.sub('current', CURRENT_VERSION)
          assert_file(destination_root.to_s + new_file_path, Regexp.new("Api::#{CURRENT_VERSION.capitalize}"))
        end
      end

      it 'request specs' do
        current_spec_files = files_in_directory(spec_root.join('requests', 'api', 'current'))

        current_spec_files.each do |path|
          new_file_path = path.sub('current', CURRENT_VERSION)
          assert_file(destination_root.to_s + new_file_path, Regexp.new("Api::#{CURRENT_VERSION.capitalize}"))
        end
      end
    end

    describe 'creates controllers for the given current version' do
      it 'creates controller files using template' do
        assert_directory("#{destination_root}/app/controllers/api/#{CURRENT_VERSION}")
      end
    end

    describe 'creates schema for the given current version' do
      it 'copies the schema files' do
        expect(destination_root.to_s + '/app/schema/api').to have_structure {
          directory CURRENT_VERSION do
            file 'models.rb'
            file 'schema.rb'
          end
        }
      end
    end
  end
end