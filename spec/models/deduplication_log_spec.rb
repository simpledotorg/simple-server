# frozen_string_literal: true

require "rails_helper"

describe DeduplicationLog, type: :model do
  context "associations" do
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:deduped_record) }
    it { is_expected.to belong_to(:deleted_record) }
  end
end
