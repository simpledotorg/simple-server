require "rails_helper"

RSpec.describe DrRai::ActionsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/dr_rai/actions").to route_to("dr_rai/actions#index")
    end

    it "routes to #create" do
      expect(post: "/dr_rai/actions").to route_to("dr_rai/actions#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/dr_rai/actions/1").to route_to("dr_rai/actions#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/dr_rai/actions/1").to route_to("dr_rai/actions#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/dr_rai/actions/1").to route_to("dr_rai/actions#destroy", id: "1")
    end
  end
end
