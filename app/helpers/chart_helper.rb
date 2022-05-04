module ChartHelper
  def chart(type, id, data, dataset_options = {}, options = {})
    chart_options = default_chart_config.deep_merge(options).deep_transform_keys { |k| k.to_s.camelize(:lower) }

    tag.canvas id: id, data: {
      render_chart: true,
      chart_type: type.to_s,
      chart_data: data,
      chart_dataset_options: dataset_options.deep_transform_keys { |k| k.to_s.camelize(:lower) }.to_json,
      chart_options: chart_options
    }
  end

  def line_chart(id, data, dataset_options = {}, options = {})
    chart(:line, id, data, options)
  end

  def pivot_period_data(data)
    results = pivot_chart_data(data)
    results.each do |period, data|
      results[period] = data.merge(period.to_hash)
    end
  end

  def pivot_chart_data(data)
    results = {}
    data.each do |outer_key, values_hash|
      values_hash.each do |inner_key, value|
        if results[inner_key]
          results[inner_key].merge!(outer_key => value)
        else
          results[inner_key] = {outer_key => value}
        end
      end
    end
    results
  end

  private

  def default_chart_config
    {
      animation: false,
      responsive: true,
      maintain_aspect_ratio: false,
      layout: {
        padding: {
          left: 0,
          right: 0,
          top: 20,
          bottom: 0
        }
      },
      elements: {
        point: {
          point_style: "circle",
          hover_radius: 5
        }
      },
      legend: {
        display: false
      },
      tooltips: {
        mode: "x",
        enabled: false
      },
      scales: {
        xAxes: [
          {
            stacked: true,
            display: true,
            gridLines: {
              display: false,
              drawBorder: true
            },
            ticks: {
              autoSkip: false,
              fontColor: dark_grey,
              fontSize: 10,
              fontFamily: "Roboto",
              padding: 8,
              min: 0,
              beginAtZero: true
            }
          }
        ],
        yAxes: [
          {
            stacked: false,
            display: true,
            gridLines: {
              display: true,
              drawBorder: false
            },
            ticks: {
              autoSkip: false,
              fontColor: dark_grey,
              fontSize: 10,
              fontFamily: "Roboto",
              padding: 8,
              min: 0,
              beginAtZero: true,
              stepSize: 25,
              max: 100
            }
          }
        ]
      }
    }
  end
end
