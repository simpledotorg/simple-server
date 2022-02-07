require "rails_helper"
 require_relative "../../../lib/data_scripts/nhf_study_export_script"

describe NhfStudyExportScript do
  it "runs" do
    described_class.call
  end

  it "enables readonly mode when in dry run mode" do
    described_class.call(dry_run: true)
    expect(User.new).to be_readonly
  end

  it "changes nothing in dry run mode" do
    expect {
      described_class.call
    }.to_not change {
      Patient.count
    }
  end
end
