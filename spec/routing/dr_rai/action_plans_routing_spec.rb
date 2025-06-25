require "rails_helper"

RSpec.describe DrRai::ActionPlansController, type: :routing do
  describe "routing" do
    it "routes to #create" do
      expect(post: "/dr_rai/action_plans").to route_to("dr_rai/action_plans#create")
    end

    it "routes to #destroy" do
      expect(delete: "/dr_rai/action_plans/1").to route_to("dr_rai/action_plans#destroy", id: "1")
    end
  end
end
