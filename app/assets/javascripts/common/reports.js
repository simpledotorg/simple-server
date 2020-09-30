const lightGreenColor = "rgba(242, 248, 245, 0.9)";
const darkGreenColor = "rgba(0, 122, 49, 1)";
const mediumGreenColor = "rgba(0, 184, 73, 1)";
const lightRedColor = "rgba(255, 235, 238, 0.9)";
const darkRedColor = "rgba(255, 51, 85, 1)";
const lightPurpleColor = "rgba(238, 229, 252, 0.9)";
const darkPurpleColor = "rgba(83, 0, 224, 1)";
const darkGreyColor = "rgba(108, 115, 122, 1)";
const lightBlueColor = "rgba(233, 243, 255, 0.9)";
const mediumBlueColor = "rgba(0, 117, 235, 1)";
const mediumGreyColor = "rgba(173, 178, 184, 1)";
const lightGreyColor = "rgba(240, 242, 245, 0.9)";
const whiteColor = "rgba(255, 255, 255, 1)";
const transparent = "rgba(0, 0, 0, 0)";

window.addEventListener("DOMContentLoaded", function() {
  if(getChartDataNode()) {
    initializeCharts();
    initializeTables();
  }
});

function getChartDataNode() {
  return document.getElementById("data-json")
}

function initializeTables() {
  const tableSortAscending = { descending: false };
  const tableSortDescending = { descending: true };

  const cumulativeRegistrationsTable = document.getElementById("cumulative-registrations-table");
  const htnNotUnderControlTable = document.getElementById("htn-not-under-control-table");
  const noBPMeasureTable = document.getElementById("no-bp-measure-table");
  const htnControlledTable = document.getElementById("htn-controlled-table");

  if (htnControlledTable) {
    new Tablesort(htnControlledTable, tableSortAscending);
  }

  if (noBPMeasureTable) {
    new Tablesort(noBPMeasureTable, tableSortDescending);
  }

  if (htnNotUnderControlTable) {
    new Tablesort(htnNotUnderControlTable, tableSortDescending);
  }

  if (cumulativeRegistrationsTable) {
    new Tablesort(cumulativeRegistrationsTable, tableSortAscending);
  }
};

