require "rspec"

describe "SimpleServer::Application" do
  describe I18n do
    describe "#default_locale" do
      it "defaults to english locale" do
        expect(I18n.default_locale).to eq(:en)
      end
    end
  end
end
