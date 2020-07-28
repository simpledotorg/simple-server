window.addEventListener("DOMContentLoaded", initializeCharts);
window.addEventListener("DOMContentLoaded", setDropdownPeriodType);

var lightGreenColor = "rgba(242, 248, 245, 1)";
var darkGreenColor = "rgba(0, 122, 49, 1)";
var lightRedColor = "rgba(255, 235, 238, 1)";
var darkRedColor = "rgba(255, 51, 85, 1)";

function setDropdownPeriodType() {
  $('.dropdown-item').click(function() {
    let periodType = $(this).data("period-type");
    $("#dropdown-period-type").val(periodType);
  })
}

function initializeCharts() {
  const data = getReportingData();

  const controlledGraphConfig = createGraphConfig(data.controlRate, darkGreenColor, lightGreenColor);
  controlledGraphConfig.options = createGraphOptions(data.controlRate, data.controlledPatients, "control rate");
  const controlledGraphCanvas = document.getElementById("controlledPatientsTrend").getContext("2d");
  new Chart(controlledGraphCanvas, controlledGraphConfig);

  const uncontrolledGraphConfig = createGraphConfig(data.uncontrolledRate, darkRedColor, lightRedColor);
  uncontrolledGraphConfig.options = createGraphOptions(data.uncontrolledRate, data.uncontrolledPatients, "not under control rate");
  const uncontrolledGraphCanvas = document.getElementById("uncontrolledPatientsTrend").getContext("2d");
  new Chart(uncontrolledGraphCanvas, uncontrolledGraphConfig);
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

function createGraphConfig(data, rgbaLineColor, rgbaBackgroundColor) {
  return {
    type: "line",
    data: {
      labels: Object.keys(data),
      datasets: [{
        backgroundColor: rgbaBackgroundColor,
        borderColor: rgbaLineColor,
        borderWidth: 1,
        pointBackgroundColor: rgbaLineColor,
        data: Object.values(data),
      }],
    },
  };
};

function createGraphOptions(rates, counts, label) {
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
        label: function(tooltipItem, _) {
          const index = tooltipItem.index;
          const date = Object.keys(rates)[index];
          const count = Object.values(counts)[index];
          // const formattedValue = value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
          const percent = Math.round(tooltipItem.value);
          return `${percent}% ${label} (${count} patients) in ${date}`;
        },
      },
    }
  };
};