function getReportingData() {
  const jsonData = JSON.parse(getChartDataNode().textContent);

  return {
    controlRate: jsonData.controlled_patients_rate,
    controlledPatients: jsonData.controlled_patients,
    missedVisits: jsonData.missed_visits,
    missedVisitsRate: jsonData.missed_visits_rate,
    monthlyRegistrations: jsonData.registrations,
    cumulativeRegistrations: jsonData.adjusted_registrations,
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
    rgbaPointColor: whiteColor,
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
    data.cumulativeRegistrations,
  );

  const controlledGraphCanvas = document.getElementById("controlledPatientsTrend");
  if (controlledGraphCanvas) {
    new Chart(controlledGraphCanvas.getContext("2d"), controlledGraphConfig);
  }

  const missedVisitsConfig = createGraphConfig([
    {
      data: data.missedVisitsRate,
      borderWidth: 2,
      rgbaLineColor: mediumBlueColor,
      rgbaPointColor: whiteColor,
      rgbaBackgroundColor: lightBlueColor,
      label: "Missed visits",
    },
  ], "line");
  missedVisitsConfig.options = createGraphOptions(
    false,
    25,
    100,
    formatValueAsPercent,
    formatRateTooltipText,
    [data.missedVisits],
    data.cumulativeRegistrations,
  );

  const missedVisitsGraphCanvas = document.getElementById("missedVisitsTrend");
  if (missedVisitsGraphCanvas) {
    new Chart(missedVisitsGraphCanvas.getContext("2d"), missedVisitsConfig);
  }

  const uncontrolledGraphConfig = createGraphConfig([
    {
      data: data.uncontrolledRate,
      borderWidth: 2,
      rgbaLineColor: darkRedColor,
      rgbaPointColor: whiteColor,
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
    data.cumulativeRegistrations,
  );

  const uncontrolledGraphCanvas = document.getElementById("uncontrolledPatientsTrend");
  if (uncontrolledGraphCanvas) {
    new Chart(uncontrolledGraphCanvas.getContext("2d"), uncontrolledGraphConfig);
  }

  const maxCumulativeRegistrations = Math.max(...Object.values(data.cumulativeRegistrations));
  const cumulativeRegistrationsMax = Math.round(maxCumulativeRegistrations * 1.15);
  const cumulativeRegistrationsStepSize = Math.round(cumulativeRegistrationsMax / 2);

  const maxMonthlyRegistrations = Math.max(...Object.values(data.monthlyRegistrations));
  const monthlyRegistrationsMax = Math.round(maxMonthlyRegistrations * 1.15);
  const monthlyRegistrationsStepSize = Math.round(monthlyRegistrationsMax / 2);

  const cumulativeRegistrationsGraphConfig = createGraphConfig([
    {
      id: "cumulativeRegistrations",
      data: data.cumulativeRegistrations,
      borderWidth: 2,
      rgbaLineColor: darkPurpleColor,
      rgbaPointColor: whiteColor,
      rgbaBackgroundColor: transparent,
      label: "cumulative registrations",
      graphType: "line",
    },
    {
      id: "monthlyRegistrations",
      data: data.monthlyRegistrations,
      rgbaBackgroundColor: lightPurpleColor,
      hoverBackgroundColor: lightPurpleColor,
      label: "monthly registrations",
      graphType: "bar",
    },
  ], "bar");

  const configTest = {
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
    hoverMode: 'index',
    stacked: false,
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
        stacked: true,
        display: true,
        gridLines: {
          display: false,
          drawBorder: true,
        },
        ticks: {
          fontColor: darkGreyColor,
          fontSize: 12,
          fontFamily: "Roboto Condensed",
          padding: 8,
        },
      }],
      yAxes: [
        {
          id: "cumulativeRegistrations",
          type: "linear",
          display: true,
          position: "left",
          ticks: {
            fontColor: darkGreyColor,
            fontSize: 12,
            fontFamily: "Roboto Condensed",
            padding: 8,
            max: cumulativeRegistrationsMax,
            stepSize: cumulativeRegistrationsStepSize,
          },
          gridLines: {
            display: true,
            drawBorder: false,
          },
        },
        {
          id: "monthlyRegistrations",
          type: "linear",
          display: true,
          position: "right",
          ticks: {
            fontColor: darkGreyColor,
            fontSize: 12,
            fontFamily: "Roboto Condensed",
            padding: 8,
            max: monthlyRegistrationsMax,
            stepSize: monthlyRegistrationsStepSize,
          },
          gridLines: {
            display: true,
            drawBorder: false,
          },
        },
      ],
    },
  };

  cumulativeRegistrationsGraphConfig.options = configTest;

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
    data.cumulativeRegistrations,
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
          yAxisID: dataset.id,
          label: dataset.label,
          backgroundColor: dataset.rgbaBackgroundColor,
          borderColor: dataset.rgbaLineColor ? dataset.rgbaLineColor : undefined,
          borderWidth: dataset.borderWidth ? dataset.borderWidth : undefined,
          pointBackgroundColor: dataset.rgbaPointColor,
          hoverBackgroundColor: dataset.hoverBackgroundColor,
          data: Object.values(dataset.data),
          type: dataset.graphType ? dataset.graphType : "line",
        };
      }),
    },
  }
}

function createGraphOptions(stacked, stepSize, suggestedMax, tickCallbackFunction, tooltipCallbackFunction, numerators, denominators) {
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
      xAxes: [createAxisConfig(stacked, false, true)],
      yAxes: [{
        stacked,
        display: true,
        gridLines: {
          display: true,
          drawBorder: false,
        },
        ticks: {
          fontColor: darkGreyColor,
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

function formatSumTooltipText(tooltipItem, data) {
  return ` ${formatNumberWithCommas(tooltipItem.value)} ${data.datasets[tooltipItem.datasetIndex].label}`;
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

function createAxisConfig(stacked, display, drawBorder) {
  return {
    stacked,
    display: true,
    gridLines: {
      display,
      drawBorder,
    },
    ticks: {
      fontColor: darkGreyColor,
      fontSize: 12,
      fontFamily: "Roboto Condensed",
      padding: 8,
    },
  };
};