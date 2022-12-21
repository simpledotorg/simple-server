require "rails_helper"

RSpec.describe Questionnaire, type: :model do
  describe "#localized_layout" do
    it { should delegate_method(:localized_layout).to(:questionnaire_version) }
    it { should delegate_method(:id).to(:questionnaire_version) }
  end
end
