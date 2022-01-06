# frozen_string_literal: true

module Seed
  module Helpers
    extend ActionView::Helpers::DateHelper
  end

  def self.seed_org_name
    Seed::FakeNames.instance.seed_org_name
  end

  def self.seed_org
    Organization.find_by(name: seed_org_name) || FactoryBot.create(:organization, name: seed_org_name)
  end
end
