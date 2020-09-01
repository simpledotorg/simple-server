window.addEventListener("DOMContentLoaded", function() {
  initializeTables();
  initializeCharts();
});

const lightGreenColor = "rgba(242, 248, 245, 1)";
const darkGreenColor = "rgba(0, 122, 49, 1)";
const mediumGreenColor = "rgba(0, 184, 73, 1)";
const lightRedColor = "rgba(255, 235, 238, 1)";
const darkRedColor = "rgba(255, 51, 85, 1)";
const lightPurpleColor = "rgba(238, 229, 252, 1)";
const darkPurpleColor = "rgba(83, 0, 224, 1)";
const darkGreyColor = "rgba(108, 115, 122, 1)";
const mediumGreyColor = "rgba(173, 178, 184, 1)";
const lightGreyColor = "rgba(240, 242, 245, 1)";

function initializeTables() {
  const tableSortConfig = { descending: true };

  const cumulativeRegistrationsTable = document.getElementById("cumulative-registrations-table");
  const htnNotUnderControlTable = document.getElementById("htn-not-under-control-table");
  const noBPMeasureTable = document.getElementById("no-bp-measure-table");
  const htnControlledTable = document.getElementById("htn-controlled-table");

  if (htnControlledTable) {
    new Tablesort(htnControlledTable, tableSortConfig);
  }

  if (noBPMeasureTable) {
    new Tablesort(noBPMeasureTable, tableSortConfig);
  }

  if (htnNotUnderControlTable) {
    new Tablesort(htnNotUnderControlTable, tableSortConfig);
  }

  if (cumulativeRegistrationsTable) {
    new Tablesort(cumulativeRegistrationsTable, tableSortConfig);
  }
};

function getReportingData() {
  const $newData = document.getElementById("data-json");
  const jsonData = JSON.parse($newData.textContent);

  return {
    controlRate: jsonData.controlled_patients_rate,
    controlledPatients: jsonData.controlled_patients,
    missedVisits: jsonData.missed_visits,
    missedVisitsRate: jsonData.missed_visits_rate,
    registrations: jsonData.cumulative_registrations,
    adjustedRegistrations: jsonData.adjusted_registrations,
    uncontrolledRate: jsonData.uncontrolled_patients_rate,
    uncontrolledPatients: jsonData.uncontrolled_patients,
    visitButNoBPMeasure: jsonData.visited_without_bp_taken,
    visitButNoBPMeasureRate: jsonData.visited_without_bp_taken_rate
  };
};

function initializeCharts() {
  const data = getReportingData();

  const controlledGraphConfig = createGraphConfig([{
    data: data.controlRate,
    borderWidth: 2,
    rgbaLineColor: mediumGreenColor,
    rgbaPointColor: lightGreenColor,
    rgbaBackgroundColor: lightGreenColor,
    label: "HTN controlled",
  }], "line");
  controlledGraphConfig.options = createGraphOptions(
    false,
    25,
    100,
    formatValueAsPercent,
    formatRateTooltipText,
    [data.controlledPatients],
    data.adjustedRegistrations,
  );

  const controlledGraphCanvas = document.getElementById("controlledPatientsTrend");
  if (controlledGraphCanvas) {
    new Chart(controlledGraphCanvas.getContext("2d"), controlledGraphConfig);
  }

  const noRecentBPConfig = createGraphConfig([
    {
      data: data.visitButNoBPMeasureRate,
      borderWidth: 0,
      rgbaLineColor: darkGreyColor,
      rgbaBackgroundColor: darkGreyColor,
      hoverBackgroundColor: darkGreyColor,
      label: "Visited in the last 3 months",
    },
    {
      data: data.missedVisitsRate,
      borderWidth: 0,
      rgbaLineColor: mediumGreyColor,
      rgbaBackgroundColor: mediumGreyColor,
      label: "No visit >3 months ago",
    },
  ], "bar");
  noRecentBPConfig.options = createGraphOptions(
    true,
    25,
    100,
    formatValueAsPercent,
    formatRateTooltipText,
    [data.visitButNoBPMeasure, data.missedVisits],
    data.adjustedRegistrations,
  );

  const noRecentBPGraphCanvas = document.getElementById("noRecentBPTrend");
  if (noRecentBPGraphCanvas) {
    new Chart(noRecentBPGraphCanvas.getContext("2d"), noRecentBPConfig);
  }

  const uncontrolledGraphConfig = createGraphConfig([
    {
      data: data.uncontrolledRate,
      borderWidth: 2,
      rgbaLineColor: darkRedColor,
      rgbaPointColor: lightRedColor,
      rgbaBackgroundColor: lightRedColor,
      label: "HTN not under control",
    }
  ], "line");

  uncontrolledGraphConfig.options = createGraphOptions(
    false,
    25,
    100,
    formatValueAsPercent,
    formatRateTooltipText,
    [data.uncontrolledPatients],
    data.adjustedRegistrations,
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
      borderWidth: { top: 2 },
      rgbaLineColor: darkPurpleColor,
      rgbaBackgroundColor: lightPurpleColor,
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
      label: "HTN controlled",
    },
    {
      data: data.uncontrolledRate,
      rgbaBackgroundColor: darkRedColor,
      hoverBackgroundColor: darkRedColor,
      label: "HTN not under control",
    },
    {
      data: data.visitButNoBPMeasureRate,
      rgbaBackgroundColor: darkGreyColor,
      hoverBackgroundColor: darkGreyColor,
      label: "Visited in the last 3 months",
    },
    {
      data: data.missedVisitsRate,
      rgbaBackgroundColor: mediumGreyColor,
      hoverBackgroundColor: mediumGreyColor,
      label: "No visit >3 months",
    }
  ], "bar");

  visitDetailsGraphConfig.options = createGraphOptions(
    true,
    25,
    100,
    formatValueAsPercent,
    formatRateTooltipText,
    [data.controlledPatients, data.uncontrolledPatients, data.visitButNoBPMeasure, data.missedVisits],
    data.adjustedRegistrations,
  );

  const visitDetailsGraphCanvas = document.getElementById("missedVisitDetails");
  if (visitDetailsGraphCanvas) {
    new Chart(visitDetailsGraphCanvas.getContext("2d"), visitDetailsGraphConfig);
  }
}

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
          pointBackgroundColor: dataset.rgbaPointColor,
          hoverBackgroundColor: dataset.hoverBackgroundColor,
          data: Object.values(dataset.data),
        };
      }),
    },
  }
}

