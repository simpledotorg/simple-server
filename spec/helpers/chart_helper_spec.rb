require "rails_helper"

RSpec.describe ChartHelper, type: :helper do
  describe ".pivot_chart_data" do
    it "pivots the nested hash provided" do
      data = {foo: {a: 1, b: 2},
              bar: {a: 3, b: 4},
              baz: {a: 5, b: 6, c: 7}}

      expect(pivot_chart_data(data))
        .to eq({a: {foo: 1, bar: 3, baz: 5},
                b: {foo: 2, bar: 4, baz: 6},
                c: {baz: 7}})
    end
  end
end
