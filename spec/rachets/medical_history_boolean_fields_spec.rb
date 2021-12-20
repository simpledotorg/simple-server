require "spec_helper"

RSpec.describe "Rachet down usage of boolean fields in medical history" do
  it "prevents new usages of prior_heart_attack_boolean" do
    expected_usages = 1
    offending_lines = `grep -rn "prior_heart_attack_boolean" app`
    actual_usages = offending_lines.split("\n").count

    msg = <<~EOL
      Warning: prior_heart_attack_boolean is deprecated, you added a new usage.
    EOL
    happy_msg = <<~EOL
      You removed a usage of prior_heart_attack_boolean. Please update the expected_usages or delete this spec.
    EOL
    expect(actual_usages).to_not be > expected_usages, msg
    expect(actual_usages).to_not be < expected_usages, happy_msg
  end

  it "prevents new usages of prior_stroke_boolean" do
    expected_usages = 1
    offending_lines = `grep -rn "prior_stroke_boolean" app`
    actual_usages = offending_lines.split("\n").count

    msg = <<~EOL
      Warning: prior_stroke_boolean is deprecated, you added a new usage.
    EOL
    happy_msg = <<~EOL
      You removed a usage of prior_stroke_boolean. Please update the expected_usages or delete this spec.
    EOL
    expect(actual_usages).to_not be > expected_usages, msg
    expect(actual_usages).to_not be < expected_usages, happy_msg
  end
end