function createGraphOptions(isStacked, stepSize, suggestedMax, tickCallbackFunction, tooltipCallbackFunction, numerators, denominators) {
  return {
    animation: false,
    responsive: true,
    maintainAspectRatio: false,
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
        pointStyle: "circle",
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
          fontColor: mediumGreyColor,
          fontSize: 12,
          fontFamily: "Roboto Condensed",
          padding: 8,
          maxRotation: 0,
          minRotation: 0,
          autoSkip: true,
          maxTicksLimit: 10
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
      mode: "index",
      intersect: false,
      position: "average",
      backgroundColor: "rgba(0,0,0,1)",
      bodyFontFamily: "Roboto Condensed",
      bodyFontSize: 12,
      caretSize: 6,
      titleFontFamily: "Roboto Condensed",
      titleFontSize: 14,
      xPadding: 10,
      yPadding: 10,
      itemSort: function (a, b) {
        return b.datasetIndex - a.datasetIndex;
      },
      callbacks: {
        label: function (tooltipItem, data) {
          return tooltipCallbackFunction(tooltipItem, data, numerators, denominators);
        },
        labelColor: formatTooltipLabelColor
      }
    }
  };
}

function formatRateTooltipText(tooltipItem, data, numerators, denominators) {
  const datasetIndex = tooltipItem.datasetIndex;
  const numerator = formatNumberWithCommas(numerators[datasetIndex][tooltipItem.label]);
  const denominator = formatNumberWithCommas(denominators[tooltipItem.label]);
  const label = data.datasets[datasetIndex].label;
  const percent = Math.round(tooltipItem.value);

  return ` ${percent}% ${label} (${numerator} of ${denominator} patients)`;
}

function formatSumTooltipText(tooltipItem) {
  return ` ${formatNumberWithCommas(tooltipItem.value)} cumulative registrations`;
}

function formatValueAsPercent(value) {
  return `${value}%`;
}

function formatNumberWithCommas(value) {
  return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function formatTooltipLabelColor(tooltipItem, data) {
  const pointBackgroundColor = data.config.data.datasets[tooltipItem.datasetIndex].pointBackgroundColor;
  const borderColor = data.config.data.datasets[tooltipItem.datasetIndex].borderColor;
  const backgroundColor = data.config.data.datasets[tooltipItem.datasetIndex].backgroundColor;

  let styles = {};

  if (pointBackgroundColor === undefined) {
    styles.borderColor = backgroundColor;
    styles.backgroundColor = backgroundColor;
  } else {
    styles.borderColor = borderColor;
    styles.backgroundColor = borderColor;
  }

  return styles;
}
