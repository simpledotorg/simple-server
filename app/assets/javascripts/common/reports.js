const darkGreenColor = "rgba(0, 122, 49, 1)";
const mediumGreenColor = "rgba(0, 184, 73, 1)";
const lightGreenColor = "rgba(242, 248, 245, 0.9)";
const darkRedColor = "rgba(184, 22, 49, 1)"
const mediumRedColor = "rgba(255, 51, 85, 1)";
const lightRedColor = "rgba(255, 235, 238, 0.9)";
const darkPurpleColor = "rgba(83, 0, 224, 1)";
const lightPurpleColor = "rgba(238, 229, 252, 0.9)";
const darkBlueColor = "rgba(12, 57, 102, 1)";
const mediumBlueColor = "rgba(0, 117, 235, 1)";
const lightBlueColor = "rgba(233, 243, 255, 0.9)";
const darkGreyColor = "rgba(108, 115, 122, 1)";
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
  return document.getElementById("data-json");
}

function initializeCharts() {
  const data = getReportingData();

  const controlledGraphControlRate = window.withLtfu ? data.controlWithLtfuRate : data.controlRate;
  const controlledGraphAdjustedRegistrations = window.withLtfu ? data.adjustedRegistrationsWithLtfu : data.adjustedRegistrations;
  const controlledGraphControlledPatients = window.withLtfu ? data.controlledPatientsWithLtfu : data.controlledPatients;

  const controlledGraphConfig = createBaseGraphConfig();
  controlledGraphConfig.data = {
    labels: Object.keys(controlledGraphControlRate),
    datasets: [{
      label: "BP controlled",
      backgroundColor: lightGreenColor,
      borderColor: mediumGreenColor,
      borderWidth: 2,
      pointBackgroundColor: whiteColor,
      hoverBackgroundColor: whiteColor,
      hoverBorderWidth: 2,
      data: Object.values(controlledGraphControlRate),
      type: "line",
    }],
  };
  controlledGraphConfig.options.scales = {
    xAxes: [{
      stacked: true,
      display: true,
      gridLines: {
        display: false,
        drawBorder: true,
      },
      ticks: {
        autoSkip: false,
        fontColor: darkGreyColor,
        fontSize: 12,
        fontFamily: "Roboto Condensed",
        padding: 8,
        min: 0,
        beginAtZero: true,
      },
    }],
    yAxes: [{
      stacked: false,
      display: true,
      gridLines: {
        display: true,
        drawBorder: false,
      },
      ticks: {
        autoSkip: false,
        fontColor: darkGreyColor,
        fontSize: 12,
        fontFamily: "Roboto Condensed",
        padding: 8,
        min: 0,
        beginAtZero: true,
        stepSize: 25,
        max: 100,
      },
    }],
  };
  controlledGraphConfig.options.tooltips = {
    enabled: false,
    custom: function (tooltip) {
      const cardNode = document.getElementById("bp-controlled");
      const mostRecentPeriod = cardNode.getAttribute("data-period");
      const rateNode = cardNode.querySelector("[data-rate]");
      const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
      const periodStartNode = cardNode.querySelector("[data-period-start]");
      const periodEndNode = cardNode.querySelector("[data-period-end]");
      const registrationsNode = cardNode.querySelector("[data-registrations]");
      const registrationsPeriodEndNode = cardNode.querySelector("[data-registrations-period-end]")
      let label = null;
      let rate = null;
      if (tooltip.dataPoints) {
        rate = tooltip.dataPoints[0].value + "%";
        label = tooltip.dataPoints[0].label;
      }
      else {
        rate = rateNode.getAttribute("data-rate");
        label = mostRecentPeriod;
      }
      const period = data.periodInfo[label];
      const adjustedRegistrations = controlledGraphAdjustedRegistrations[label];
      const totalPatients = controlledGraphControlledPatients[label];

      rateNode.innerHTML = rate;
      totalPatientsNode.innerHTML = formatNumberWithCommas(totalPatients);
      periodStartNode.innerHTML = period.bp_control_start_date;
      periodEndNode.innerHTML = period.bp_control_end_date;
      registrationsNode.innerHTML = formatNumberWithCommas(adjustedRegistrations);
      registrationsPeriodEndNode.innerHTML = period.bp_control_start_date;
    }
  };

  const controlledGraphCanvas = document.getElementById("controlledPatientsTrend");
  if (controlledGraphCanvas) {
    new Chart(controlledGraphCanvas.getContext("2d"), controlledGraphConfig);
  }

  const missedVisitsConfig = createBaseGraphConfig();
  missedVisitsConfig.data = {
    labels: Object.keys(data.missedVisitsRate),
    datasets: [{
      label: "Missed visits",
      backgroundColor: lightBlueColor,
      borderColor: mediumBlueColor,
      borderWidth: 2,
      pointBackgroundColor: whiteColor,
      hoverBackgroundColor: whiteColor,
      hoverBorderWidth: 2,
      data: Object.values(data.missedVisitsRate),
      type: "line",
    }],
  };
  missedVisitsConfig.options.scales = {
    xAxes: [{
      stacked: false,
      display: true,
      gridLines: {
        display: false,
        drawBorder: true,
      },
      ticks: {
        autoSkip: false,
        fontColor: darkGreyColor,
        fontSize: 12,
        fontFamily: "Roboto Condensed",
        padding: 8,
        min: 0,
        beginAtZero: true,
      },
    }],
    yAxes: [{
      stacked: false,
      display: true,
      gridLines: {
        display: true,
        drawBorder: false,
      },
      ticks: {
        autoSkip: false,
        fontColor: darkGreyColor,
        fontSize: 12,
        fontFamily: "Roboto Condensed",
        padding: 8,
        min: 0,
        beginAtZero: true,
        stepSize: 25,
        max: 100,
      },
    }],
  }
  missedVisitsConfig.options.tooltips = {
    enabled: false,
    custom: function (tooltip) {
      const cardNode = document.getElementById("missed-visits");
      const mostRecentPeriod = cardNode.getAttribute("data-period");
      const rateNode = cardNode.querySelector("[data-rate]");
      const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
      const periodStartNode = cardNode.querySelector("[data-period-start]");
      const periodEndNode = cardNode.querySelector("[data-period-end]");
      const registrationsNode = cardNode.querySelector("[data-registrations]");
      const registrationsPeriodEndNode = cardNode.querySelector("[data-registrations-period-end]")
      let label = null;
      let rate = null;
      if (tooltip.dataPoints) {
        rate = tooltip.dataPoints[0].value + "%";
        label = tooltip.dataPoints[0].label;
      }
      else {
        rate = rateNode.getAttribute("data-rate");
        label = mostRecentPeriod;
      }
      const period = data.periodInfo[label];
      const adjustedRegistrations = data.adjustedRegistrations[label];
      const totalPatients = data.missedVisits[label];

      rateNode.innerHTML = rate;
      totalPatientsNode.innerHTML = formatNumberWithCommas(totalPatients);
      periodStartNode.innerHTML = period.bp_control_start_date;
      periodEndNode.innerHTML = period.bp_control_end_date;
      registrationsNode.innerHTML = formatNumberWithCommas(adjustedRegistrations);
      registrationsPeriodEndNode.innerHTML = period.bp_control_start_date;
    }
  };

  const missedVisitsGraphCanvas = document.getElementById("missedVisitsTrend");
  if (missedVisitsGraphCanvas) {
    new Chart(missedVisitsGraphCanvas.getContext("2d"), missedVisitsConfig);
  }

  const uncontrolledGraphConfig = createBaseGraphConfig();
  uncontrolledGraphConfig.data = {
    labels: Object.keys(data.uncontrolledRate),
    datasets: [{
      label: "BP uncontrolled",
      backgroundColor: lightRedColor,
      borderColor: mediumRedColor,
      borderWidth: 2,
      pointBackgroundColor: whiteColor,
      hoverBackgroundColor: whiteColor,
      hoverBorderWidth: 2,
      data: Object.values(data.uncontrolledRate),
      type: "line",
    }],
  };
  uncontrolledGraphConfig.options.scales = {
    xAxes: [{
      stacked: false,
      display: true,
      gridLines: {
        display: false,
        drawBorder: true,
      },
      ticks: {
        autoSkip: false,
        fontColor: darkGreyColor,
        fontSize: 12,
        fontFamily: "Roboto Condensed",
        padding: 8,
        min: 0,
        beginAtZero: true,
      },
    }],
    yAxes: [{
      stacked: false,
      display: true,
      gridLines: {
        display: true,
        drawBorder: false,
      },
      ticks: {
        autoSkip: false,
        fontColor: darkGreyColor,
        fontSize: 12,
        fontFamily: "Roboto Condensed",
        padding: 8,
        min: 0,
        beginAtZero: true,
        stepSize: 25,
        max: 100,
      },
    }],
  };
  uncontrolledGraphConfig.options.tooltips = {
    enabled: false,
    custom: function (tooltip) {
      const cardNode = document.getElementById("bp-uncontrolled");
      const mostRecentPeriod = cardNode.getAttribute("data-period");
      const rateNode = cardNode.querySelector("[data-rate]");
      const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
      const periodStartNode = cardNode.querySelector("[data-period-start]");
      const periodEndNode = cardNode.querySelector("[data-period-end]");
      const registrationsNode = cardNode.querySelector("[data-registrations]");
      const registrationsPeriodEndNode = cardNode.querySelector("[data-registrations-period-end]")
      let label = null;
      let rate = null;
      if (tooltip.dataPoints) {
        rate = tooltip.dataPoints[0].value + "%";
        label = tooltip.dataPoints[0].label;
      }
      else {
        rate = rateNode.getAttribute("data-rate");
        label = mostRecentPeriod;
      }
      const period = data.periodInfo[label];
      const adjustedRegistrations = data.adjustedRegistrations[label];
      const totalPatients = data.uncontrolledPatients[label];

      rateNode.innerHTML = rate;
      totalPatientsNode.innerHTML = formatNumberWithCommas(totalPatients);
      periodStartNode.innerHTML = period.bp_control_start_date;
      periodEndNode.innerHTML = period.bp_control_end_date;
      registrationsNode.innerHTML = formatNumberWithCommas(adjustedRegistrations);
      registrationsPeriodEndNode.innerHTML = period.bp_control_start_date;
    }
  };

  const uncontrolledGraphCanvas = document.getElementById("uncontrolledPatientsTrend");
  if (uncontrolledGraphCanvas) {
    new Chart(uncontrolledGraphCanvas.getContext("2d"), uncontrolledGraphConfig);
  }

  const cumulativeRegistrationsYAxis = createAxisMaxAndStepSize(data.cumulativeRegistrations);
  const monthlyRegistrationsYAxis = createAxisMaxAndStepSize(data.monthlyRegistrations);

  const cumulativeRegistrationsGraphConfig = createBaseGraphConfig();
  cumulativeRegistrationsGraphConfig.type = "bar";
  cumulativeRegistrationsGraphConfig.data = {
    labels: Object.keys(data.cumulativeRegistrations),
    datasets: [
      {
        yAxisID: "cumulativeRegistrations",
        label: "cumulative registrations",
        backgroundColor: transparent,
        borderColor: darkPurpleColor,
        borderWidth: 2,
        pointBackgroundColor: whiteColor,
        hoverBackgroundColor: whiteColor,
        hoverBorderWidth: 2,
        data: Object.values(data.cumulativeRegistrations),
        type: "line",
      },
      {
        yAxisID: "monthlyRegistrations",
        label: "monthly registrations",
        backgroundColor: lightPurpleColor,
        hoverBackgroundColor: darkPurpleColor,
        data: Object.values(data.monthlyRegistrations),
        type: "bar",
      },
    ],
  };
  cumulativeRegistrationsGraphConfig.options.scales = {
    xAxes: [{
      stacked: true,
      display: true,
      gridLines: {
        display: false,
        drawBorder: false,
      },
      ticks: {
        autoSkip: false,
        fontColor: darkGreyColor,
        fontSize: 12,
        fontFamily: "Roboto Condensed",
        padding: 8,
        min: 0,
        beginAtZero: true,
      },
    }],
    yAxes: [
      {
        id: "cumulativeRegistrations",
        position: "left",
        stacked: true,
        display: true,
        gridLines: {
          display: false,
          drawBorder: false,
        },
        ticks: {
          autoSkip: false,
          fontColor: darkGreyColor,
          fontSize: 12,
          fontFamily: "Roboto Condensed",
          padding: 8,
          min: 0,
          beginAtZero: true,
          stepSize: cumulativeRegistrationsYAxis.stepSize,
          max: cumulativeRegistrationsYAxis.max,
          callback: function(label) {
            return formatNumberWithCommas(label);
          },
        },
      },
      {
        id: "monthlyRegistrations",
        position: "right",
        stacked: true,
        display: true,
        gridLines: {
          display: true,
          drawBorder: false,
        },
        ticks: {
          autoSkip: false,
          fontColor: darkGreyColor,
          fontSize: 12,
          fontFamily: "Roboto Condensed",
          padding: 8,
          min: 0,
          beginAtZero: true,
          stepSize: monthlyRegistrationsYAxis.stepSize,
          max: monthlyRegistrationsYAxis.max,
          callback: function(label) {
            return formatNumberWithCommas(label);
          },
        },
      },
    ],
  };
  cumulativeRegistrationsGraphConfig.options.tooltips = {
    enabled: false,
    custom: function (tooltip) {
      const cardNode = document.getElementById("cumulative-registrations");
      const mostRecentPeriod = cardNode.getAttribute("data-period");
      const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
      const registrationsPeriodEndNode = cardNode.querySelector("[data-registrations-period-end]");
      const monthlyRegistrationsNode = cardNode.querySelector("[data-monthly-registrations]");
      const registrationsMonthEndNode = cardNode.querySelector("[data-registrations-month-end]");
      let label = null;
      if(tooltip.dataPoints) {
        label = tooltip.dataPoints[0].label;
      }
      else {
        label = mostRecentPeriod;
      }
      const period = data.periodInfo[label];
      const cumulativeRegistrations = data.cumulativeRegistrations[label];
      const monthlyRegistrations = data.monthlyRegistrations[label];

      monthlyRegistrationsNode.innerHTML = formatNumberWithCommas(monthlyRegistrations);
      totalPatientsNode.innerHTML = formatNumberWithCommas(cumulativeRegistrations);
      registrationsPeriodEndNode.innerHTML = period.bp_control_end_date;
      registrationsMonthEndNode.innerHTML = label;
    }
  };

  const cumulativeRegistrationsGraphCanvas = document.getElementById("cumulativeRegistrationsTrend");
  if (cumulativeRegistrationsGraphCanvas) {
    new Chart(cumulativeRegistrationsGraphCanvas.getContext("2d"), cumulativeRegistrationsGraphConfig);
  }

  const visitDetailsGraphConfig = createBaseGraphConfig();
  visitDetailsGraphConfig.type = "bar";
  visitDetailsGraphConfig.data = {
    labels: Object.keys(data.controlRate).slice(-6),
    datasets: [
      {
        label: "BP controlled",
        backgroundColor: mediumGreenColor,
        hoverBackgroundColor: darkGreenColor,
        data: Object.values(data.controlRate).slice(-6),
        type: "bar",
      },
      {
        label: "BP uncontrolled",
        backgroundColor: mediumRedColor,
        hoverBackgroundColor: darkRedColor,
        data: Object.values(data.uncontrolledRate).slice(-6),
        type: "bar",
      },
      {
        label: "Visit but no BP measure",
        backgroundColor: mediumGreyColor,
        hoverBackgroundColor: darkGreyColor,
        data: Object.values(data.visitButNoBPMeasureRate).slice(-6),
        type: "bar",
      },
      {
        label: "Missed visits",
        backgroundColor: mediumBlueColor,
        hoverBackgroundColor: darkBlueColor,
        data: Object.values(data.missedVisitsRate).slice(-6),
        type: "bar",
      },
    ],
  };
  visitDetailsGraphConfig.options.scales = {
    xAxes: [{
      stacked: true,
      display: true,
      gridLines: {
        display: false,
        drawBorder: false,
      },
      ticks: {
        autoSkip: false,
        fontColor: darkGreyColor,
        fontSize: 12,
        fontFamily: "Roboto Condensed",
        padding: 8,
        min: 0,
        beginAtZero: true,
      },
    }],
    yAxes: [{
      stacked: true,
      display: false,
      gridLines: {
        display: false,
        drawBorder: false,
      },
      ticks: {
        autoSkip: false,
        fontColor: darkGreyColor,
        fontSize: 12,
        fontFamily: "Roboto Condensed",
        padding: 8,
        min: 0,
        beginAtZero: true,
      },
    }],
  };
  visitDetailsGraphConfig.options.tooltips = {
    mode: "x",
    enabled: false,
    custom: function (tooltip) {
      const cardNode = document.getElementById("visit-details");
      const mostRecentPeriod = cardNode.getAttribute("data-period");
      const missedVisitsRateNode = cardNode.querySelector("[data-missed-visits-rate]");
      const visitButNoBPMeasureRateNode = cardNode.querySelector("[data-visit-but-no-bp-measure-rate]");
      const uncontrolledRateNode = cardNode.querySelector("[data-uncontrolled-rate]");
      const controlledRateNode = cardNode.querySelector("[data-controlled-rate]");
      const missedVisitsPatientsNode = cardNode.querySelector("[data-missed-visits-patients]");
      const visitButNoBPMeasurePatientsNode = cardNode.querySelector("[data-visit-but-no-bp-measure-patients]");
      const uncontrolledPatientsNode = cardNode.querySelector("[data-uncontrolled-patients]");
      const controlledPatientsNode = cardNode.querySelector("[data-controlled-patients]");
      const periodStartNodes = cardNode.querySelectorAll("[data-period-start]");
      const periodEndNodes = cardNode.querySelectorAll("[data-period-end]");
      const adjustedRegistrationsNodes = cardNode.querySelectorAll("[data-adjusted-registrations]");
      let label = null;
      let missedVisitsRate = null;
      let visitButNoBPMeasureRate = null;
      let uncontrolledRate = null;
      let controlledRate = null;
      if (tooltip.dataPoints) {
        missedVisitsRate = tooltip.dataPoints[3].value + "%";
        visitButNoBPMeasureRate = tooltip.dataPoints[2].value + "%";
        uncontrolledRate = tooltip.dataPoints[1].value + "%";
        controlledRate = tooltip.dataPoints[0].value + "%";
        label = tooltip.dataPoints[0].label;
      }
      else {
        missedVisitsRate = missedVisitsRateNode.getAttribute("data-missed-visits-rate");
        visitButNoBPMeasureRate = visitButNoBPMeasureRateNode.getAttribute("data-visit-but-no-bp-measure-rate");
        uncontrolledRate = uncontrolledRateNode.getAttribute("data-uncontrolled-rate");
        controlledRate = controlledRateNode.getAttribute("data-controlled-rate");
        label = mostRecentPeriod;
      }
      const period = data.periodInfo[label];
      const adjustedRegistrations = data.adjustedRegistrations[label];
      const totalMissedVisits = data.missedVisits[label];
      const totalVisitButNoBPMeasure = data.visitButNoBPMeasure[label];
      const totalUncontrolledPatients = data.uncontrolledPatients[label];
      const totalControlledPatients = data.controlledPatients[label];

      missedVisitsRateNode.innerHTML = missedVisitsRate;
      visitButNoBPMeasureRateNode.innerHTML = visitButNoBPMeasureRate;
      uncontrolledRateNode.innerHTML = uncontrolledRate;
      controlledRateNode.innerHTML = controlledRate;
      missedVisitsPatientsNode.innerHTML = formatNumberWithCommas(totalMissedVisits);
      visitButNoBPMeasurePatientsNode.innerHTML = formatNumberWithCommas(totalVisitButNoBPMeasure);
      uncontrolledPatientsNode.innerHTML = formatNumberWithCommas(totalUncontrolledPatients);
      controlledPatientsNode.innerHTML = formatNumberWithCommas(totalControlledPatients);
      periodStartNodes.forEach(node => node.innerHTML = period.bp_control_start_date);
      periodEndNodes.forEach(node => node.innerHTML = period.bp_control_end_date);
      adjustedRegistrationsNodes.forEach(node => node.innerHTML = adjustedRegistrations);
    },
  };

  const visitDetailsGraphCanvas = document.getElementById("missedVisitDetails");
  if (visitDetailsGraphCanvas) {
    new Chart(visitDetailsGraphCanvas.getContext("2d"), visitDetailsGraphConfig);
  }
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
    controlWithLtfuRate: jsonData.controlled_patients_with_ltfu_rate,
    controlledPatients: jsonData.controlled_patients,
    controlledPatientsWithLtfu: jsonData.controlled_patients_with_ltfu,
    missedVisits: jsonData.missed_visits,
    missedVisitsRate: jsonData.missed_visits_rate,
    monthlyRegistrations: jsonData.registrations,
    adjustedRegistrations: jsonData.adjusted_registrations,
    adjustedRegistrationsWithLtfu: jsonData.adjusted_registrations_with_ltfu,
    cumulativeRegistrations: jsonData.cumulative_registrations,
    uncontrolledRate: jsonData.uncontrolled_patients_rate,
    uncontrolledPatients: jsonData.uncontrolled_patients,
    visitButNoBPMeasure: jsonData.visited_without_bp_taken,
    visitButNoBPMeasureRate: jsonData.visited_without_bp_taken_rate,
    periodInfo: jsonData.period_info
  };
};

function createBaseGraphConfig() {
  return {
    type: "line",
    options: {
      animation: false,
      responsive: true,
      maintainAspectRatio: false,
      layout: {
        padding: {
          left: 0,
          right: 0,
          top: 20,
          bottom: 0,
        },
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
    },
  };
}

function createAxisMaxAndStepSize(data) {
  const maxDataValue = Math.max(...Object.values(data));
  const maxAxisValue = Math.round(maxDataValue * 1.15);
  const axisStepSize = Math.round(maxAxisValue / 2);

  return {
    max: maxAxisValue,
    stepSize: axisStepSize,
  };
};

function formatNumberWithCommas(value) {
  if (value == undefined) {
    return 0;
  }

  if (numeral(value) !== undefined) {
    return numeral(value).format('0,0');
  }

  return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}
