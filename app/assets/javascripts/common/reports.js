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
    visitButNoBPMeasureRate: jsonData.visited_without_bp_taken_rate,
    periodInfo: jsonData.period_info
  };
};

function initializeCharts() {
  const data = getReportingData();

  const controlledGraphConfig = createGraphConfig({
    datasets: [{
      data: data.controlRate,
      borderWidth: 2,
      rgbaLineColor: mediumGreenColor,
      rgbaPointColor: lightGreenColor,
      rgbaBackgroundColor: lightGreenColor,
      label: "HTN controlled",
    }],
    graphType: "line",
  });
  controlledGraphConfig.options = createGraphOptions(
    [createAxisConfig({
      stacked: false,
      display: false,
      drawBorder: true,
    })],
    [createAxisConfig({
      stacked: false,
      display: true,
      drawBorder: false,
      stepSize: 25,
      max: 100,
    })],
    formatRateTooltipText,
    [data.controlledPatients],
    data.cumulativeRegistrations,
  );
  controlledGraphConfig.options.tooltips = {
    enabled: false,
    custom: function (tooltipModel) {
      return onePlotTooltip({
        tooltipModel,
        elementId: "bp-controlled",
        totalPatients: data.controlledPatients,
        cumulativeRegistrations: data.cumulativeRegistrations,
        periodInfo: data.periodInfo,
      });
    }
  };

  const controlledGraphCanvas = document.getElementById("controlledPatientsTrend");
  if (controlledGraphCanvas) {
    new Chart(controlledGraphCanvas.getContext("2d"), controlledGraphConfig);
  }

  const missedVisitsConfig = createGraphConfig({
    datasets: [{
      data: data.missedVisitsRate,
      borderWidth: 2,
      rgbaLineColor: mediumBlueColor,
      rgbaPointColor: whiteColor,
      rgbaBackgroundColor: lightBlueColor,
      label: "Missed visits",
    }],
    graphType: "line",
  });
  missedVisitsConfig.options = createGraphOptions(
    [createAxisConfig({
      stacked: false,
      display: false,
      drawBorder: true,
    })],
    [createAxisConfig({
      stacked: false,
      display: true,
      drawBorder: false,
      stepSize: 25,
      max: 100,
    })],
    formatRateTooltipText,
    [data.missedVisits],
    data.cumulativeRegistrations,
  );
  missedVisitsConfig.options.tooltips = {
    enabled: false,
    custom: function (tooltipModel) {
      return onePlotTooltip({
        tooltipModel,
        elementId: "missed-visits",
        totalPatients: data.missedVisits,
        cumulativeRegistrations: data.cumulativeRegistrations,
        periodInfo: data.periodInfo,
      });
    }
  };

  const missedVisitsGraphCanvas = document.getElementById("missedVisitsTrend");
  if (missedVisitsGraphCanvas) {
    new Chart(missedVisitsGraphCanvas.getContext("2d"), missedVisitsConfig);
  }

  const uncontrolledGraphConfig = createGraphConfig({
    datasets: [{
      data: data.uncontrolledRate,
      borderWidth: 2,
      rgbaLineColor: darkRedColor,
      rgbaPointColor: whiteColor,
      rgbaBackgroundColor: lightRedColor,
      label: "HTN not under control",
    }],
    graphType: "line",
  });
  uncontrolledGraphConfig.options = createGraphOptions(
    [createAxisConfig({
      stacked: false,
      display: false,
      drawBorder: true,
    })],
    [createAxisConfig({
      stacked: false,
      display: true,
      drawBorder: false,
      stepSize: 25,
      max: 100,
    })],
    formatRateTooltipText,
    [data.uncontrolledPatients],
    data.cumulativeRegistrations,
  );
  uncontrolledGraphConfig.options.tooltips = {
    enabled: false,
    custom: function (tooltipModel) {
      return onePlotTooltip({
        tooltipModel,
        elementId: "bp-uncontrolled",
        totalPatients: data.uncontrolledPatients,
        cumulativeRegistrations: data.cumulativeRegistrations,
        periodInfo: data.periodInfo,
      });
    }
  };

  const uncontrolledGraphCanvas = document.getElementById("uncontrolledPatientsTrend");
  if (uncontrolledGraphCanvas) {
    new Chart(uncontrolledGraphCanvas.getContext("2d"), uncontrolledGraphConfig);
  }

  const cumulativeRegistrationsYAxis = createAxisMaxAndStepSize(data.cumulativeRegistrations);
  const monthlyRegistrationsYAxis = createAxisMaxAndStepSize(data.monthlyRegistrations);

  const cumulativeRegistrationsGraphConfig = createGraphConfig({
    datasets: [
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
    ],
    graphType: "bar",
  });
  cumulativeRegistrationsGraphConfig.options = createGraphOptions(
    [createAxisConfig({
      stacked: true,
      display: false,
      drawBorder: false,
    })],
    [
      createAxisConfig({
        stacked: true,
        display: false,
        drawBorder: false,
        stepSize: cumulativeRegistrationsYAxis.stepSize,
        max: cumulativeRegistrationsYAxis.max,
        id: "cumulativeRegistrations",
        position: "left",
      }),
      createAxisConfig({
        stacked: true,
        display: true,
        drawBorder: false,
        stepSize: monthlyRegistrationsYAxis.stepSize,
        max: monthlyRegistrationsYAxis.max,
        id: "monthlyRegistrations",
        position: "right",
      }),
    ],
    formatSumTooltipText,
  );
  cumulativeRegistrationsGraphConfig.options.tooltips = {
    enabled: false,
    custom: function (tooltipModel) {
      return twoPlotsTooltip({
        tooltipModel,
        elementId: "cumulative-registrations",
        cumulativeRegistrations: data.cumulativeRegistrations,
        monthlyRegistrations: data.monthlyRegistrations,
        periodInfo: data.periodInfo,
      });
    }
  };

  const cumulativeRegistrationsGraphCanvas = document.getElementById("cumulativeRegistrationsTrend");
  if (cumulativeRegistrationsGraphCanvas) {
    new Chart(cumulativeRegistrationsGraphCanvas.getContext("2d"), cumulativeRegistrationsGraphConfig);
  }

  const visitDetailsGraphConfig = createGraphConfig({
    datasets: [
      {
        data: data.controlRate,
        rgbaBackgroundColor: mediumGreenColor,
        hoverBackgroundColor: mediumGreenColor,
        label: "HTN controlled",
        graphType: "bar",
      },
      {
        data: data.uncontrolledRate,
        rgbaBackgroundColor: darkRedColor,
        hoverBackgroundColor: darkRedColor,
        label: "HTN not under control",
        graphType: "bar",
      },
      {
        data: data.visitButNoBPMeasureRate,
        rgbaBackgroundColor: darkGreyColor,
        hoverBackgroundColor: darkGreyColor,
        label: "Visited in the last 3 months",
        graphType: "bar",
      },
      {
        data: data.missedVisitsRate,
        rgbaBackgroundColor: mediumBlueColor,
        hoverBackgroundColor: mediumBlueColor,
        label: "No visit >3 months",
        graphType: "bar",
      }
    ],
    graphType: "bar",
    numberOfMonths: 6,
  });
  visitDetailsGraphConfig.options = createGraphOptions(
    [createAxisConfig({
      stacked: true,
      display: false,
      drawBorder: false,
    })],
    [createAxisConfig({
      stacked: true,
      display: false,
      drawBorder: false,
      stepSize: 25,
      max: 100,
    })],
    formatRateTooltipText,
    [data.controlledPatients, data.uncontrolledPatients, data.visitButNoBPMeasure, data.missedVisits],
    data.cumulativeRegistrations,
  );
  visitDetailsGraphConfig.options.tooltips = {
    mode: "x",
    enabled: false,
    custom: function (tooltipModel) {
      return stackedBarChartTooltip({
        tooltipModel,
        elementId: "visit-details",
        missedVisitsPatients: Object.values(data.missedVisits).slice(18, 24),
        visitButNoBPMeasurePatients: Object.values(data.visitButNoBPMeasure).slice(18, 24),
        uncontrolledPatients: Object.values(data.uncontrolledPatients).slice(18, 24),
        controlledPatients: Object.values(data.controlledPatients).slice(18, 24),
        cumulativeRegistrations: Object.values(data.cumulativeRegistrations).slice(18, 24),
        periodInfo: Object.values(data.periodInfo).slice(18, 24),
      });
    }
  };

  const visitDetailsGraphCanvas = document.getElementById("missedVisitDetails");
  if (visitDetailsGraphCanvas) {
    new Chart(visitDetailsGraphCanvas.getContext("2d"), visitDetailsGraphConfig);
  }
}

