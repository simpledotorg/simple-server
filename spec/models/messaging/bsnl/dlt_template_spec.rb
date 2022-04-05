require "rails_helper"

RSpec.describe Messaging::Bsnl::DltTemplate do
  def stub_template(template_name)
    stub_const("Messaging::Bsnl::DltTemplate::BSNL_TEMPLATES", {
      template_name => {"Template_Id" => "a template id",
                        "Template_Keys" => %w[key_1 key_2],
                        "Non_Variable_Text_Length" => "10",
                        "Max_Length_Permitted" => "20"}
    })
  end

  it "looks up the template ID from config" do
    allow_any_instance_of(Facility).to receive(:locale).and_return("en")
    template_name = "en.a.template.name"
    stub_template(template_name)

    expect(described_class.new(template_name).id).to eq("a template id")
    expect(described_class.new(template_name).name).to eq(template_name)
    expect(described_class.new(template_name).keys).to contain_exactly("key_1", "key_2")
    expect(described_class.new(template_name).max_length_permitted).to eq(20)
    expect(described_class.new(template_name).non_variable_text_length).to eq(10)
    expect(described_class.new(template_name).variable_length_permitted).to eq(10)
  end

  it "returns nil if the message key is missing in config" do
    allow_any_instance_of(Facility).to receive(:locale).and_return("en")
    existing_template_name = "en.a.template.name"
    stub_template(existing_template_name)
    missing_template_name = "en.a.missing.template"

    expect { described_class.new(missing_template_name) }.to raise_error(Messaging::Bsnl::Error)
  end

  describe "#sanitised_variable_content" do
    it "calls validation methods" do
      template_name = "en.a.template.name"
      stub_template(template_name)
      template = described_class.new(template_name)
      content = {a: :hash}

      allow(template).to receive(:check_variables_presence).and_return(content)
      allow(template).to receive(:trim_variables).and_return(content)
      allow(template).to receive(:limit_total_variable_length).and_return(content)
      allow(template).to receive(:check_total_variable_length).and_return(content)

      expect(template).to receive(:check_variables_presence).with(content)
      expect(template).to receive(:trim_variables).with(content)
      expect(template).to receive(:limit_total_variable_length).with(content)
      expect(template).to receive(:check_total_variable_length).with(content)

      template.sanitised_variable_content(content)
    end
  end

  describe "#check_variables_presence" do
    it "raises an error if all the variables that the template requires have not been provided" do
      template_name = "en.a.template.name"
      stub_template(template_name)
      template = described_class.new(template_name)

      expect { template.check_variables_presence({key_1: "Value 1"}) }
        .to raise_error(Messaging::Bsnl::Error, "Variables key_2 not provided to #{template_name}")
    end

    it "does not raise an error if all the variables have been provided" do
      template_name = "en.a.template.name"
      stub_template(template_name)
      template = described_class.new(template_name)

      expect { template.check_variables_presence({key_1: "Value 1", key_2: "Value 2"}) }.not_to raise_error(Messaging::Bsnl::Error)
    end
  end

  describe "#trim_variables" do
    it "trims the variables to the maximum per variable length allowed by DLT" do
      stub_const("Messaging::Bsnl::DltTemplate::MAX_VARIABLE_LENGTH", 10)

      template_name = "en.a.template.name"
      stub_template(template_name)
      template = described_class.new(template_name)

      expect(template.trim_variables({key_1: "A variable longer than 10 characters"})).to eq({key_1: "A variable"})
    end
  end

  describe "#limit_total_variable_length" do
    it "doesn't change the variable lengths if they are within the limit" do
      template_name = "en.a.template.name"
      stub_const("Messaging::Bsnl::DltTemplate::BSNL_TEMPLATES", {
        template_name => {"Template_Id" => "a template id",
                          "Template_Keys" => %w[key_1 key_2 key_3],
                          "Non_Variable_Text_Length" => "10",
                          "Max_Length_Permitted" => "20"}
      })
      stub_const("Messaging::Bsnl::DltTemplate::TRIMMABLE_VARIABLES", %i[key_1 key_2 key_3])

      template = described_class.new(template_name)
      variable_content = {key_1: "a" * 3, key_2: "a" * 3, key_3: "a" * 3}
      expect(template.limit_total_variable_length(variable_content)).to eq(variable_content)
    end

    it "only trims the variables that are in the allow list" do
      template_name = "en.a.template.name"
      stub_template(template_name)
      stub_const("Messaging::Bsnl::DltTemplate::TRIMMABLE_VARIABLES", %i[key_1])

      template = described_class.new(template_name)

      expect(template.limit_total_variable_length({key_1: "a" * 3, key_2: "a" * 10})).to eq({key_1: "", key_2: "a" * 10})
    end

    it "preserves equal amounts of all variables that are trimmable" do
      template_name = "en.a.template.name"
      stub_const("Messaging::Bsnl::DltTemplate::BSNL_TEMPLATES", {
        template_name => {"Template_Id" => "a template id",
                          "Template_Keys" => %w[key_1 key_2 key_3],
                          "Non_Variable_Text_Length" => "10",
                          "Max_Length_Permitted" => "20"}
      })
      stub_const("Messaging::Bsnl::DltTemplate::TRIMMABLE_VARIABLES", %i[key_1 key_2])

      template = described_class.new(template_name)
      expect(template.limit_total_variable_length({key_1: "a" * 5, key_2: "a" * 5, key_3: "a" * 3})).to eq({key_1: "aaaa", key_2: "aaa", key_3: "aaa"})
      expect(template.limit_total_variable_length({key_1: "a" * 2, key_2: "a" * 5, key_3: "a" * 3})).to eq({key_1: "aa", key_2: "aaaaa", key_3: "aaa"})
    end
  end

  describe "#check_total_variable_length" do
    it "raises an error if the total variable length is longer than the permitted length (after all the other optimisations we can make)" do
      template_name = "en.a.template.name"
      stub_template(template_name)
      stub_const("Messaging::Bsnl::DltTemplate::TRIMMABLE_VARIABLES", %i[key_1 key_2])

      template = described_class.new(template_name)
      expect { template.limit_total_variable_length({key_1: "a" * 2, key_2: "a" * 5}) }.not_to raise_error
      expect { template.check_total_variable_length({key_1: "a" * 10, key_2: "a" * 10}) }.to raise_error
    end
  end
end
