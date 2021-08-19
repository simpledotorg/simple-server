require "rails_helper"
require_relative Rails.root.join("spec/support/experiment_data_examples.rb")

RSpec.describe Experimentation::DataExportWorker, type: :model do
  describe "#perform" do
    include_context "active experiment data"

    it "sends the email successfully" do
      expect_any_instance_of(Mail::Message).to receive(:deliver)
      described_class.perform_async(@experiment.name, recipient_email_address = "person@example.com")
      described_class.drain
    end

    it "formats the email and attachment correctly" do
      recipient_email_address = "person@example.com"
      email_params = {
        to: recipient_email_address,
        subject: "Experiment data export: #{@experiment.name}",
        content_type: "multipart/mixed",
        body: "Please see attached CSV."
      }
      expected_file_contents =
%Q(Experiment Name,Treatment Group,Experiment Inclusion Date,Appointment 1 Creation Date,Appointment 1 Date,\
Appointment 2 Creation Date,Appointment 2 Date,Blood Pressure 1 Date,Blood Pressure 2 Date,Blood Pressure 3 Date,\
Message 1 Type,Message 1 Date Sent,Message 1 Status,Message 1 Text Identifier,Message 2 Type,Message 2 Date Sent,\
Message 2 Status,Message 2 Text Identifier,Message 3 Type,Message 3 Date Sent,Message 3 Status,\
Message 3 Text Identifier,Message 4 Type,Message 4 Date Sent,Message 4 Status,Message 4 Text Identifier,\
Patient Gender,Patient Age,Patient Risk Level,Assigned Facility Name,Assigned Facility Type,Assigned Facility State,\
Assigned Facility District,Assigned Facility Block,Patient Registration Date,Patient Id\nexportable,control,\
2020-12-31,2020-12-25,2021-01-08,2020-12-25,2021-01-15,2020-05-01,2020-10-01,2021-01-10,,,,,,,,,,,,,,,,,female,60,1,\
Bangalore Clinic,City,Karnataka,South,Red Zone,2020-01-01,#{@control_patient.treatment_group_memberships.last.id}\n\
exportable,single message,2020-12-31,2021-08-19,2021-01-15,,,2020-07-01,,,whatsapp,2021-01-14,read,\
single group message,,,,,,,,,,,,,male,70,1,Goa Clinic,Village,Goa,South,Blue Zone,2020-01-01,\
#{@single_message_patient.treatment_group_memberships.last.id}\nexportable,cascade group,2020-12-31,2021-08-19,\
2021-01-22,,,2020-11-01,,,whatsapp,2021-01-21,failed,cascade 1,sms,2021-01-21,delivered,cascade 1,whatsapp,2021-01-22,\
failed,cascade 2,sms,2021-01-22,delivered,cascade 2,female,50,1,Bangalore Clinic,City,Karnataka,South,Red Zone,\
2020-01-01,#{@cascade_patient.treatment_group_memberships.last.id}\n)
      attachment_data = {
        mime_type: "text/csv",
        content: expected_file_contents
      }
      filename = @experiment.name.gsub(" ", "_") + ".csv"

      attachments_double = double("attachments")
      email_double = double("email", attachments: attachments_double, deliver: nil)
      mailer = instance_double(ApplicationMailer, mail: email_double)
      allow(ApplicationMailer).to receive(:new).and_return(mailer)

      expect(attachments_double).to receive(:[]=).with(filename, attachment_data)

      described_class.perform_async(@experiment.name, recipient_email_address)
      described_class.drain
    end
  end
end