function createGraphConfig(config) {
  let { datasets, graphType, numberOfMonths } = config;

  const totalMonths = Object.keys(datasets[0].data).length;

  if (numberOfMonths == undefined) {
    numberOfMonths = 24;
  }

  return {
    type: graphType,
    data: {
      labels: Object.keys(datasets[0].data).slice(totalMonths - numberOfMonths, totalMonths),
      datasets: datasets.map(dataset => {
        return {
          yAxisID: dataset.id,
          label: dataset.label,
          backgroundColor: dataset.rgbaBackgroundColor,
          borderColor: dataset.rgbaLineColor ? dataset.rgbaLineColor : undefined,
          borderWidth: dataset.borderWidth ? dataset.borderWidth : undefined,
          pointBackgroundColor: dataset.rgbaPointColor,
          hoverBackgroundColor: dataset.hoverBackgroundColor,
          data: Object.values(dataset.data).slice(totalMonths - numberOfMonths, totalMonths),
          type: dataset.graphType ? dataset.graphType : "line",
        };
      }),
    },
  }
}

function createGraphOptions(xAxes, yAxes, tooltipCallbackFunction, numerator, denominator, periodInfo) {
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
      xAxes,
      yAxes,
    },
    // TODO Please delete
    tooltips: { enabled: false },
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

