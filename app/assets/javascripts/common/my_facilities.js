window.addEventListener("DOMContentLoaded", function() {
  let facilityControlRateData = {};
  const greenColor = "#007a31";
  const redColor = "#b81631";
  const $facilityRows = document.querySelectorAll('[data-row]');

  Array.from($facilityRows).forEach($facilityRow => {
    let controlRateValues = [];
    const facilitySlug = $facilityRow.getAttribute("data-row");
    const trendLineColor = $facilityRow.getAttribute("data-trend-color");
    const $controlRates = $facilityRow.querySelectorAll('[data-control-rate]');

    Array.from($controlRates).forEach($controlRate => {
      controlRateValues.push($controlRate.getAttribute("data-control-rate"));
    });

    facilityControlRateData[facilitySlug] = {};
    facilityControlRateData[facilitySlug].color = trendLineColor;
    facilityControlRateData[facilitySlug].data = controlRateValues;
  });

  Object.keys(facilityControlRateData).forEach(facility => {
    const trendChartConfig = createBaseTrendChartConfig();
    trendChartConfig.data = {
      labels: facilityControlRateData[facility].data,
      datasets: [{
        label: "BP controlled rate",
        fill: false,
        borderColor: facilityControlRateData[facility].color === "green" ? greenColor : redColor,
        data: facilityControlRateData[facility].data,
      }],
    };

    const trendChartCanvas = document.getElementById(facility);
    if (trendChartCanvas) {
      new Chart(trendChartCanvas.getContext("2d"), trendChartConfig);
    }
  });
});

function createBaseTrendChartConfig() {
  return {
    type: "line",
    options: {
      animation: false,
      elements: {
        line: {
          borderJoinStyle: "round",
        },
        point: {
          radius: 0,
        },
      },
      responsive: true,
      maintainAspectRatio: false,
      layout: {
        padding: {
          top: 2,
          right: 2,
          bottom: 2,
          left: 2,
        }
      },
      legend: {
        display: false
      },
      scales: {
        xAxes: [{ display: false }],
        yAxes: [{ display: false }],
      },
    },
  };
};