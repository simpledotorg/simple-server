require "rails_helper"
require_relative Rails.root.join("spec/support/experiment_data_examples.rb")

RSpec.describe ExperimentResultsMailer, type: :model do
  describe "#mail_csv" do
    include_context "active experiment data"

    it "formats the email and attachment correctly" do
      recipient_email_address = "person@example.com"
      filename = @experiment.name.tr(" ", "_") + ".csv"
      expected_file_contents = %(Experiment Name,Treatment Group,Experiment Inclusion Date,\
Appointment 1 Creation Date,Appointment 1 Date,Appointment 2 Creation Date,Appointment 2 Date,Blood Pressure 1 Date,\
Blood Pressure 2 Date,Blood Pressure 3 Date,Message 1 Type,Message 1 Date Sent,Message 1 Status,\
Message 1 Text Identifier,Message 2 Type,Message 2 Date Sent,Message 2 Status,Message 2 Text Identifier,\
Message 3 Type,Message 3 Date Sent,Message 3 Status,Message 3 Text Identifier,Message 4 Type,Message 4 Date Sent,\
Message 4 Status,Message 4 Text Identifier,Patient Gender,Patient Age,Patient Risk Level,Assigned Facility Name,\
Assigned Facility Type,Assigned Facility State,Assigned Facility District,Assigned Facility Block,\
Patient Registration Date,Patient Id\r\nexportable,control,2020-12-31,2020-12-25,2021-01-08,2020-12-25,2021-01-15,\
2020-05-01,2020-10-01,2021-01-10,,,,,,,,,,,,,,,,,female,60,1,Bangalore Clinic,City,Karnataka,South,Red Zone,\
2020-01-01,#{@control_patient.treatment_group_memberships.last.id}\r\nexportable,single message,2020-12-31,\
2021-08-19,2021-01-15,,,2020-07-01,,,whatsapp,2021-01-14,read,single group message,,,,,,,,,,,,,male,70,1,Goa Clinic,\
Village,Goa,South,Blue Zone,2020-01-01,#{@single_message_patient.treatment_group_memberships.last.id}\r\n\
exportable,cascade,2020-12-31,2021-08-19,2021-01-22,,,2020-11-01,,,whatsapp,2021-01-21,failed,cascade 1,sms,\
2021-01-21,delivered,cascade 1,whatsapp,2021-01-22,failed,cascade 2,sms,2021-01-22,delivered,cascade 2,female,50,1,\
Bangalore Clinic,City,Karnataka,South,Red Zone,2020-01-01,#{@cascade_patient.treatment_group_memberships.last.id}\r\n)

      expect_any_instance_of(Mail::Message).to receive(:deliver)

      service = described_class.new(@experiment.name, recipient_email_address)
      mailer = service.mailer
      service.mail_csv
      attachment = mailer.mail.attachments.first

      expect(attachment.filename).to eq(filename)
      expect(attachment.body.to_s).to eq(expected_file_contents)
      expect(mailer.mail.to).to eq([recipient_email_address])
      expect(mailer.mail.subject).to eq("Experiment data export: exportable")
      expect(mailer.mail.body.to_s).to eq("Please see attached CSV.")
    end
  end
end
