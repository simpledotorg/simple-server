require "rails_helper"
require "tasks/scripts/get_bsnl_account_balance"

RSpec.describe GetBsnlAccountBalance do
  describe "#call" do
    context "SMS Balance is close to expiry" do
      it "raises an error" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("BSNL_IHCI_HEADER").and_return("ABCDEF")
        allow(ENV).to receive(:[]).with("BSNL_IHCI_ENTITY_ID").and_return("123")
        Configuration.create(name: "bsnl_sms_jwt", value: "a jwt token")
        stub_const("GetBsnlAccountBalance::BALANCE_EXPIRY_ALERT_DAYS", 7)
        expiry_date = 3.days.from_now
        stub_request(:post, "https://bulksms.bsnl.in:5010/api/Get_SMS_Count")
          .to_return(body: {"Recharge_Details" => [{"Balance_Expiry_Time" => expiry_date}]}.to_json)

        expect { described_class.new.call }.to raise_error(Messaging::Bsnl::BalanceError, "Account balance is going to expire in less than 7 days. Please extend validity before #{expiry_date.strftime("%d-%b-%y")}")
      end
    end

    context "SMS Balance is not close to expiry" do
      it "doesn't raise an error" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("BSNL_IHCI_HEADER").and_return("ABCDEF")
        allow(ENV).to receive(:[]).with("BSNL_IHCI_ENTITY_ID").and_return("123")
        Configuration.create(name: "bsnl_sms_jwt", value: "a jwt token")
        stub_const("GetBsnlAccountBalance::BALANCE_EXPIRY_ALERT_DAYS", 7)
        stub_const("GetBsnlAccountBalance::MAX_DAILY_MESSAGE_SEGMENT_COUNT", 10)
        expiry_date = 10.days.from_now
        stub_request(:post, "https://bulksms.bsnl.in:5010/api/Get_SMS_Count")
          .to_return(body: {"Recharge_Details" => [{"Balance_Expiry_Time" => expiry_date, "SMS_Balance_Count" => 1000}]}.to_json)

        expect { described_class.new.call }.not_to raise_error
      end
    end

    context "SMS Balance is running low" do
      it "raises an error" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("BSNL_IHCI_HEADER").and_return("ABCDEF")
        allow(ENV).to receive(:[]).with("BSNL_IHCI_ENTITY_ID").and_return("123")
        Configuration.create(name: "bsnl_sms_jwt", value: "a jwt token")
        stub_const("GetBsnlAccountBalance::BALANCE_EXPIRY_ALERT_DAYS", 7)
        stub_const("GetBsnlAccountBalance::MAX_DAILY_MESSAGE_SEGMENT_COUNT", 1000)
        expiry_date = 30.days.from_now
        stub_request(:post, "https://bulksms.bsnl.in:5010/api/Get_SMS_Count")
          .to_return(body: {"Recharge_Details" => [{"Balance_Expiry_Time" => expiry_date, "SMS_Balance_Count" => 1000}]}.to_json)

        expect { described_class.new.call }.to raise_error(Messaging::Bsnl::BalanceError, "Account balance remaining is 1000 segments, may run out in less than 7 days")
      end
    end

    context "SMS Balance is sufficient" do
      it "doesn't raise an error" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("BSNL_IHCI_HEADER").and_return("ABCDEF")
        allow(ENV).to receive(:[]).with("BSNL_IHCI_ENTITY_ID").and_return("123")
        Configuration.create(name: "bsnl_sms_jwt", value: "a jwt token")
        stub_const("GetBsnlAccountBalance::BALANCE_EXPIRY_ALERT_DAYS", 7)
        stub_const("GetBsnlAccountBalance::MAX_DAILY_MESSAGE_SEGMENT_COUNT", 10)
        expiry_date = 10.days.from_now
        stub_request(:post, "https://bulksms.bsnl.in:5010/api/Get_SMS_Count")
          .to_return(body: {"Recharge_Details" => [{"Balance_Expiry_Time" => expiry_date, "SMS_Balance_Count" => 1000}]}.to_json)

        expect { described_class.new.call }.not_to raise_error
      end
    end

    context "There are multiple balances" do
      it "adds the balances" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("BSNL_IHCI_HEADER").and_return("ABCDEF")
        allow(ENV).to receive(:[]).with("BSNL_IHCI_ENTITY_ID").and_return("123")
        Configuration.create(name: "bsnl_sms_jwt", value: "a jwt token")
        stub_const("GetBsnlAccountBalance::BALANCE_EXPIRY_ALERT_DAYS", 7)
        stub_const("GetBsnlAccountBalance::MAX_DAILY_MESSAGE_SEGMENT_COUNT", 1000)
        expiry_date = 10.days.from_now
        stub_request(:post, "https://bulksms.bsnl.in:5010/api/Get_SMS_Count")
          .to_return(body:  {"Recharge_Details" => [{"Balance_Expiry_Time" => expiry_date, "SMS_Balance_Count" => 1000},
            {"Balance_Expiry_Time" => expiry_date + 10.days, "SMS_Balance_Count" => 1000}]}.to_json)

        expect { described_class.new.call }.to raise_error(Messaging::Bsnl::BalanceError, "Account balance remaining is 2000 segments, may run out in less than 7 days")
      end

      it "picks up the last expiry date" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("BSNL_IHCI_HEADER").and_return("ABCDEF")
        allow(ENV).to receive(:[]).with("BSNL_IHCI_ENTITY_ID").and_return("123")
        Configuration.create(name: "bsnl_sms_jwt", value: "a jwt token")
        stub_const("GetBsnlAccountBalance::BALANCE_EXPIRY_ALERT_DAYS", 7)
        stub_const("GetBsnlAccountBalance::MAX_DAILY_MESSAGE_SEGMENT_COUNT", 10)
        expiry_date = 3.days.from_now
        expiry_date_2 = expiry_date + 2.days
        stub_request(:post, "https://bulksms.bsnl.in:5010/api/Get_SMS_Count")
          .to_return(body:  {"Recharge_Details" => [{"Balance_Expiry_Time" => expiry_date_2, "SMS_Balance_Count" => 1000},
            {"Balance_Expiry_Time" => expiry_date, "SMS_Balance_Count" => 1000}]}.to_json)

        expect { described_class.new.call }.to raise_error(Messaging::Bsnl::BalanceError, "Account balance is going to expire in less than 7 days. Please extend validity before #{expiry_date_2.strftime("%d-%b-%y")}")
      end
    end
  end
end
