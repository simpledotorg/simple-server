require "rails_helper"
require "tasks/scripts/get_bsnl_template_details"

RSpec.describe GetBsnlTemplateDetails do
  describe "#write_to_config" do
    it "massages the template details and saves it to the file as YAML" do
      templates = [{"Template_Id" => "1",
                    "Header" => "ABCDEF",
                    "Message_Type" => "SI",
                    "Template_Name" => "en.notifications.set03.basic.2",
                    "Template_Message_DLT" => "Test message",
                    "Template_Message" => nil,
                    "Template_Keys" => [],
                    "Non_Variable_Text_Length" => "0",
                    "Max_Length_Permitted" => "0",
                    "Count_Of_Keys" => "0",
                    "Create_Date" => nil,
                    "Is_Unicode" => "0",
                    "Entity_Id" => "1",
                    "Template_Status" => "0",
                    "Template_Status_Description" => "Template Variables Naming Pending"},
        {"Template_Id" => "2",
         "Header" => "ABCDEF",
         "Message_Type" => "SI",
         "Template_Name" => "en.notifications.set03.basic",
         "Template_Message_DLT" => "Test template",
         "Template_Message" => "Test message",
         "Template_Keys" => %w[facility_name patient_name],
         "Non_Variable_Text_Length" => "166",
         "Max_Length_Permitted" => "332",
         "Count_Of_Keys" => "2",
         "Create_Date" => "14-03-2022 05:42:45 PM",
         "Is_Unicode" => "0",
         "Entity_Id" => "1",
         "Template_Status" => "1",
         "Template_Status_Description" => "Template Variables Named"}]
      dbl = instance_double("MessagingBsnlApi")
      allow(Messaging::Bsnl::Api).to receive(:new).and_return(dbl)
      allow(dbl).to receive(:get_template_details).and_return(templates)

      expect(described_class.new.massaged_template_details).to eq(
        {"en.notifications.set03.basic" =>
            {"Template_Id" => "2",
             "Template_Keys" => ["facility_name", "patient_name"],
             "Non_Variable_Text_Length" => "166",
             "Max_Length_Permitted" => "332",
             "Template_Status" => "1",
             "Is_Unicode" => "0",
             "Version" => 1,
             "Is_Latest_Version" => false,
             "Latest_Template_Version" => "en.notifications.set03.basic.2"},
         "en.notifications.set03.basic.2" =>
            {"Template_Id" => "1",
             "Template_Keys" => [],
             "Non_Variable_Text_Length" => "0",
             "Max_Length_Permitted" => "0",
             "Template_Status" => "0",
             "Is_Unicode" => "0",
             "Version" => 2,
             "Is_Latest_Version" => true,
             "Latest_Template_Version" => "en.notifications.set03.basic.2"}}
      )
    end
  end
end
