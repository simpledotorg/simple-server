window.addEventListener("DOMContentLoaded", initializeCharts);

let lightGreenColor = "rgba(242, 248, 245, 1)";
let darkGreenColor = "rgba(0, 122, 49, 1)";
let mediumGreenColor = "rgba(92, 255, 157, 1)";
let lightRedColor = "rgba(255, 235, 238, 1)";
let darkRedColor = "rgba(255, 51, 85, 1)";
let lightPurpleColor = "rgba(238, 229, 252, 1)";
let darkPurpleColor = "#5300E0";
let darkGreyColor = "rgba(108, 115, 122, 1)";
let mediumGreyColor = "rgba(173, 178, 184, 1)";
let lightGreyColor = "rgba(240, 242, 245, 1)";

function initializeCharts() {
  const data = getReportingData();

  const controlledGraphConfig = createGraphConfig([{
    data: data.controlRate,
    borderWidth: 1,
    rgbaLineColor: darkGreenColor,
    rgbaBackgroundColor: lightGreenColor,
    label: "control rate",
  }], "line");
  controlledGraphConfig.options = createGraphOptions(
    false,
    25,
    100,
    formatValueAsPercent,
    formatRateTooltipText,
    [data.controlledPatients],
  );
  const controlledGraphCanvas = document.getElementById("controlledPatientsTrend");
  if (controlledGraphCanvas) {
    new Chart(controlledGraphCanvas.getContext("2d"), controlledGraphConfig);
  }

  const noBPMeasureGraphConfig = createGraphConfig([
    {
      data: data.visitButNoBPMeasureRate,
      rgbaBackgroundColor: darkGreyColor,
      hoverBackgroundColor: darkGreyColor,
      label: "visited but no BP measure",
    },
    {
      data: data.missedVisitsRate,
      rgbaBackgroundColor: mediumGreyColor,
      rgbaLineColor: mediumGreyColor,
      label: "Missed visit",
    },
  ], "bar");
  noBPMeasureGraphConfig.options = createGraphOptions(
    true,
    25,
    100,
    formatValueAsPercent,
    formatRateTooltipText,
    [data.visitButNoBPMeasure, data.missedVisits],
  );

  const noBPMeasureGraphCanvas = document.getElementById("noBPMeasureTrend");
  if (noBPMeasureGraphCanvas) {
    new Chart(noBPMeasureGraphCanvas.getContext("2d"), noBPMeasureGraphConfig);
  }

  const uncontrolledGraphConfig = createGraphConfig([
    {
      data: data.uncontrolledRate,
      rgbaBackgroundColor: lightRedColor,
      borderWidth: 1,
      rgbaLineColor: darkRedColor,
      label: "not under control rate",
    }
  ], "line");
  uncontrolledGraphConfig.options = createGraphOptions(
    false,
    25,
    100,
    formatValueAsPercent,
    formatRateTooltipText,
    [data.uncontrolledPatients],
  );
  const uncontrolledGraphCanvas = document.getElementById("uncontrolledPatientsTrend");
  if (uncontrolledGraphCanvas) {
    new Chart(uncontrolledGraphCanvas.getContext("2d"), uncontrolledGraphConfig);
  }

  const maxRegistrations = Math.max(...Object.values(data.registrations));
  const suggestedMax = Math.round(maxRegistrations) * 1.15;
  const stepSize = Math.round(suggestedMax / 3);
  const cumulativeRegistrationsGraphConfig = createGraphConfig([
    {
      data: data.registrations,
      rgbaBackgroundColor: lightPurpleColor,
      borderWidth: { top: 2 },
      rgbaLineColor: darkPurpleColor,
      hoverBackgroundColor: lightPurpleColor,
    },
  ], "bar");
  cumulativeRegistrationsGraphConfig.options = createGraphOptions(
    false,
    stepSize,
    suggestedMax,
    formatNumberWithCommas,
    formatSumTooltipText,
  );
  const cumulativeRegistrationsGraphCanvas = document.getElementById("cumulativeRegistrationsTrend");
  if (cumulativeRegistrationsGraphCanvas) {
    new Chart(cumulativeRegistrationsGraphCanvas.getContext("2d"), cumulativeRegistrationsGraphConfig);
  }

  const visitDetailsGraphConfig = createGraphConfig([
    {
      data: data.controlRate,
      rgbaBackgroundColor: mediumGreenColor,
      hoverBackgroundColor: mediumGreenColor,
      label: "control rate",
    },
    {
      data: data.uncontrolledRate,
      rgbaBackgroundColor: darkRedColor,
      hoverBackgroundColor: darkRedColor,
      label: "not under control rate",
    },
    {
      data: data.visitButNoBPMeasureRate,
      rgbaBackgroundColor: darkGreyColor,
      hoverBackgroundColor: darkGreyColor,
      label: "Visited but no BP measure",
    },
    {
      data: data.missedVisitsRate,
      rgbaBackgroundColor: mediumGreyColor,
      hoverBackgroundColor: mediumGreyColor,
      label: "Missed visit",
    }
  ], "bar");
  visitDetailsGraphConfig.options = createGraphOptions(
    true,
    25,
    100,
    formatValueAsPercent,
    formatRateTooltipText,
    [data.controlledPatients, data.uncontrolledPatients, data.visitButNoBPMeasure, data.missedVisits],
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
  const registrations = jsonData.cumulative_registrations;
  const uncontrolledRate = jsonData.uncontrolled_patients_rate;
  const uncontrolledPatients = jsonData.uncontrolled_patients;

  let data = {
    controlRate: controlRate,
    controlledPatients: controlledPatients,
    missedVisits: jsonData.missed_visits,
    missedVisitsRate: jsonData.missed_visits_rate,
    registrations: registrations,
    uncontrolledRate: uncontrolledRate,
    uncontrolledPatients: uncontrolledPatients,
    visitButNoBPMeasure: jsonData.visited_without_bp_taken,
    visitButNoBPMeasureRate: jsonData.visited_without_bp_taken_rate
  };

  return data;
};

function createGraphConfig(datasetsConfig, graphType) {
  return {
    type: graphType,
    data: {
      labels: Object.keys(datasetsConfig[0].data),
      datasets: datasetsConfig.map(dataset => {
        return {
          label: dataset.label,
          backgroundColor: dataset.rgbaBackgroundColor,
          borderColor: dataset.rgbaLineColor ? dataset.rgbaLineColor : undefined,
          borderWidth: dataset.borderWidth ? dataset.borderWidth : undefined,
          pointBackgroundColor: dataset.rgbaLineColor,
          hoverBackgroundColor: dataset.hoverBackgroundColor,
          data: Object.values(dataset.data),
        };
      }),
    },
  };
};

function createGraphOptions(isStacked, stepSize, suggestedMax, tickCallbackFunction, tooltipCallbackFunction, dataSum) {
  return {
    animation: false,
    responsive: true,
    maintainAspectRatio: false,
    layout: {
      padding: {
        left: 0,
        right: 0,
        top: 40,
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
          fontSize: 12,
          fontFamily: "Roboto Condensed",
          padding: 8,
          maxRotation: 0,
          minRotation: 0,
          autoSkip: true,
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
          padding: 8,
          stepSize,
          suggestedMax,
          suggestedMin: 0,
          callback: tickCallbackFunction,
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
        title: function () { },
        label: function (tooltipItem, data) {
          return tooltipCallbackFunction(tooltipItem, data, dataSum);
        },
      },
    }
  };
};

function formatRateTooltipText(tooltipItem, data, sumData) {
  const datasetIndex = tooltipItem.datasetIndex;
  const total = formatNumberWithCommas(sumData[datasetIndex][tooltipItem.label]);
  const label = data.datasets[datasetIndex].label.toLowerCase();
  const percent = Math.round(tooltipItem.value);
  return `${percent}% ${label} (${total} patients)`;
}

function formatSumTooltipText(tooltipItem) {
  return `${formatNumberWithCommas(tooltipItem.value)} patients registered in ${tooltipItem.label}`;
}

function formatValueAsPercent(value) {
  return `${value}%`;
}

function formatNumberWithCommas(value) {
  return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}