function createAxisConfig(config) {
  const { stacked, display, drawBorder, stepSize, max, id, position } = config;
  let axisConfig = {
    id,
    position: position ? position : "left",
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
      beginAtZero: true,
      stepSize,
      max,
    },
  };

  return axisConfig;
};

function createAxisMaxAndStepSize(data) {
  const maxDataValue = Math.max(...Object.values(data));
  const maxAxisValue = Math.round(maxDataValue * 1.15);
  const axisStepSize = Math.round(maxAxisValue / 2);

  return {
    max: maxAxisValue,
    stepSize: axisStepSize,
  };
};

function customTooltip(tooltipModel, numerator, denominator, periodInfo) {
  const { dataPoints } = tooltipModel;
  const valueElement = document.getElementById("bp-controlled-value");
  const defaultValue = valueElement.textContent;
  const endDateElement = document.getElementById("bp-controlled-end-date");
  const defaultEndDate = endDateElement.textContent;

  if (dataPoints == undefined) {
    valueElement.innerHTML = defaultValue;
    endDateElement.innerHTML = defaultEndDate;
  } else {
    valueElement.innerHTML = dataPoints[0].value;
    endDateElement.innerHTML = dataPoints[0].label;
  }
};

function onePlotTooltip(config) {
  const { tooltipModel, elementId, totalPatients, cumulativeRegistrations, periodInfo } = config;
  const { dataPoints } = tooltipModel;

  const cardNode = document.getElementById(elementId);
  const rateNode = cardNode.querySelector("[data-rate]");
  const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
  const periodStartNode = cardNode.querySelector("[data-period-start]");
  const periodEndNode = cardNode.querySelector("[data-period-end]");
  const registrationsNode = cardNode.querySelector("[data-registrations]");
  const registrationsPeriodEndNode = cardNode.querySelector("[data-registrations-period-end]") 

  if (dataPoints == undefined) {
    rateNode.innerHTML = rateNode.getAttribute("data-rate");
    totalPatientsNode.innerHTML = totalPatientsNode.getAttribute("data-total-patients");
    periodStartNode.innerHTML = periodStartNode.getAttribute("data-period-start");
    periodEndNode.innerHTML = periodEndNode.getAttribute("data-period-end");
    registrationsNode.innerHTML = registrationsNode.getAttribute("data-registrations");
    registrationsPeriodEndNode.innerHTML = periodStartNode.getAttribute("data-period-start");
  } else {
    rateNode.innerHTML = dataPoints[0].value + "%";
    totalPatientsNode.innerHTML = Object.values(totalPatients)[dataPoints[0].index];
    periodStartNode.innerHTML = Object.values(periodInfo)[dataPoints[0].index].bp_control_start_date;
    periodEndNode.innerHTML = Object.values(periodInfo)[dataPoints[0].index].bp_control_end_date;
    registrationsNode.innerHTML = Object.values(cumulativeRegistrations)[dataPoints[0].index];
    registrationsPeriodEndNode.innerHTML = Object.values(periodInfo)[dataPoints[0].index].bp_control_start_date;
  }
}

function twoPlotsTooltip(config) {
  const { tooltipModel, elementId, cumulativeRegistrations, monthlyRegistrations, periodInfo } = config;
  const { dataPoints } = tooltipModel;

  const cardNode = document.getElementById(elementId);
  const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
  const registrationsPeriodEndNode = cardNode.querySelector("[data-registrations-period-end]");
  const monthlyRegistrationsNode = cardNode.querySelector("[data-monthly-registrations]");
  const registrationsMonthEndNode = cardNode.querySelector("[data-registrations-month-end]");

  if (dataPoints == undefined) {
    totalPatientsNode.innerHTML = totalPatientsNode.getAttribute("data-total-patients");
    registrationsPeriodEndNode.innerHTML = registrationsPeriodEndNode.getAttribute("data-registrations-period-end");
    monthlyRegistrationsNode.innerHTML = monthlyRegistrationsNode.getAttribute("data-monthly-registrations");
    registrationsMonthEndNode.innerHTML = registrationsMonthEndNode.getAttribute("data-registrations-month-end");
  } else {
    totalPatientsNode.innerHTML = Object.values(cumulativeRegistrations)[dataPoints[0].index];
    registrationsPeriodEndNode.innerHTML = Object.values(periodInfo)[dataPoints[0].index].bp_control_end_date;
    monthlyRegistrationsNode.innerHTML = Object.values(monthlyRegistrations)[dataPoints[0].index];
    registrationsMonthEndNode.innerHTML = Object.keys(monthlyRegistrations)[dataPoints[0].index];
  }
}

