require "rails_helper"

RSpec.describe Messaging::Bsnl::DltTemplate do
  def stub_template(template_name)
    stub_const("Messaging::Bsnl::DltTemplate::BSNL_TEMPLATES", {
      template_name => {"Template_Id" => "a template id",
                        "Template_Keys" => %w[key_1 key_2],
                        "Non_Variable_Text_Length" => "10",
                        "Max_Length_Permitted" => "20",
                        "Version" => 1,
                        "Is_Latest_Version" => true,
                        "Latest_Template_Version" => template_name}
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
    expect(described_class.new(template_name).version).to eq(1)
    expect(described_class.new(template_name).is_latest_version).to eq(true)
  end

  it "raises an error if the message key is missing in config" do
    allow_any_instance_of(Facility).to receive(:locale).and_return("en")
    existing_template_name = "en.a.template.name"
    stub_template(existing_template_name)
    missing_template_name = "en.a.missing.template"

    expect { described_class.new(missing_template_name) }.to raise_error(Messaging::Bsnl::TemplateError)
  end

  describe ".latest_name_of" do
    it "finds the name of the latest version of a template" do
      stub_const("Messaging::Bsnl::DltTemplate::BSNL_TEMPLATES", {
        "en.a.template.name" => {"Template_Id" => "a template id",
                                 "Template_Keys" => %w[key_1 key_2],
                                 "Non_Variable_Text_Length" => "10",
                                 "Max_Length_Permitted" => "20",
                                 "Version" => 1,
                                 "Is_Latest_Version" => true,
                                 "Latest_Template_Version" => "en.a.template.name.3"}
      })

      expect(described_class.latest_name_of("en.a.template.name")).to eq("en.a.template.name.3")
      expect(described_class.latest_name_of("en.a.template.name.2")).to eq("en.a.template.name.3")
    end

    it "finds the name of the latest version of a template if only versioned templates are present" do
      stub_const("Messaging::Bsnl::DltTemplate::BSNL_TEMPLATES", {
        "en.a.template.name.1" => {"Template_Id" => "a template id",
                                   "Template_Keys" => %w[key_1 key_2],
                                   "Non_Variable_Text_Length" => "10",
                                   "Max_Length_Permitted" => "20",
                                   "Version" => 1,
                                   "Is_Latest_Version" => true,
                                   "Latest_Template_Version" => "en.a.template.name.3"}
      })

      expect(described_class.latest_name_of("en.a.template.name")).to eq("en.a.template.name.3")
      expect(described_class.latest_name_of("en.a.template.name.2")).to eq("en.a.template.name.3")
    end
  end

  describe ".drop_version_number" do
    it "returns the name of the template without the version suffix" do
      expect(described_class.drop_version_number("en.a.template.name.1")).to eq("en.a.template.name")
      expect(described_class.drop_version_number("en.a.template.name.200")).to eq("en.a.template.name")
      expect(described_class.drop_version_number("en.a.template.name.text-suffix")).to eq("en.a.template.name.text-suffix")
      expect(described_class.drop_version_number("en.a.template.name.text-suffix.1")).to eq("en.a.template.name.text-suffix")
    end
  end

  describe ".version_number" do
    it "returns the version number of the template, defaults to the initial version number" do
      expect(described_class.version_number("en.a.template.name")).to eq(1)
      expect(described_class.version_number("en.a.template.name.1")).to eq(1)
      expect(described_class.version_number("en.a.template.name.200")).to eq(200)
      expect(described_class.version_number("en.a.template.name.text-suffix")).to eq(1)
    end
  end

  describe "#sanitised_variable_content" do
    it "calls validation methods" do
      template_name = "en.a.template.name"
      stub_template(template_name)
      template = described_class.new(template_name)
      content = {a: "hash"}

      allow(template).to receive(:check_variables_presence).and_return(content)
      allow(template).to receive(:trim_variables).and_return(content)
      allow(template).to receive(:limit_total_variable_length).and_return(content)
      allow(template).to receive(:check_total_variable_length).and_return(content)

      expect(template).to receive(:check_variables_presence).with(content)
      expect(template).to receive(:trim_variables).with(content)
      expect(template).to receive(:limit_total_variable_length).with(content)
      expect(template).to receive(:check_total_variable_length).with(content)

      expect(template.sanitised_variable_content(content)).to eq([{"Key" => "a", "Value" => "hash"}])
    end
  end

  describe "#check_variables_presence" do
    it "raises an error if all the variables that the template requires have not been provided" do
      template_name = "en.a.template.name"
      stub_template(template_name)
      template = described_class.new(template_name)

      expect { template.check_variables_presence({key_1: "Value 1"}) }
        .to raise_error(an_instance_of(Messaging::Bsnl::MissingVariablesError)) do |error|
        expect(error.reason).to be_nil
        expect(/Variables key_2 not provided to #{template_name}/).to match(error.message)
      end
    end

    it "does not raise an error if all the variables have been provided" do
      template_name = "en.a.template.name"
      stub_template(template_name)
      template = described_class.new(template_name)

      expect { template.check_variables_presence({key_1: "Value 1", key_2: "Value 2"}) }.not_to raise_error(Messaging::Bsnl::MissingVariablesError)
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
