const greyColor = "#6c737a";
const greenColor = "#007a31";
const redColor = "#b81631";

window.addEventListener("DOMContentLoaded", function() {
  let facilityRateData = {};
  const $facilityRows = document.querySelectorAll('[data-row]');

  Array.from($facilityRows).forEach($facilityRow => {
    let rateValues = [];
    const facilitySlug = $facilityRow.getAttribute("data-row");
    const trendLineColor = $facilityRow.getAttribute("data-trend-color");
    const $rates = $facilityRow.querySelectorAll('[data-rate]');

    Array.from($rates).forEach($rate => {
      rateValues.push($rate.getAttribute("data-rate"));
    });

    facilityRateData[facilitySlug] = {};
    facilityRateData[facilitySlug].color = trendLineColor;
    facilityRateData[facilitySlug].data = rateValues;
  });

  Object.keys(facilityRateData).forEach(facility => {
    const trendChartConfig = createBaseTrendChartConfig();
    trendChartConfig.data = {
      labels: facilityRateData[facility].data,
      datasets: [{
        fill: false,
        borderWidth: 1.5,
        borderColor: getHexCodeFromColorName(facilityRateData[facility].color),
        data: facilityRateData[facility].data,
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
          tension: 0.4,
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
      events: [],
      legend: {
        display: false
      },
      plugins: {
        tooltip:  false,
      },
      scales: {
        x: { display: false },
        y: { display: false },
      },
    },
  };
};

function getHexCodeFromColorName(colorName) {
  switch(colorName) {
    case "green":
      return greenColor;
    case "red":
      return redColor;
    case "grey":
      return greyColor;
    default:
      break;
  };
};