function stackedBarChartTooltip(config) {
  const {
    tooltipModel,
    elementId,
    missedVisitsPatients,
    visitButNoBPMeasurePatients,
    uncontrolledPatients,
    controlledPatients,
    cumulativeRegistrations,
    periodInfo,
  } = config;
  const { dataPoints } = tooltipModel;

  const cardNode = document.getElementById(elementId);
  let missedVisitsRateNode = cardNode.querySelector("[data-missed-visits-rate]");
  let visitButNoBPMeasureRateNode = cardNode.querySelector("[data-visit-but-no-bp-measure-rate]");
  let uncontrolledRateNode = cardNode.querySelector("[data-uncontrolled-rate]");
  let controlledRateNode = cardNode.querySelector("[data-controlled-rate]");
  let missedVisitsPatientsNode = cardNode.querySelector("[data-missed-visits-patients]");
  let visitButNoBPMeasurePatientsNode = cardNode.querySelector("[data-visited-but-no-bp-measure-patients]");
  let uncontrolledPatientsNode = cardNode.querySelector("[data-uncontrolled-patients]");
  let controlledPatientsNode = cardNode.querySelector("[data-controlled-patients]");
  const periodStartNodes = cardNode.querySelectorAll("[data-period-start]");
  const periodEndNodes = cardNode.querySelectorAll("[data-period-end]");
  const cumulativeRegistrationsNodes = cardNode.querySelectorAll("[data-cumulative-registrations]");

  if (dataPoints == undefined) {
    missedVisitsRateNode.innerHTML = missedVisitsRateNode.getAttribute("data-missed-visits-rate");
    visitButNoBPMeasureRateNode.innerHTML = visitButNoBPMeasureRateNode.getAttribute("data-visit-but-no-bp-measure-rate");
    uncontrolledRateNode.innerHTML = uncontrolledRateNode.getAttribute("data-uncontrolled-rate");
    controlledRateNode.innerHTML = controlledRateNode.getAttribute("data-controlled-rate");
    missedVisitsPatientsNode.innerHTML = missedVisitsPatientsNode.getAttribute("data-missed-visits-patients");
    visitButNoBPMeasurePatientsNode = visitButNoBPMeasurePatientsNode.getAttribute("data-visited-but-no-bp-measure-patients");
    uncontrolledPatientsNode = cardNode.getAttribute("data-uncontrolled-patients");
    controlledPatientsNode = cardNode.getAttribute("data-controlled-patients");
    periodStartNodes.forEach(node => node.innerHTML = periodStartNodes[0].getAttribute("data-period-start"));
    periodEndNodes.forEach(node => node.innerHTML = periodEndNodes[0].getAttribute("data-period-end"));
    cumulativeRegistrationsNodes.forEach(node => node.innerHTML = cumulativeRegistrationsNodes[0].getAttribute("data-cumulative-registrations"));
  } else {
    missedVisitsRateNode.innerHTML = dataPoints[3].value + "%";
    visitButNoBPMeasureRateNode.innerHTML = dataPoints[2].value + "%";
    uncontrolledRateNode.innerHTML = dataPoints[1].value + "%";
    controlledRateNode.innerHTML = dataPoints[0].value + "%";
    missedVisitsPatientsNode.innerHTML = missedVisitsPatients[dataPoints[3].index];
    visitButNoBPMeasurePatientsNode.innerHTML = visitButNoBPMeasurePatients[dataPoints[2].index];
    uncontrolledPatientsNode.innerHTML = uncontrolledPatients[dataPoints[1].index];
    controlledPatientsNode.innerHTML = controlledPatients[dataPoints[0].index];
    periodStartNodes.forEach(node => node.innerHTML = periodInfo[dataPoints[0].index].bp_control_start_date);
    periodEndNodes.forEach(node => node.innerHTML = periodInfo[dataPoints[0].index].bp_control_end_date);
    cumulativeRegistrationsNodes.forEach(node => node.innerHTML = cumulativeRegistrations[dataPoints[0].index]);
  }
}