require "spec_helper"

RSpec.describe "Rachet down usage of let!" do
  expected_usages = 492

  it "prevents new usages" do
    command = %{grep -rn "\slet\!(:" spec}
    offending_lines = `#{command}`
    actual_usages = offending_lines.split("\n").count

    msg = <<~EOL
      It looks like you added a new usage of 'let!'. We expected #{expected_usages}, but found #{actual_usages}.
      Please change your test setup to use local variables, a regular ruby method, or some other approach.
      For more background and ideas on alternative approaches see https://thoughtbot.com/blog/lets-not and https://thoughtbot.com/blog/my-issues-with-let.

      And if you really must use let!, you can increase EXPECTED_USAGES in the #{__FILE__}.
    EOL
    happy_msg = <<~EOL
      You removed a usage of let! We previously had #{expected_usages}, but found #{actual_usages}.
      Thank you for helping us work towards more explicit and maintainable specs.
      Please change 'expected_usages' in #{__FILE__} to #{actual_usages} to continue to rachet this down."
    EOL
    expect(actual_usages).to_not be > expected_usages, msg
    expect(actual_usages).to_not be < expected_usages, happy_msg
  end
end
