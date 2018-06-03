require "rails_helper"

RSpec.describe FacilitiesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/facilities").to route_to("facilities#index")
    end

    it "routes to #new" do
      expect(:get => "/facilities/new").to route_to("facilities#new")
    end

    it "routes to #show" do
      expect(:get => "/facilities/1").to route_to("facilities#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/facilities/1/edit").to route_to("facilities#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/facilities").to route_to("facilities#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/facilities/1").to route_to("facilities#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/facilities/1").to route_to("facilities#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/facilities/1").to route_to("facilities#destroy", :id => "1")
    end

  end
end
