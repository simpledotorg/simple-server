require "rails_helper"

RSpec.describe Seed::Cli do
  it "reports the number of processorts that will be used" do
    expect(Parallel).to receive(:processor_count).and_return(8)
    output = StringIO.new
    input = StringIO.new("\n")
    Seed::Cli.new([], output: output, input: input).run
    expect(output.string).to include("using 8 cores, continue? (Y/n)")
  end

  it "runs the seed task when Y is entered" do
    expect(Parallel).to receive(:processor_count).and_return(8)
    expect(Seed::Runner).to receive(:call).once
    output = StringIO.new
    input = StringIO.new("Y\n")
    Seed::Cli.new([], output: output, input: input).run
  end

  it "does not run the seed task for any other input" do
    expect(Parallel).to receive(:processor_count).and_return(8)
    expect(Seed::Runner).to receive(:call).never
    output = StringIO.new
    input = StringIO.new("N\n")
    Seed::Cli.new([], output: output, input: input).run
  end
end
