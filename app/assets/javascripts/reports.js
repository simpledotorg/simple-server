window.addEventListener("DOMContentLoaded", initializeCharts);

let lightGreenColor = "rgba(242, 248, 245, 1)";
let darkGreenColor = "rgba(0, 122, 49, 1)";
let mediumGreenColor = "rgba(92, 255, 157, 1)";
let lightRedColor = "rgba(255, 235, 238, 1)";
let darkRedColor = "rgba(255, 51, 85, 1)";
let darkGreyColor = "rgba(108, 115, 122, 1)";
let mediumGreyColor = "rgba(173, 178, 184, 1)";
let lightGreyColor = "rgba(240, 242, 245, 1)";

function initializeCharts() {
  const data = getReportingData();

  const controlledGraphConfig = createGraphConfig([{
    data: data.controlRate,
    rgbaLineColor: darkGreenColor,
    rgbaBackgroundColor: lightGreenColor,
    label: "control rate",
  }], "line");
  controlledGraphConfig.options = createGraphOptions(
    data.controlRate,
    data.controlledPatients,
    false,
  );
  const controlledGraphCanvas = document.getElementById("controlledPatientsTrend");
  if (controlledGraphCanvas) {
    new Chart(controlledGraphCanvas.getContext("2d"), controlledGraphConfig);
  }

  const uncontrolledGraphConfig = createGraphConfig([
    {
      data: data.uncontrolledRate,
      rgbaBackgroundColor: lightRedColor,
      rgbaLineColor: darkRedColor,
      label: "not under control rate",
    }
  ], "line");
  uncontrolledGraphConfig.options = createGraphOptions(
    data.uncontrolledRate,
    data.uncontrolledPatients,
    false,
  );
  const uncontrolledGraphCanvas = document.getElementById("uncontrolledPatientsTrend");
  if (uncontrolledGraphCanvas) {
    new Chart(uncontrolledGraphCanvas.getContext("2d"), uncontrolledGraphConfig);
  }

  const visitDetailsGraphConfig = createGraphConfig([
    {
      data: data.controlRate,
      rgbaBackgroundColor: mediumGreenColor,
      rgbaLineColor: mediumGreenColor,
      label: "control rate",
    },
    {
      data: data.uncontrolledRate,
      rgbaBackgroundColor: darkRedColor,
      rgbaLineColor: darkRedColor,
      label: "not under control rate",
    },
  ], "bar");
  visitDetailsGraphConfig.options = createGraphOptions(
   data.uncontrolledRate,
   data.uncontrolledPatients,
   true,
  );
  const visitDetailsGraphCanvas = document.getElementById("missedVisitDetails");
  if (visitDetailsGraphCanvas) {
    new Chart(visitDetailsGraphCanvas.getContext("2d"), visitDetailsGraphConfig);
  }
};

function getReportingData() {
  const $reportingDiv = document.getElementById("reporting");
  const $newData = document.getElementById("data-json");
  const jsonData = JSON.parse($newData.textContent);

  const controlRate = jsonData.controlled_patients_rate;
  const controlledPatients = jsonData.controlled_patients;
  const registrations = jsonData.registrations;
  const uncontrolledRate = jsonData.uncontrolled_patients_rate;
  const uncontrolledPatients = jsonData.uncontrolled_patients;

  let data = {
    controlRate: controlRate,
    controlledPatients: controlledPatients,
    registrations: registrations,
    uncontrolledRate: uncontrolledRate,
    uncontrolledPatients: uncontrolledPatients,
  };

  return data;
};

function createGraphConfig(datasetsConfig, graphType, label) {
  return {
    type: graphType,
    data: {
      labels: Object.keys(datasetsConfig[0].data),
      datasets: datasetsConfig.map(dataset => {
        return {
          label: dataset.label,
          backgroundColor: dataset.rgbaBackgroundColor,
          borderColor: dataset.rgbaLineColor,
          borderWidth: 1,
          pointBackgroundColor: dataset.rgbaLineColor,
          data: Object.values(dataset.data),
        };
      }),
    },
  };
};

function createGraphOptions(rates, counts, isStacked) {
  return {
    animation: false,
    responsive: true,
    maintainAspectRatio: false,
    layout: {
      padding: {
        left: 0,
        right: 0,
        top: 0,
        bottom: 0
      }
    },
    elements: {
      point: {
        pointStyle: "circle",
        backgroundColor: "rgba(81, 205, 130, 1)",
        hoverRadius: 5,
      },
    },
    legend: {
      display: false,
    },
    scales: {
      xAxes: [{
        stacked: isStacked,
        display: true,
        gridLines: {
          display: true,
          drawBorder: false,
        },
        ticks: {
          fontColor: "#ADB2B8",
          fontSize: 14,
          fontFamily: "Roboto Condensed",
          maxRotation: 0,
          minRotation: 0
        }
      }],
      yAxes: [{
        stacked: isStacked,
        display: true,
        gridLines: {
          display: true,
          drawBorder: false,
        },
        ticks: {
          fontColor: "#ADB2B8",
          fontSize: 12,
          fontFamily: "Roboto Condensed",
          stepSize: 25,
          suggestedMax: 100,
          suggestedMin: 0,
          callback: function(value, index, values) {
            return value + "%";
          }
        }
      }],
    },
    tooltips: {
      backgroundColor: "rgb(0, 0, 0)",
      bodyAlign: "center",
      bodyFontFamily: "Roboto Condensed",
      bodyFontSize: 12,
      caretSize: 6,
      displayColors: false,
      position: "nearest",
      titleAlign: "center",
      titleFontFamily: "Roboto Condensed",
      titleFontSize: 16,
      xAlign: "center",
      xPadding: 12,
      yAlign: "bottom",
      yPadding: 12,
      callbacks: {
        title: function() {},
        label: function(tooltipItem, data) {
          const datasetIndex = tooltipItem.datasetIndex;
          const index = tooltipItem.index;
          const date = Object.keys(rates)[index];
          const count = Object.values(counts)[index];
          const percent = Math.round(tooltipItem.value);
          return `${percent}% ${data.datasets[datasetIndex].label} (${count} patients) in ${date}`;
        },
      },
    }
  };
};