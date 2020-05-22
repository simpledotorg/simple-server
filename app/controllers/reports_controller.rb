class ReportsController < ApplicationController
  layout "reports"
  def index
    @data = { march: [5,3,2,5],
      april: [234,2,3,3,3]}
    

  end
end
