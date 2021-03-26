Reports = function () {
  this.darkGreenColor = "rgba(0, 122, 49, 1)";
  this.mediumGreenColor = "rgba(0, 184, 73, 1)";
  this.lightGreenColor = "rgba(242, 248, 245, 0.9)";
  this.darkRedColor = "rgba(184, 22, 49, 1)"
  this.mediumRedColor = "rgba(255, 51, 85, 1)";
  this.lightRedColor = "rgba(255, 235, 238, 0.9)";
  this.darkPurpleColor = "rgba(83, 0, 224, 1)";
  this.lightPurpleColor = "rgba(169, 128, 239, 1)";
  this.darkBlueColor = "rgba(12, 57, 102, 1)";
  this.mediumBlueColor = "rgba(0, 117, 235, 1)";
  this.lightBlueColor = "rgba(233, 243, 255, 0.9)";
  this.darkGreyColor = "rgba(108, 115, 122, 1)";
  this.mediumGreyColor = "rgba(173, 178, 184, 1)";
  this.lightGreyColor = "rgba(240, 242, 245, 0.9)";
  this.whiteColor = "rgba(255, 255, 255, 1)";
  this.transparent = "rgba(0, 0, 0, 0)";

  this.listen = () => {
    this.initializeCharts();
    this.initializeTables();
  }

  this.getChartDataNode = () => {
    return document.getElementById("data-json");
  }

  this.initializeCharts = () => {
    const data = this.getReportingData();

    const controlGraphDenominator = window.withLtfu ? data.adjustedPatientCountsWithLtfu : data.adjustedPatientCounts;
    const missedVisitsGraphNumerator = data.missedVisits;
    const missedVisitsGraphRate = window.withLtfu ? data.controlWithLtfuRate : data.controlRate;

    this.setupControlledGraph(data);
    this.setupUncontrolledGraph(data);
    // this.setupMissedVisitsGraph();
    // this.setupCumulativeRegistrationsGraph();
    // this.setupVisitDetailsGraph();

    const missedVisitsConfig = this.createBaseGraphConfig();
    missedVisitsConfig.data = {
      labels: Object.keys(missedVisitsGraphRate),
      datasets: [{
        label: "Missed visits",
        backgroundColor: this.lightBlueColor,
        borderColor: this.mediumBlueColor,
        borderWidth: 2,
        pointBackgroundColor: this.whiteColor,
        hoverBackgroundColor: this.whiteColor,
        hoverBorderWidth: 2,
        data: Object.values(missedVisitsGraphRate),
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
          fontColor: this.darkGreyColor,
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
          fontColor: this.darkGreyColor,
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
      custom: (tooltip) => {
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
        } else {
          rate = rateNode.getAttribute("data-rate");
          label = mostRecentPeriod;
        }
        const period = data.periodInfo[label];
        const adjustedPatientCounts = controlGraphDenominator[label];
        const totalPatients = missedVisitsGraphNumerator[label];

        rateNode.innerHTML = rate;
        totalPatientsNode.innerHTML = this.formatNumberWithCommas(totalPatients);
        periodStartNode.innerHTML = period.bp_control_start_date;
        periodEndNode.innerHTML = period.bp_control_end_date;
        registrationsNode.innerHTML = this.formatNumberWithCommas(adjustedPatientCounts);
        registrationsPeriodEndNode.innerHTML = period.bp_control_registration_date;
      }
    };

    const missedVisitsGraphCanvas = document.getElementById("missedVisitsTrend");
    if (missedVisitsGraphCanvas) {
      new Chart(missedVisitsGraphCanvas.getContext("2d"), missedVisitsConfig);
    }

    const cumulativeRegistrationsYAxis = this.createAxisMaxAndStepSize(data.cumulativeRegistrations);
    const monthlyRegistrationsYAxis = this.createAxisMaxAndStepSize(data.monthlyRegistrations);

    const cumulativeRegistrationsGraphConfig = this.createBaseGraphConfig();
    cumulativeRegistrationsGraphConfig.type = "bar";
    cumulativeRegistrationsGraphConfig.data = {
      labels: Object.keys(data.cumulativeRegistrations),
      datasets: [
        {
          yAxisID: "cumulativeRegistrations",
          label: "cumulative registrations",
          backgroundColor: this.transparent,
          borderColor: this.darkPurpleColor,
          borderWidth: 2,
          pointBackgroundColor: this.whiteColor,
          hoverBackgroundColor: this.whiteColor,
          hoverBorderWidth: 2,
          data: Object.values(data.cumulativeRegistrations),
          type: "line",
        },
        {
          yAxisID: "monthlyRegistrations",
          label: "monthly registrations",
          backgroundColor: this.lightPurpleColor,
          hoverBackgroundColor: this.darkPurpleColor,
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
          fontColor: this.darkGreyColor,
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
            fontColor: this.darkGreyColor,
            fontSize: 12,
            fontFamily: "Roboto Condensed",
            padding: 8,
            min: 0,
            beginAtZero: true,
            stepSize: cumulativeRegistrationsYAxis.stepSize,
            max: cumulativeRegistrationsYAxis.max,
            callback: (label) => {
              return this.formatNumberWithCommas(label);
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
            fontColor: this.darkGreyColor,
            fontSize: 12,
            fontFamily: "Roboto Condensed",
            padding: 8,
            min: 0,
            beginAtZero: true,
            stepSize: monthlyRegistrationsYAxis.stepSize,
            max: monthlyRegistrationsYAxis.max,
            callback: (label) => {
              return this.formatNumberWithCommas(label);
            },
          },
        },
      ],
    };
    cumulativeRegistrationsGraphConfig.options.tooltips = {
      enabled: false,
      custom: (tooltip) => {
        const cardNode = document.getElementById("cumulative-registrations");
        const mostRecentPeriod = cardNode.getAttribute("data-period");
        const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
        const registrationsPeriodEndNode = cardNode.querySelector("[data-registrations-period-end]");
        const monthlyRegistrationsNode = cardNode.querySelector("[data-monthly-registrations]");
        const registrationsMonthEndNode = cardNode.querySelector("[data-registrations-month-end]");
        let label = null;
        if (tooltip.dataPoints) {
          label = tooltip.dataPoints[0].label;
        } else {
          label = mostRecentPeriod;
        }
        const period = data.periodInfo[label];
        const cumulativeRegistrations = data.cumulativeRegistrations[label];
        const monthlyRegistrations = data.monthlyRegistrations[label];

        monthlyRegistrationsNode.innerHTML = this.formatNumberWithCommas(monthlyRegistrations);
        totalPatientsNode.innerHTML = this.formatNumberWithCommas(cumulativeRegistrations);
        registrationsPeriodEndNode.innerHTML = period.bp_control_end_date;
        registrationsMonthEndNode.innerHTML = label;
      }
    };

    const cumulativeRegistrationsGraphCanvas = document.getElementById("cumulativeRegistrationsTrend");
    if (cumulativeRegistrationsGraphCanvas) {
      new Chart(cumulativeRegistrationsGraphCanvas.getContext("2d"), cumulativeRegistrationsGraphConfig);
    }

    const visitDetailsGraphConfig = this.createBaseGraphConfig();
    visitDetailsGraphConfig.type = "bar";

    const maxBarsToDisplay = 6;
    const barsToDisplay = Math.min(Object.keys(data.controlRate).length, maxBarsToDisplay);

    visitDetailsGraphConfig.data = {
      labels: Object.keys(data.controlRate).slice(-barsToDisplay),
      datasets: [
        {
          label: "BP controlled",
          backgroundColor: this.mediumGreenColor,
          hoverBackgroundColor: this.darkGreenColor,
          data: Object.values(data.controlRate).slice(-barsToDisplay),
          type: "bar",
        },
        {
          label: "BP uncontrolled",
          backgroundColor: this.mediumRedColor,
          hoverBackgroundColor: this.darkRedColor,
          data: Object.values(data.uncontrolledRate).slice(-barsToDisplay),
          type: "bar",
        },
        {
          label: "Visit but no BP measure",
          backgroundColor: this.mediumGreyColor,
          hoverBackgroundColor: this.darkGreyColor,
          data: Object.values(data.visitButNoBPMeasureRate).slice(-barsToDisplay),
          type: "bar",
        },
        {
          label: "Missed visits",
          backgroundColor: this.mediumBlueColor,
          hoverBackgroundColor: this.darkBlueColor,
          data: Object.values(data.missedVisitsRate).slice(-barsToDisplay),
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
          fontColor: this.darkGreyColor,
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
          fontColor: this.darkGreyColor,
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
      custom: (tooltip) => {
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
        const registrationPeriodEndNodes = cardNode.querySelectorAll("[data-registrations-period-end]");
        const adjustedPatientCountsNodes = cardNode.querySelectorAll("[data-adjusted-registrations]");
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
        } else {
          missedVisitsRate = missedVisitsRateNode.getAttribute("data-missed-visits-rate");
          visitButNoBPMeasureRate = visitButNoBPMeasureRateNode.getAttribute("data-visit-but-no-bp-measure-rate");
          uncontrolledRate = uncontrolledRateNode.getAttribute("data-uncontrolled-rate");
          controlledRate = controlledRateNode.getAttribute("data-controlled-rate");
          label = mostRecentPeriod;
        }
        const period = data.periodInfo[label];
        const adjustedPatientCounts = data.adjustedPatientCounts[label];
        const totalMissedVisits = data.missedVisits[label];
        const totalVisitButNoBPMeasure = data.visitButNoBPMeasure[label];
        const totalUncontrolledPatients = data.uncontrolledPatients[label];
        const totalControlledPatients = data.controlledPatients[label];

        missedVisitsRateNode.innerHTML = missedVisitsRate;
        visitButNoBPMeasureRateNode.innerHTML = visitButNoBPMeasureRate;
        uncontrolledRateNode.innerHTML = uncontrolledRate;
        controlledRateNode.innerHTML = controlledRate;
        missedVisitsPatientsNode.innerHTML = this.formatNumberWithCommas(totalMissedVisits);
        visitButNoBPMeasurePatientsNode.innerHTML = this.formatNumberWithCommas(totalVisitButNoBPMeasure);
        uncontrolledPatientsNode.innerHTML = this.formatNumberWithCommas(totalUncontrolledPatients);
        controlledPatientsNode.innerHTML = this.formatNumberWithCommas(totalControlledPatients);
        periodStartNodes.forEach(node => node.innerHTML = period.bp_control_start_date);
        periodEndNodes.forEach(node => node.innerHTML = period.bp_control_end_date);
        registrationPeriodEndNodes.forEach(node => node.innerHTML = period.bp_control_registration_date);
        adjustedPatientCountsNodes.forEach(node => node.innerHTML = this.formatNumberWithCommas(adjustedPatientCounts));
      },
    };

    const visitDetailsGraphCanvas = document.getElementById("missedVisitDetails");
    if (visitDetailsGraphCanvas) {
      new Chart(visitDetailsGraphCanvas.getContext("2d"), visitDetailsGraphConfig);
    }
  }

  this.setupControlledGraph = (data) => {
    const controlGraphDenominator = window.withLtfu ? data.adjustedPatientCountsWithLtfu : data.adjustedPatientCounts;
    const controlledGraphNumerator = data.controlledPatients;
    const controlledGraphRate = window.withLtfu ? data.controlWithLtfuRate : data.controlRate;

    const controlledGraphConfig = this.createBaseGraphConfig();
    controlledGraphConfig.data = {
      labels: Object.keys(controlledGraphRate),
      datasets: [{
        label: "BP controlled",
        backgroundColor: this.lightGreenColor,
        borderColor: this.mediumGreenColor,
        borderWidth: 2,
        pointBackgroundColor: this.whiteColor,
        hoverBackgroundColor: this.whiteColor,
        hoverBorderWidth: 2,
        data: Object.values(controlledGraphRate),
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
          fontColor: this.darkGreyColor,
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
          fontColor: this.darkGreyColor,
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
      custom: (tooltip) => {
        let hoveredOnDatapoint = tooltip.dataPoints
        if(hoveredOnDatapoint)
          populateControlledGraph(tooltip.dataPoints[0].label);
        else
          populateControlledGraphDefault();
      }
    };

    let populateControlledGraph = (period) => {
      const cardNode = document.getElementById("bp-controlled");
      const rateNode = cardNode.querySelector("[data-rate]");
      const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
      const periodStartNode = cardNode.querySelector("[data-period-start]");
      const periodEndNode = cardNode.querySelector("[data-period-end]");
      const registrationsNode = cardNode.querySelector("[data-registrations]");
      const registrationsPeriodEndNode = cardNode.querySelector("[data-registrations-period-end]");
      const rate = controlledGraphRate[period] + "%";

      const periodInfo = data.periodInfo[period];
      const adjustedPatientCounts = controlGraphDenominator[period];
      const totalPatients = controlledGraphNumerator[period];

      rateNode.innerHTML = rate;
      totalPatientsNode.innerHTML = this.formatNumberWithCommas(totalPatients);
      periodStartNode.innerHTML = periodInfo.bp_control_start_date;
      periodEndNode.innerHTML = periodInfo.bp_control_end_date;
      registrationsNode.innerHTML = this.formatNumberWithCommas(adjustedPatientCounts);
      registrationsPeriodEndNode.innerHTML = periodInfo.bp_control_registration_date;
    }

    let populateControlledGraphDefault = () => {
      const cardNode = document.getElementById("bp-controlled");
      const mostRecentPeriod = cardNode.getAttribute("data-period");

      populateControlledGraph(mostRecentPeriod);
    }

    const controlledGraphCanvas = document.getElementById("controlledPatientsTrend");
    if (controlledGraphCanvas) {
      const controlledGraph = new Chart(controlledGraphCanvas.getContext("2d"), controlledGraphConfig);
      populateControlledGraphDefault();

      return controlledGraph;
    }
  }

  this.setupUncontrolledGraph = (data) => {
    const controlGraphDenominator = window.withLtfu ? data.adjustedPatientCountsWithLtfu : data.adjustedPatientCounts;
    const uncontrolledGraphNumerator = data.uncontrolledPatients;
    const uncontrolledGraphRate = window.withLtfu ? data.uncontrolledWithLtfuRate : data.uncontrolledRate;

    const uncontrolledGraphConfig = this.createBaseGraphConfig();
    uncontrolledGraphConfig.data = {
      labels: Object.keys(uncontrolledGraphRate),
      datasets: [{
        label: "BP uncontrolled",
        backgroundColor: this.lightRedColor,
        borderColor: this.mediumRedColor,
        borderWidth: 2,
        pointBackgroundColor: this.whiteColor,
        hoverBackgroundColor: this.whiteColor,
        hoverBorderWidth: 2,
        data: Object.values(uncontrolledGraphRate),
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
          fontColor: this.darkGreyColor,
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
          fontColor: this.darkGreyColor,
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
      custom: (tooltip) => {
        let hoveredOnDatapoint = tooltip.dataPoints
        if(hoveredOnDatapoint)
          populateUncontrolledGraph(tooltip.dataPoints[0].label);
        else
          populateUncontrolledGraphDefault();
      }
    };

    let populateUncontrolledGraph = (period) => {
      const cardNode = document.getElementById("bp-uncontrolled");
      const rateNode = cardNode.querySelector("[data-rate]");
      const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
      const periodStartNode = cardNode.querySelector("[data-period-start]");
      const periodEndNode = cardNode.querySelector("[data-period-end]");
      const registrationsNode = cardNode.querySelector("[data-registrations]");
      const registrationsPeriodEndNode = cardNode.querySelector("[data-registrations-period-end]")
      const rate = uncontrolledGraphRate[period] + "%";

      const periodInfo = data.periodInfo[period];
      const adjustedPatientCounts = controlGraphDenominator[period];
      const totalPatients = uncontrolledGraphNumerator[period];

      rateNode.innerHTML = rate;
      totalPatientsNode.innerHTML = this.formatNumberWithCommas(totalPatients);
      periodStartNode.innerHTML = periodInfo.bp_control_start_date;
      periodEndNode.innerHTML = periodInfo.bp_control_end_date;
      registrationsNode.innerHTML = this.formatNumberWithCommas(adjustedPatientCounts);
      registrationsPeriodEndNode.innerHTML = periodInfo.bp_control_registration_date;
    }

    let populateUncontrolledGraphDefault = () => {
      const cardNode = document.getElementById("bp-uncontrolled");
      const mostRecentPeriod = cardNode.getAttribute("data-period");

      populateUncontrolledGraph(mostRecentPeriod);
    }

    const uncontrolledGraphCanvas = document.getElementById("uncontrolledPatientsTrend");
    if (uncontrolledGraphCanvas) {
      const uncontrolledGraph = new Chart(uncontrolledGraphCanvas.getContext("2d"), uncontrolledGraphConfig);
      populateUncontrolledGraphDefault();

      return uncontrolledGraph;
    }
  }

  this.initializeTables = () => {
    const tableSortAscending = {descending: false};
    const tableSortDescending = {descending: true};

    const regionComparisonTable = document.getElementById("region-comparison-table");

    // Start: Remove with :report_with_exclusions feature flag
    const cumulativeRegistrationsTable = document.getElementById("cumulative-registrations-table");
    const htnNotUnderControlTable = document.getElementById("htn-not-under-control-table");
    const noBPMeasureTable = document.getElementById("no-bp-measure-table");
    const htnControlledTable = document.getElementById("htn-controlled-table");
    // End: Remove with :report_with_exclusions feature flag

    if (regionComparisonTable) {
      new Tablesort(regionComparisonTable, tableSortAscending);
    }

    // Start: Remove with :report_with_exclusions feature flag
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
    // End: Remove with :report_with_exclusions feature flag
  };

  this.getReportingData = () => {
    const jsonData = JSON.parse(this.getChartDataNode().textContent);

    return {
      controlledPatients: jsonData.controlled_patients,
      controlRate: jsonData.controlled_patients_rate,
      controlWithLtfuRate: jsonData.controlled_patients_with_ltfu_rate,
      missedVisits: jsonData.missed_visits,
      missedVisitsRate: jsonData.missed_visits_rate,
      missedVisitsWithLtfuRate: jsonData.missed_visits_with_ltfu_rate,
      monthlyRegistrations: jsonData.registrations,
      adjustedPatientCounts: jsonData.adjusted_patient_counts,
      adjustedPatientCountsWithLtfu: jsonData.adjusted_patient_counts_with_ltfu,
      cumulativeRegistrations: jsonData.cumulative_registrations,
      uncontrolledPatients: jsonData.uncontrolled_patients,
      uncontrolledRate: jsonData.uncontrolled_patients_rate,
      uncontrolledWithLtfuRate: jsonData.uncontrolled_patients_with_ltfu_rate,
      visitButNoBPMeasure: jsonData.visited_without_bp_taken,
      visitButNoBPMeasureRate: jsonData.visited_without_bp_taken_rate,
      periodInfo: jsonData.period_info
    };
  };

  this.createBaseGraphConfig = () => {
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

  this.createAxisMaxAndStepSize = (data) => {
    const maxDataValue = Math.max(...Object.values(data));
    const maxAxisValue = Math.round(maxDataValue * 1.15);
    const axisStepSize = Math.round(maxAxisValue / 2);

    return {
      max: maxAxisValue,
      stepSize: axisStepSize,
    };
  };

  this.formatNumberWithCommas = (value) => {
    if (value === undefined) {
      return 0;
    }

    if (numeral(value) !== undefined) {
      return numeral(value).format('0,0');
    }

    return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  }
}
