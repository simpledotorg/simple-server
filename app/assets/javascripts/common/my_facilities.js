window.addEventListener("DOMContentLoaded", function() {
  let controlRateData = {};
  const $facilityRows = document.querySelectorAll('[data-row]');

  Array.from($facilityRows).forEach($facilityRow => {
    let controlRateValues = [];
    const facilitySlug = $facilityRow.getAttribute("data-row");
    const $controlRates = $facilityRow.querySelectorAll('[data-control-rate]');

    Array.from($controlRates).forEach($controlRate => {
      controlRateValues.push($controlRate.innerText);
    });

    controlRateData[facilitySlug] = controlRateValues;
  });

  Object.keys(controlRateData).forEach(facilitySlug => {
    const trendChartConfig = createBaseTrendChartConfig();
    trendChartConfig.data = {
      labels: controlRateData[facilitySlug],
      datasets: [{
        label: "BP controlled rate",
        fill: false,
        data: controlRateData[facilitySlug],
      }],
    };
    trendChartConfig.options.scales = {
      xAxes: [{ display: false }],
      yAxes: [{ display: false }],
    };

    const trendChartCanvas = document.getElementById(facilitySlug);
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
      elements: { point: { radius: 0, }},
      responsive: true,
      maintainAspectRatio: false,
      layout: { padding: { top: 2, right: 2, bottom: 2, left: 2, }},
      legend: { display: false },
    },
  };
};