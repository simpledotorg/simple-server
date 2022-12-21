require "rails_helper"

RSpec.describe Questionnaire, type: :model do
  describe "#localized_layout" do
    it { should delegate_method(:localized_layout).to(:questionnaire_version) }
    it { should delegate_method(:created_at).to(:questionnaire_version) }
  end
end
