window.addEventListener("DOMContentLoaded", initializeCharts);

var lightGreenColor = "rgba(242, 248, 245, 1)";
var darkGreenColor = "rgba(0, 122, 49, 1)";
var lightRedColor = "rgba(255, 235, 238, 1)";
var darkRedColor = "rgba(255, 51, 85, 1)";

function initializeCharts() {
  const data = getReportingData();

  const controlledGraphConfig = createGraphConfig(data.controlRate, darkGreenColor, lightGreenColor);
  controlledGraphConfig.options = createGraphOptions(data.controlRate, "control rate");
  const controlledGraphCanvas =
    document.getElementById("controlledPatientsTrend").getContext("2d");
  new Chart(controlledGraphCanvas, controlledGraphConfig);

  const uncontrolledGraphConfig = createGraphConfig(data.controlRate, darkRedColor, lightRedColor);
  uncontrolledGraphConfig.options = createGraphOptions(data.controlRate, "control rate");
  const uncontrolledGraphCanvas =
    document.getElementById("uncontrolledPatientsTrend").getContext("2d");
  new Chart(uncontrolledGraphCanvas, uncontrolledGraphConfig);
};

function getReportingData() {
  const $reportingDiv = document.getElementById("reporting");
  const controlRate =
    JSON.parse($reportingDiv.attributes.getNamedItem("data-control-rate").value);
  const controlledPatients = 
    JSON.parse($reportingDiv.attributes.getNamedItem("data-controlled-patients").value);
  const registrations =
    JSON.parse($reportingDiv.attributes.getNamedItem("data-registrations").value);
  
  let data = {
    controlRate: Object.entries(controlRate),
    controlledPatients: Object.entries(controlledPatients),
    registrations: Object.entries(registrations),
  };

  return data;
};

function createGraphConfig(data, rgbaLineColor, rgbaBackgroundColor) {
  return {
    type: "line",
    data: {
      labels: data.map(key => key[0]),
      datasets: [{
        backgroundColor: rgbaBackgroundColor,
        borderColor: rgbaLineColor,
        borderWidth: 1,
        pointBackgroundColor: rgbaLineColor,
        data: data.map(key => key[1]),
      }],
    },
  };
};

function createGraphOptions(data, label) {
  return {
    animation: false,
    responsive: true,
    maintainAspectRatio: false,
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
        display: false,
        gridLines: {
          display: false,
          drawBorder: false,
        },
      }],
      yAxes: [{
        display: false,
        gridLines: {
          display: false,
          drawBorder: false,
        },
        ticks: {
          suggestedMin: 0,
          suggestedMax: 60
        }
      }],
    },
    tooltips: {
      caretSize: 6,
      position: "average",
      yAlign: "bottom",
      xAlign: "center",
      titleFontFamily: "Roboto Condensed",
      bodyFontFamily: "Roboto Condensed",
      backgroundColor: "rgb(0, 0, 0)",
      titleFontSize: 16,
      bodyFontSize: 14,
      titleAlign: "center",
      bodyAlign: "center",
      displayColors: false,
      yPadding: 12,
      xPadding: 12,
      callbacks: {
        title: function() {},
        label: function(tooltipItem, _) {
          const date = data.map(key => key[0])[tooltipItem.index];
          const value = data.map(key => key[1])[tooltipItem.index];
          const formattedValue = value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
          const percent = parseInt(tooltipItem.value).toFixed(0);
          return `${percent}% ${label} (${formattedValue} patients) in ${date}`;
        },
      },
    }
  };
};