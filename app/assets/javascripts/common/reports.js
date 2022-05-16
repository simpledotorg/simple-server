Reports = function (withLtfu) {
  this.darkGreenColor = "rgba(0, 122, 49, 1)";
  this.mediumGreenColor = "rgba(0, 184, 73, 1)";
  this.lightGreenColor = "rgba(242, 248, 245, 0.5)";
  this.darkRedColor = "rgba(184, 22, 49, 1)";
  this.mediumRedColor = "rgba(255, 51, 85, 1)";
  this.lightRedColor = "rgba(255, 235, 238, 0.5)";
  this.darkPurpleColor = "rgba(83, 0, 224, 1)";
  this.lightPurpleColor = "rgba(169, 128, 239, 0.5)";
  this.darkBlueColor = "rgba(12, 57, 102, 1)";
  this.mediumBlueColor = "rgba(0, 117, 235, 1)";
  this.lightBlueColor = "rgba(233, 243, 255, 0.75";
  this.darkGreyColor = "rgba(108, 115, 122, 1)";
  this.mediumGreyColor = "rgba(173, 178, 184, 1)";
  this.lightGreyColor = "rgba(240, 242, 245, 0.9)";
  this.whiteColor = "rgba(255, 255, 255, 1)";
  this.orangeColor = "rgba(255, 122, 0, 1)";
  this.transparent = "rgba(0, 0, 0, 0)";
  this.maroonColor = "rgba(150, 48, 48, 1)";
  this.darkMaroonColor = "rgba(121,30,39,1)";

  this.initialize = () => {
    this.initializeCharts();
    this.initializeTables();
  };

  this.getChartDataNode = () => {
    return document.getElementById("data-json");
  };

  this.initializeCharts = () => {
    const data = this.getReportingData();

    this.setupControlledGraph(data);
    this.setupUncontrolledGraph(data);
    this.setupMissedVisitsGraph(data);
    this.setupCumulativeRegistrationsGraph(data);
    this.setupVisitDetailsGraph(data);
    this.setupBSBelow200Graph(data);
    this.setupCumulativeDiabetesRegistrationsGraph(data);
    this.setupBSOver200Graph(data);
    this.setupDiabetesMissedVisitsGraph(data);
    this.setupDiabetesVisitDetailsGraph(data);
  };

  this.setupControlledGraph = (data) => {
    const adjustedPatients = withLtfu
      ? data.adjustedPatientCountsWithLtfu
      : data.adjustedPatientCounts;
    const controlledGraphNumerator = data.controlledPatients;
    const controlledGraphRate = withLtfu
      ? data.controlWithLtfuRate
      : data.controlRate;

    const controlledGraphConfig = this.createBaseGraphConfig();
    controlledGraphConfig.data = {
      labels: Object.keys(controlledGraphRate),
      datasets: [
        {
          label: "BP controlled",
          backgroundColor: this.lightGreenColor,
          borderColor: this.mediumGreenColor,
          borderWidth: 2,
          pointBackgroundColor: this.whiteColor,
          hoverBackgroundColor: this.whiteColor,
          hoverBorderWidth: 2,
          data: Object.values(controlledGraphRate),
        },
      ],
    };
    controlledGraphConfig.options.scales = {
      xAxes: [
        {
          stacked: true,
          display: true,
          gridLines: {
            display: false,
            drawBorder: true,
          },
          ticks: {
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
          },
        },
      ],
      yAxes: [
        {
          stacked: false,
          display: true,
          gridLines: {
            display: true,
            drawBorder: false,
          },
          ticks: {
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
            stepSize: 25,
            max: 100,
          },
        },
      ],
    };
    controlledGraphConfig.options.tooltips = {
      enabled: false,
      custom: (tooltip) => {
        let hoveredDatapoint = tooltip.dataPoints;
        if (hoveredDatapoint)
          populateControlledGraph(hoveredDatapoint[0].label);
        else populateControlledGraphDefault();
      },
    };

    const populateControlledGraph = (period) => {
      const cardNode = document.getElementById("bp-controlled");
      const rateNode = cardNode.querySelector("[data-rate]");
      const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
      const periodStartNode = cardNode.querySelector("[data-period-start]");
      const periodEndNode = cardNode.querySelector("[data-period-end]");
      const registrationsNode = cardNode.querySelector("[data-registrations]");
      const registrationsPeriodEndNode = cardNode.querySelector(
        "[data-registrations-period-end]"
      );

      const rate = this.formatPercentage(controlledGraphRate[period]);
      const periodInfo = data.periodInfo[period];
      const adjustedPatientCounts = adjustedPatients[period];
      const totalPatients = controlledGraphNumerator[period];

      rateNode.innerHTML = rate;
      totalPatientsNode.innerHTML = this.formatNumberWithCommas(totalPatients);
      periodStartNode.innerHTML = periodInfo.bp_control_start_date;
      periodEndNode.innerHTML = periodInfo.bp_control_end_date;
      registrationsNode.innerHTML = this.formatNumberWithCommas(
        adjustedPatientCounts
      );
      registrationsPeriodEndNode.innerHTML =
        periodInfo.bp_control_registration_date;
    };

    const populateControlledGraphDefault = () => {
      const cardNode = document.getElementById("bp-controlled");
      const mostRecentPeriod = cardNode.getAttribute("data-period");

      populateControlledGraph(mostRecentPeriod);
    };

    const controlledGraphCanvas = document.getElementById(
      "controlledPatientsTrend"
    );
    if (controlledGraphCanvas) {
      new Chart(controlledGraphCanvas.getContext("2d"), controlledGraphConfig);
      populateControlledGraphDefault();
    }
  };

  this.setupUncontrolledGraph = (data) => {
    const adjustedPatients = withLtfu
      ? data.adjustedPatientCountsWithLtfu
      : data.adjustedPatientCounts;
    const uncontrolledGraphNumerator = data.uncontrolledPatients;
    const uncontrolledGraphRate = withLtfu
      ? data.uncontrolledWithLtfuRate
      : data.uncontrolledRate;

    const uncontrolledGraphConfig = this.createBaseGraphConfig();
    uncontrolledGraphConfig.data = {
      labels: Object.keys(uncontrolledGraphRate),
      datasets: [
        {
          label: "BP uncontrolled",
          backgroundColor: this.lightRedColor,
          borderColor: this.mediumRedColor,
          borderWidth: 2,
          pointBackgroundColor: this.whiteColor,
          hoverBackgroundColor: this.whiteColor,
          hoverBorderWidth: 2,
          data: Object.values(uncontrolledGraphRate),
          type: "line",
        },
      ],
    };
    uncontrolledGraphConfig.options.scales = {
      xAxes: [
        {
          stacked: false,
          display: true,
          gridLines: {
            display: false,
            drawBorder: true,
          },
          ticks: {
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
          },
        },
      ],
      yAxes: [
        {
          stacked: false,
          display: true,
          gridLines: {
            display: true,
            drawBorder: false,
          },
          ticks: {
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
            stepSize: 25,
            max: 100,
          },
        },
      ],
    };
    uncontrolledGraphConfig.options.tooltips = {
      enabled: false,
      custom: (tooltip) => {
        let hoveredDatapoint = tooltip.dataPoints;
        if (hoveredDatapoint)
          populateUncontrolledGraph(hoveredDatapoint[0].label);
        else populateUncontrolledGraphDefault();
      },
    };

    const populateUncontrolledGraph = (period) => {
      const cardNode = document.getElementById("bp-uncontrolled");
      const rateNode = cardNode.querySelector("[data-rate]");
      const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
      const periodStartNode = cardNode.querySelector("[data-period-start]");
      const periodEndNode = cardNode.querySelector("[data-period-end]");
      const registrationsNode = cardNode.querySelector("[data-registrations]");
      const registrationsPeriodEndNode = cardNode.querySelector(
        "[data-registrations-period-end]"
      );

      const rate = this.formatPercentage(uncontrolledGraphRate[period]);
      const periodInfo = data.periodInfo[period];
      const adjustedPatientCounts = adjustedPatients[period];
      const totalPatients = uncontrolledGraphNumerator[period];

      rateNode.innerHTML = rate;
      totalPatientsNode.innerHTML = this.formatNumberWithCommas(totalPatients);
      periodStartNode.innerHTML = periodInfo.bp_control_start_date;
      periodEndNode.innerHTML = periodInfo.bp_control_end_date;
      registrationsNode.innerHTML = this.formatNumberWithCommas(
        adjustedPatientCounts
      );
      registrationsPeriodEndNode.innerHTML =
        periodInfo.bp_control_registration_date;
    };

    const populateUncontrolledGraphDefault = () => {
      const cardNode = document.getElementById("bp-uncontrolled");
      const mostRecentPeriod = cardNode.getAttribute("data-period");

      populateUncontrolledGraph(mostRecentPeriod);
    };

    const uncontrolledGraphCanvas = document.getElementById(
      "uncontrolledPatientsTrend"
    );
    if (uncontrolledGraphCanvas) {
      new Chart(
        uncontrolledGraphCanvas.getContext("2d"),
        uncontrolledGraphConfig
      );
      populateUncontrolledGraphDefault();
    }
  };

  this.setupMissedVisitsGraph = (data) => {
    const adjustedPatients = withLtfu
      ? data.adjustedPatientCountsWithLtfu
      : data.adjustedPatientCounts;
    const missedVisitsGraphNumerator = withLtfu
      ? data.missedVisitsWithLtfu
      : data.missedVisits;
    const missedVisitsGraphRate = withLtfu
      ? data.missedVisitsWithLtfuRate
      : data.missedVisitsRate;

    const missedVisitsConfig = this.createBaseGraphConfig();
    missedVisitsConfig.data = {
      labels: Object.keys(missedVisitsGraphRate),
      datasets: [
        {
          label: "Missed visits",
          backgroundColor: this.lightBlueColor,
          borderColor: this.mediumBlueColor,
          borderWidth: 2,
          pointBackgroundColor: this.whiteColor,
          hoverBackgroundColor: this.whiteColor,
          hoverBorderWidth: 2,
          data: Object.values(missedVisitsGraphRate),
          type: "line",
        },
      ],
    };
    missedVisitsConfig.options.scales = {
      xAxes: [
        {
          stacked: false,
          display: true,
          gridLines: {
            display: false,
            drawBorder: true,
          },
          ticks: {
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
          },
        },
      ],
      yAxes: [
        {
          stacked: false,
          display: true,
          gridLines: {
            display: true,
            drawBorder: false,
          },
          ticks: {
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
            stepSize: 25,
            max: 100,
          },
        },
      ],
    };
    missedVisitsConfig.options.tooltips = {
      enabled: false,
      custom: (tooltip) => {
        let hoveredDatapoint = tooltip.dataPoints;
        if (hoveredDatapoint)
          populateMissedVisitsGraph(hoveredDatapoint[0].label);
        else populateMissedVisitsGraphDefault();
      },
    };

    const populateMissedVisitsGraph = (period) => {
      const cardNode = document.getElementById("missed-visits");
      const rateNode = cardNode.querySelector("[data-rate]");
      const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
      const periodStartNode = cardNode.querySelector("[data-period-start]");
      const periodEndNode = cardNode.querySelector("[data-period-end]");
      const registrationsNode = cardNode.querySelector("[data-registrations]");
      const registrationsPeriodEndNode = cardNode.querySelector(
        "[data-registrations-period-end]"
      );

      const rate = this.formatPercentage(missedVisitsGraphRate[period]);
      const periodInfo = data.periodInfo[period];
      const adjustedPatientCounts = adjustedPatients[period];
      const totalPatients = missedVisitsGraphNumerator[period];

      rateNode.innerHTML = rate;
      totalPatientsNode.innerHTML = this.formatNumberWithCommas(totalPatients);
      periodStartNode.innerHTML = periodInfo.bp_control_start_date;
      periodEndNode.innerHTML = periodInfo.bp_control_end_date;
      registrationsNode.innerHTML = this.formatNumberWithCommas(
        adjustedPatientCounts
      );
      registrationsPeriodEndNode.innerHTML =
        periodInfo.bp_control_registration_date;
    };

    const populateMissedVisitsGraphDefault = () => {
      const cardNode = document.getElementById("missed-visits");
      const mostRecentPeriod = cardNode.getAttribute("data-period");

      populateMissedVisitsGraph(mostRecentPeriod);
    };

    const missedVisitsGraphCanvas =
      document.getElementById("missedVisitsTrend");
    if (missedVisitsGraphCanvas) {
      new Chart(missedVisitsGraphCanvas.getContext("2d"), missedVisitsConfig);
      populateMissedVisitsGraphDefault();
    }
  };

  this.setupCumulativeRegistrationsGraph = (data) => {
    const cumulativeRegistrationsYAxis = this.createAxisMaxAndStepSize(
      data.cumulativeRegistrations
    );
    const monthlyRegistrationsYAxis = this.createAxisMaxAndStepSize(
      data.monthlyRegistrations
    );

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
      xAxes: [
        {
          stacked: true,
          display: true,
          gridLines: {
            display: false,
            drawBorder: false,
          },
          ticks: {
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
          },
        },
      ],
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
            display: false,
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
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
            display: false,
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
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
        let hoveredDatapoint = tooltip.dataPoints;
        if (hoveredDatapoint)
          populateCumulativeRegistrationsGraph(hoveredDatapoint[0].label);
        else populateCumulativeRegistrationsGraphDefault();
      },
    };

    const populateCumulativeRegistrationsGraph = (period) => {
      const cardNode = document.getElementById("cumulative-registrations");
      const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
      const registrationsPeriodEndNode = cardNode.querySelector(
        "[data-registrations-period-end]"
      );
      const monthlyRegistrationsNode = cardNode.querySelector(
        "[data-monthly-registrations]"
      );
      const registrationsMonthEndNode = cardNode.querySelector(
        "[data-registrations-month-end]"
      );

      const periodInfo = data.periodInfo[period];
      const cumulativeRegistrations = data.cumulativeRegistrations[period];
      const monthlyRegistrations = data.monthlyRegistrations[period];

      monthlyRegistrationsNode.innerHTML =
        this.formatNumberWithCommas(monthlyRegistrations);
      totalPatientsNode.innerHTML = this.formatNumberWithCommas(
        cumulativeRegistrations
      );
      registrationsPeriodEndNode.innerHTML = periodInfo.bp_control_end_date;
      registrationsMonthEndNode.innerHTML = period;
    };

    const populateCumulativeRegistrationsGraphDefault = () => {
      const cardNode = document.getElementById("cumulative-registrations");
      const mostRecentPeriod = cardNode.getAttribute("data-period");

      populateCumulativeRegistrationsGraph(mostRecentPeriod);
    };

    const cumulativeRegistrationsGraphCanvas = document.getElementById(
      "cumulativeRegistrationsTrend"
    );
    if (cumulativeRegistrationsGraphCanvas) {
      new Chart(
        cumulativeRegistrationsGraphCanvas.getContext("2d"),
        cumulativeRegistrationsGraphConfig
      );
      populateCumulativeRegistrationsGraphDefault();
    }
  };

  this.setupVisitDetailsGraph = (data) => {
    const visitDetailsGraphConfig = this.createBaseGraphConfig();
    visitDetailsGraphConfig.type = "bar";

    const maxBarsToDisplay = 6;
    const barsToDisplay = Math.min(
      Object.keys(data.controlRate).length,
      maxBarsToDisplay
    );

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
          data: Object.values(data.visitButNoBPMeasureRate).slice(
            -barsToDisplay
          ),
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
      xAxes: [
        {
          stacked: true,
          display: true,
          gridLines: {
            display: false,
            drawBorder: false,
          },
          ticks: {
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
          },
        },
      ],
      yAxes: [
        {
          stacked: true,
          display: false,
          gridLines: {
            display: false,
            drawBorder: false,
          },
          ticks: {
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
          },
        },
      ],
    };
    visitDetailsGraphConfig.options.tooltips = {
      mode: "x",
      enabled: false,
      custom: (tooltip) => {
        let hoveredDatapoint = tooltip.dataPoints;
        if (hoveredDatapoint)
          populateVisitDetailsGraph(hoveredDatapoint[0].label);
        else populateVisitDetailsGraphDefault();
      },
    };

    const populateVisitDetailsGraph = (period) => {
      const cardNode = document.getElementById("visit-details");
      const missedVisitsRateNode = cardNode.querySelector(
        "[data-missed-visits-rate]"
      );
      const visitButNoBPMeasureRateNode = cardNode.querySelector(
        "[data-visit-but-no-bp-measure-rate]"
      );
      const uncontrolledRateNode = cardNode.querySelector(
        "[data-uncontrolled-rate]"
      );
      const controlledRateNode = cardNode.querySelector(
        "[data-controlled-rate]"
      );
      const missedVisitsPatientsNode = cardNode.querySelector(
        "[data-missed-visits-patients]"
      );
      const visitButNoBPMeasurePatientsNode = cardNode.querySelector(
        "[data-visit-but-no-bp-measure-patients]"
      );
      const uncontrolledPatientsNode = cardNode.querySelector(
        "[data-uncontrolled-patients]"
      );
      const controlledPatientsNode = cardNode.querySelector(
        "[data-controlled-patients]"
      );
      const periodStartNodes = cardNode.querySelectorAll("[data-period-start]");
      const periodEndNodes = cardNode.querySelectorAll("[data-period-end]");
      const registrationPeriodEndNodes = cardNode.querySelectorAll(
        "[data-registrations-period-end]"
      );
      const adjustedPatientCountsNodes = cardNode.querySelectorAll(
        "[data-adjusted-registrations]"
      );

      const missedVisitsRate = this.formatPercentage(
        data.missedVisitsRate[period]
      );
      const visitButNoBPMeasureRate = this.formatPercentage(
        data.visitButNoBPMeasureRate[period]
      );
      const uncontrolledRate = this.formatPercentage(
        data.uncontrolledRate[period]
      );
      const controlledRate = this.formatPercentage(data.controlRate[period]);

      const periodInfo = data.periodInfo[period];
      const adjustedPatientCounts = data.adjustedPatientCounts[period];
      const totalMissedVisits = data.missedVisits[period];
      const totalVisitButNoBPMeasure = data.visitButNoBPMeasure[period];
      const totalUncontrolledPatients = data.uncontrolledPatients[period];
      const totalControlledPatients = data.controlledPatients[period];

      missedVisitsRateNode.innerHTML = missedVisitsRate;
      visitButNoBPMeasureRateNode.innerHTML = visitButNoBPMeasureRate;
      uncontrolledRateNode.innerHTML = uncontrolledRate;
      controlledRateNode.innerHTML = controlledRate;
      missedVisitsPatientsNode.innerHTML =
        this.formatNumberWithCommas(totalMissedVisits);
      visitButNoBPMeasurePatientsNode.innerHTML = this.formatNumberWithCommas(
        totalVisitButNoBPMeasure
      );
      uncontrolledPatientsNode.innerHTML = this.formatNumberWithCommas(
        totalUncontrolledPatients
      );
      controlledPatientsNode.innerHTML = this.formatNumberWithCommas(
        totalControlledPatients
      );
      periodStartNodes.forEach(
        (node) => (node.innerHTML = periodInfo.bp_control_start_date)
      );
      periodEndNodes.forEach(
        (node) => (node.innerHTML = periodInfo.bp_control_end_date)
      );
      registrationPeriodEndNodes.forEach(
        (node) => (node.innerHTML = periodInfo.bp_control_registration_date)
      );
      adjustedPatientCountsNodes.forEach(
        (node) =>
          (node.innerHTML = this.formatNumberWithCommas(adjustedPatientCounts))
      );
    };

    const populateVisitDetailsGraphDefault = () => {
      const cardNode = document.getElementById("visit-details");
      const mostRecentPeriod = cardNode.getAttribute("data-period");

      populateVisitDetailsGraph(mostRecentPeriod);
    };

    const visitDetailsGraphCanvas =
      document.getElementById("missedVisitDetails");
    if (visitDetailsGraphCanvas) {
      new Chart(
        visitDetailsGraphCanvas.getContext("2d"),
        visitDetailsGraphConfig
      );
      populateVisitDetailsGraphDefault();
    }
  };

  this.setupBSBelow200Graph = (data) => {
    const adjustedPatients = withLtfu
      ? data.adjustedDiabetesPatientCountsWithLtfu
      : data.adjustedDiabetesPatientCounts;

    const bsBelow200Numerator = data.bsBelow200Patients;
    const bsBelow200Rate = withLtfu
      ? data.bsBelow200WithLtfuRate
      : data.bsBelow200Rate;

    const bsBelow200GraphConfig = this.createBaseGraphConfig();
    bsBelow200GraphConfig.data = {
      labels: Object.keys(bsBelow200Rate),
      datasets: [
        {
          label: "Blood sugar <200",
          backgroundColor: this.lightGreenColor,
          borderColor: this.mediumGreenColor,
          borderWidth: 2,
          pointBackgroundColor: this.whiteColor,
          hoverBackgroundColor: this.whiteColor,
          hoverBorderWidth: 2,
          data: Object.values(bsBelow200Rate),
        },
      ],
    };
    bsBelow200GraphConfig.options.scales = {
      xAxes: [
        {
          stacked: true,
          display: true,
          gridLines: {
            display: false,
            drawBorder: true,
          },
          ticks: {
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
          },
        },
      ],
      yAxes: [
        {
          stacked: false,
          display: true,
          gridLines: {
            display: true,
            drawBorder: false,
          },
          ticks: {
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
            stepSize: 25,
            max: 100,
          },
        },
      ],
    };
    bsBelow200GraphConfig.options.tooltips = {
      enabled: false,
      custom: (tooltip) => {
        let hoveredDatapoint = tooltip.dataPoints;
        if (hoveredDatapoint)
          populateBSBelow200Graph(hoveredDatapoint[0].label);
        else populateBSBelow200GraphDefault();
      },
    };

    const populateBSBelow200Graph = (period) => {
      const cardNode = document.getElementById("bs-below-200");
      const rateNode = cardNode.querySelector("[data-rate]");
      const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
      const periodStartNode = cardNode.querySelector("[data-period-start]");
      const periodEndNode = cardNode.querySelector("[data-period-end]");
      const registrationsNode = cardNode.querySelector("[data-registrations]");
      const registrationsPeriodEndNode = cardNode.querySelector(
        "[data-registrations-period-end]"
      );
      const rbsPPBSPercentNode = cardNode.querySelector("[data-rbs-ppbs]");
      const fastingPercentNode = cardNode.querySelector("[data-fasting]");
      const hba1cPercentNode = cardNode.querySelector("[data-hba1c]");

      const rate = this.formatPercentage(bsBelow200Rate[period]);
      const periodInfo = data.periodInfo[period];
      const adjustedPatientCounts = adjustedPatients[period];
      const totalPatients = bsBelow200Numerator[period];

      rateNode.innerHTML = rate;
      totalPatientsNode.innerHTML = this.formatNumberWithCommas(totalPatients);
      periodStartNode.innerHTML = periodInfo.bp_control_start_date;
      periodEndNode.innerHTML = periodInfo.bp_control_end_date;
      registrationsNode.innerHTML = this.formatNumberWithCommas(
        adjustedPatientCounts
      );
      registrationsPeriodEndNode.innerHTML =
        periodInfo.bp_control_registration_date;
      const breakdown = data.bsBelow200BreakdownRates[period];
      rbsPPBSPercentNode.innerHTML = this.formatPercentage(
        breakdown["random"] + breakdown["post_prandial"]
      );
      fastingPercentNode.innerHTML = this.formatPercentage(
        breakdown["fasting"]
      );
      hba1cPercentNode.innerHTML = this.formatPercentage(breakdown["hba1c"]);
    };

    const populateBSBelow200GraphDefault = () => {
      const cardNode = document.getElementById("bs-below-200");
      const mostRecentPeriod = cardNode.getAttribute("data-period");

      populateBSBelow200Graph(mostRecentPeriod);
    };

    const bsBelow200GraphCanvas = document.getElementById(
      "bsBelow200PatientsTrend"
    );
    if (bsBelow200GraphCanvas) {
      new Chart(bsBelow200GraphCanvas.getContext("2d"), bsBelow200GraphConfig);
      populateBSBelow200GraphDefault();
    }
  };

  this.setupBSOver200Graph = (data) => {
    const adjustedPatients = withLtfu
      ? data.adjustedDiabetesPatientCountsWithLtfu
      : data.adjustedDiabetesPatientCounts;

    const bs200to300Numerator = data.bs200to300Patients;
    const bs200to300Rate = withLtfu
      ? data.bs200to300WithLtfuRate
      : data.bs200to300Rate;

    const bsOver300Numerator = data.bsOver300Patients;
    const bsOver300Rate = withLtfu
      ? data.bsOver300WithLtfuRate
      : data.bsOver300Rate;

    const bsOver200GraphConfig = this.createBaseGraphConfig();

    bsOver200GraphConfig.type = "bar";
    bsOver200GraphConfig.data = {
      labels: Object.keys(bsOver300Rate),
      datasets: [
        {
          label: "Blood sugar 200-299",
          backgroundColor: this.mediumRedColor,
          hoverBackgroundColor: this.darkRedColor,
          hoverBorderWidth: 2,
          data: Object.values(bs200to300Rate),
        },
        {
          label: "Blood sugar ≥300",
          backgroundColor: this.maroonColor,
          hoverBackgroundColor: this.darkMaroonColor,
          hoverBorderWidth: 2,
          data: Object.values(bsOver300Rate),
        },
      ],
    };

    bsOver200GraphConfig.options.scales = {
      xAxes: [
        {
          stacked: true,
          display: true,
          gridLines: {
            display: false,
            drawBorder: true,
          },
          ticks: {
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
          },
        },
      ],
      yAxes: [
        {
          stacked: true,
          display: true,
          gridLines: {
            display: true,
            drawBorder: false,
          },
          ticks: {
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
            stepSize: 25,
            max: 100,
          },
        },
      ],
    };
    bsOver200GraphConfig.options.tooltips = {
      mode: "x",
      enabled: false,
      custom: (tooltip) => {
        let hoveredDatapoint = tooltip.dataPoints;
        if (hoveredDatapoint) populateBSOver200Graph(hoveredDatapoint[0].label);
        else populateBSOver200GraphDefault();
      },
    };

    const populateBSOver200Graph = (period) => {
      const cardNode = document.getElementById("bs-over-200");
      const bs200to300rateNode = cardNode.querySelector(
        "[data-bs-200-to-300-rate]"
      );
      const bsOver300rateNode = cardNode.querySelector(
        "[data-bs-over-300-rate]"
      );
      const totalBS200to300PatientsNode = cardNode.querySelector(
        "[data-total-bs-200-to-300-patients]"
      );
      const totalBSOver300PatientsNode = cardNode.querySelector(
        "[data-total-bs-over-300-patients]"
      );
      const periodStartNodes = cardNode.querySelectorAll("[data-period-start]");
      const periodEndNodes = cardNode.querySelectorAll("[data-period-end]");
      const registrationsNodes = cardNode.querySelectorAll(
        "[data-registrations]"
      );
      const registrationsPeriodEndNodes = cardNode.querySelectorAll(
        "[data-registrations-period-end]"
      );

      const periodInfo = data.periodInfo[period];
      const adjustedPatientCounts = adjustedPatients[period];

      const totalBS200to300Patients = bs200to300Numerator[period];
      const totalBSOver300Patients = bsOver300Numerator[period];

      bs200to300rateNode.innerHTML = this.formatPercentage(
        bs200to300Rate[period]
      );
      bsOver300rateNode.innerHTML = this.formatPercentage(
        bsOver300Rate[period]
      );
      totalBS200to300PatientsNode.innerHTML = this.formatNumberWithCommas(
        totalBS200to300Patients
      );
      totalBSOver300PatientsNode.innerHTML = this.formatNumberWithCommas(
        totalBSOver300Patients
      );
      periodStartNodes.forEach(
        (node) => (node.innerHTML = periodInfo.bp_control_start_date)
      );
      periodEndNodes.forEach(
        (node) => (node.innerHTML = periodInfo.bp_control_end_date)
      );
      registrationsNodes.forEach(
        (node) =>
          (node.innerHTML = this.formatNumberWithCommas(adjustedPatientCounts))
      );
      registrationsPeriodEndNodes.forEach(
        (node) => (node.innerHTML = periodInfo.bp_control_registration_date)
      );
    };

    const populateBSOver200GraphDefault = () => {
      const cardNode = document.getElementById("bs-over-200");
      const mostRecentPeriod = cardNode.getAttribute("data-period");

      populateBSOver200Graph(mostRecentPeriod);
    };

    const bsOver200GraphCanvas = document.getElementById(
      "bsOver200PatientsTrend"
    );
    if (bsOver200GraphCanvas) {
      new Chart(bsOver200GraphCanvas.getContext("2d"), bsOver200GraphConfig);
      populateBSOver200GraphDefault();
    }
  };

  this.setupCumulativeDiabetesRegistrationsGraph = (data) => {
    const cumulativeDiabetesRegistrationsYAxis = this.createAxisMaxAndStepSize(
      data.cumulativeDiabetesRegistrations
    );
    const monthlyDiabetesRegistrationsYAxis = this.createAxisMaxAndStepSize(
      data.monthlyDiabetesRegistrations
    );
    const monthlyDiabetesFollowupsYAxis = this.createAxisMaxAndStepSize(
      data.monthlyDiabetesFollowups
    );

    const cumulativeDiabetesRegistrationsGraphConfig =
      this.createBaseGraphConfig();
    cumulativeDiabetesRegistrationsGraphConfig.type = "bar";
    cumulativeDiabetesRegistrationsGraphConfig.data = {
      labels: Object.keys(data.cumulativeDiabetesRegistrations),
      datasets: [
        {
          yAxisID: "cumulativeDiabetesRegistrations",
          label: "cumulative diabetes registrations",
          backgroundColor: this.transparent,
          borderColor: this.darkPurpleColor,
          borderWidth: 2,
          pointBackgroundColor: this.whiteColor,
          hoverBackgroundColor: this.whiteColor,
          hoverBorderWidth: 2,
          data: Object.values(data.cumulativeDiabetesRegistrations),
          type: "line",
        },
        {
          yAxisID: "monthlyDiabetesFollowups",
          label: "monthly diabetes followups",
          backgroundColor: this.transparent,
          borderColor: this.orangeColor,
          borderWidth: 2,
          pointBackgroundColor: this.whiteColor,
          hoverBackgroundColor: this.whiteColor,
          hoverBorderWidth: 2,
          data: Object.values(data.monthlyDiabetesFollowups),
          type: "line",
        },
        {
          yAxisID: "monthlyDiabetesRegistrations",
          label: "monthly diabetes registrations",
          backgroundColor: this.lightPurpleColor,
          hoverBackgroundColor: this.darkPurpleColor,
          data: Object.values(data.monthlyDiabetesRegistrations),
          type: "bar",
        },
      ],
    };
    cumulativeDiabetesRegistrationsGraphConfig.options.tooltips = {
      enabled: false,
      custom: (tooltip) => {
        let hoveredDatapoint = tooltip.dataPoints;
        if (hoveredDatapoint)
          populateCumulativeDiabetesRegistrationsGraph(
            hoveredDatapoint[0].label
          );
        else populateCumulativeDiabetesRegistrationsGraphDefault();
      },
    };
    cumulativeDiabetesRegistrationsGraphConfig.options.scales = {
      xAxes: [
        {
          stacked: true,
          display: true,
          gridLines: {
            display: false,
            drawBorder: false,
          },
          ticks: {
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
          },
        },
      ],
      yAxes: [
        {
          id: "cumulativeDiabetesRegistrations",
          position: "left",
          stacked: true,
          display: true,
          gridLines: {
            display: false,
            drawBorder: false,
          },
          ticks: {
            display: false,
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
            stepSize: cumulativeDiabetesRegistrationsYAxis.stepSize,
            max: cumulativeDiabetesRegistrationsYAxis.max,
            callback: (label) => {
              return this.formatNumberWithCommas(label);
            },
          },
        },
        {
          id: "monthlyDiabetesRegistrations",
          position: "right",
          stacked: true,
          display: true,
          gridLines: {
            display: true,
            drawBorder: false,
          },
          ticks: {
            display: false,
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
            stepSize: monthlyDiabetesRegistrationsYAxis.stepSize,
            max: monthlyDiabetesRegistrationsYAxis.max,
            callback: (label) => {
              return this.formatNumberWithCommas(label);
            },
          },
        },
        {
          id: "monthlyDiabetesFollowups",
          position: "right",
          stacked: true,
          display: true,
          gridLines: {
            display: false,
            drawBorder: false,
          },
          ticks: {
            display: false,
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
            stepSize: cumulativeDiabetesRegistrationsYAxis.stepSize,
            max: cumulativeDiabetesRegistrationsYAxis.max,
            callback: (label) => {
              return this.formatNumberWithCommas(label);
            },
          },
        },
      ],
    };

    const populateCumulativeDiabetesRegistrationsGraph = (period) => {
      const cardNode = document.getElementById(
        "cumulative-diabetes-registrations"
      );
      const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
      const registrationsPeriodEndNode = cardNode.querySelector(
        "[data-registrations-period-end]"
      );
      const monthlyRegistrationsNode = cardNode.querySelector(
        "[data-monthly-registrations]"
      );
      const registrationsMonthEndNode = cardNode.querySelector(
        "[data-registrations-month-end]"
      );
      const monthlyFollowUpsNode = cardNode.querySelector(
        "[data-monthly-follow-ups]"
      );
      const followupsMonthEndNode = cardNode.querySelector(
        "[data-follow-ups-month-end]"
      );

      const periodInfo = data.periodInfo[period];
      const cumulativeDiabetesRegistrations =
        data.cumulativeDiabetesRegistrations[period];
      const monthlyDiabetesRegistrations =
        data.monthlyDiabetesRegistrations[period];
      const monthlyDiabetesFollowups = data.monthlyDiabetesFollowups[period];

      monthlyRegistrationsNode.innerHTML = this.formatNumberWithCommas(
        monthlyDiabetesRegistrations
      );
      totalPatientsNode.innerHTML = this.formatNumberWithCommas(
        cumulativeDiabetesRegistrations
      );
      monthlyFollowUpsNode.innerHTML = this.formatNumberWithCommas(
        monthlyDiabetesFollowups
      );
      registrationsPeriodEndNode.innerHTML = periodInfo.bp_control_end_date;
      registrationsMonthEndNode.innerHTML = period;
      followupsMonthEndNode.innerHTML = period;
    };

    const populateCumulativeDiabetesRegistrationsGraphDefault = () => {
      const cardNode = document.getElementById(
        "cumulative-diabetes-registrations"
      );
      const mostRecentPeriod = cardNode.getAttribute("data-period");

      populateCumulativeDiabetesRegistrationsGraph(mostRecentPeriod);
    };

    const cumulativeDiabetesRegistrationsGraphCanvas = document.getElementById(
      "cumulativeDiabetesRegistrationsTrend"
    );
    if (cumulativeDiabetesRegistrationsGraphCanvas) {
      new Chart(
        cumulativeDiabetesRegistrationsGraphCanvas.getContext("2d"),
        cumulativeDiabetesRegistrationsGraphConfig
      );
      populateCumulativeDiabetesRegistrationsGraphDefault();
    }
  };

  this.setupDiabetesMissedVisitsGraph = (data) => {
    const adjustedDiabetesPatients = withLtfu
      ? data.adjustedDiabetesPatientCountsWithLtfu
      : data.adjustedDiabetesPatientCounts;
    const diabetesMissedVisitsGraphNumerator = withLtfu
      ? data.diabetesMissedVisitsWithLtfu
      : data.diabetesMissedVisits;
    const diabetesMissedVisitsGraphRate = withLtfu
      ? data.diabetesMissedVisitsWithLtfuRate
      : data.diabetesMissedVisitsRate;

    const diabetesMissedVisitsConfig = this.createBaseGraphConfig();
    diabetesMissedVisitsConfig.data = {
      labels: Object.keys(diabetesMissedVisitsGraphRate),
      datasets: [
        {
          label: "Missed visits",
          backgroundColor: this.lightBlueColor,
          borderColor: this.mediumBlueColor,
          borderWidth: 2,
          pointBackgroundColor: this.whiteColor,
          hoverBackgroundColor: this.whiteColor,
          hoverBorderWidth: 2,
          data: Object.values(diabetesMissedVisitsGraphRate),
          type: "line",
        },
      ],
    };
    diabetesMissedVisitsConfig.options.scales = {
      xAxes: [
        {
          stacked: false,
          display: true,
          gridLines: {
            display: false,
            drawBorder: true,
          },
          ticks: {
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
          },
        },
      ],
      yAxes: [
        {
          stacked: false,
          display: true,
          gridLines: {
            display: true,
            drawBorder: false,
          },
          ticks: {
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
            stepSize: 25,
            max: 100,
          },
        },
      ],
    };
    diabetesMissedVisitsConfig.options.tooltips = {
      enabled: false,
      custom: (tooltip) => {
        let hoveredDatapoint = tooltip.dataPoints;
        if (hoveredDatapoint)
          populateDiabetesMissedVisitsGraph(hoveredDatapoint[0].label);
        else populateDiabetesMissedVisitsGraphDefault();
      },
    };

    const populateDiabetesMissedVisitsGraph = (period) => {
      const cardNode = document.getElementById("diabetes-missed-visits");
      const rateNode = cardNode.querySelector("[data-rate]");
      const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
      const periodStartNode = cardNode.querySelector("[data-period-start]");
      const periodEndNode = cardNode.querySelector("[data-period-end]");
      const registrationsNode = cardNode.querySelector("[data-registrations]");
      const registrationsPeriodEndNode = cardNode.querySelector(
        "[data-registrations-period-end]"
      );

      const periodInfo = data.periodInfo[period];
      const adjustedPatientCounts = adjustedDiabetesPatients[period];
      const totalPatients = diabetesMissedVisitsGraphNumerator[period];

      rateNode.innerHTML = this.formatPercentage(
        diabetesMissedVisitsGraphRate[period]
      );
      totalPatientsNode.innerHTML = this.formatNumberWithCommas(totalPatients);
      periodStartNode.innerHTML = periodInfo.bp_control_start_date;
      periodEndNode.innerHTML = periodInfo.bp_control_end_date;
      registrationsNode.innerHTML = this.formatNumberWithCommas(
        adjustedPatientCounts
      );
      registrationsPeriodEndNode.innerHTML =
        periodInfo.bp_control_registration_date;
    };

    const populateDiabetesMissedVisitsGraphDefault = () => {
      const cardNode = document.getElementById("diabetes-missed-visits");
      const mostRecentPeriod = cardNode.getAttribute("data-period");

      populateDiabetesMissedVisitsGraph(mostRecentPeriod);
    };

    const diabetesMissedVisitsGraphCanvas = document.getElementById(
      "diabetesMissedVisitsTrend"
    );
    if (diabetesMissedVisitsGraphCanvas) {
      new Chart(
        diabetesMissedVisitsGraphCanvas.getContext("2d"),
        diabetesMissedVisitsConfig
      );
      populateDiabetesMissedVisitsGraphDefault();
    }
  };

  this.setupDiabetesVisitDetailsGraph = (data) => {
    const diabetesVisitDetailsGraphConfig = this.createBaseGraphConfig();
    diabetesVisitDetailsGraphConfig.type = "bar";

    const maxBarsToDisplay = 6;
    const barsToDisplay = Math.min(
      Object.keys(data.bsBelow200Rate).length,
      maxBarsToDisplay
    );

    diabetesVisitDetailsGraphConfig.data = {
      labels: Object.keys(data.bsBelow200Rate).slice(-barsToDisplay),
      datasets: [
        {
          label: "Blood sugar <200",
          backgroundColor: this.mediumGreenColor,
          hoverBackgroundColor: this.darkGreenColor,
          data: Object.values(data.bsBelow200Rate).slice(-barsToDisplay),
          type: "bar",
        },
        {
          label: "Blood sugar 200-299",
          backgroundColor: this.mediumRedColor,
          hoverBackgroundColor: this.darkRedColor,
          data: Object.values(data.bs200to300Rate).slice(-barsToDisplay),
          type: "bar",
        },
        {
          label: "Blood sugar ≥300",
          backgroundColor: this.maroonColor,
          hoverBackgroundColor: this.darkMaroonColor,
          data: Object.values(data.bsOver300Rate).slice(-barsToDisplay),
          type: "bar",
        },
        {
          label: "Visit but no blood sugar measure",
          backgroundColor: this.mediumGreyColor,
          hoverBackgroundColor: this.darkGreyColor,
          data: Object.values(data.visitButNoBSMeasureRate).slice(
            -barsToDisplay
          ),
          type: "bar",
        },
        {
          label: "Missed visits",
          backgroundColor: this.mediumBlueColor,
          hoverBackgroundColor: this.darkBlueColor,
          data: Object.values(data.diabetesMissedVisitsRate).slice(
            -barsToDisplay
          ),
          type: "bar",
        },
      ],
    };
    diabetesVisitDetailsGraphConfig.options.scales = {
      xAxes: [
        {
          stacked: true,
          display: true,
          gridLines: {
            display: false,
            drawBorder: false,
          },
          ticks: {
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
          },
        },
      ],
      yAxes: [
        {
          stacked: true,
          display: false,
          gridLines: {
            display: false,
            drawBorder: false,
          },
          ticks: {
            autoSkip: false,
            fontColor: this.darkGreyColor,
            fontSize: 10,
            fontFamily: "Roboto",
            padding: 8,
            min: 0,
            beginAtZero: true,
          },
        },
      ],
    };
    diabetesVisitDetailsGraphConfig.options.tooltips = {
      mode: "x",
      enabled: false,
      custom: (tooltip) => {
        let hoveredDatapoint = tooltip.dataPoints;
        if (hoveredDatapoint)
          populateDiabetesVisitDetailsGraph(hoveredDatapoint[0].label);
        else populateDiabetesVisitDetailsGraphDefault();
      },
    };

    const populateDiabetesVisitDetailsGraph = (period) => {
      const cardNode = document.getElementById("diabetes-visit-details");
      const missedVisitsRateNode = cardNode.querySelector(
        "[data-missed-visits-rate]"
      );
      const visitButNoBSMeasureRateNode = cardNode.querySelector(
        "[data-visit-but-no-bs-measure-rate]"
      );
      const bsBelow200RateNode = cardNode.querySelector(
        "[data-bs-below-200-rate]"
      );
      const bs200To300RateNode = cardNode.querySelector(
        "[data-bs-200-to-300-rate]"
      );
      const bsOver300RateNode = cardNode.querySelector(
        "[data-bs-over-300-rate]"
      );
      const missedVisitsPatientsNode = cardNode.querySelector(
        "[data-missed-visits-patients]"
      );
      const visitButNoBSMeasurePatientsNode = cardNode.querySelector(
        "[data-visit-but-no-bs-measure-patients]"
      );
      const bsOver300PatientsNode = cardNode.querySelector(
        "[data-bs-over-300-patients]"
      );
      const bs200To300PatientsNode = cardNode.querySelector(
        "[data-bs-200-to-300-patients]"
      );
      const bsBelow200PatientsNode = cardNode.querySelector(
        "[data-bs-below-200-patients]"
      );
      const periodStartNodes = cardNode.querySelectorAll("[data-period-start]");
      const periodEndNodes = cardNode.querySelectorAll("[data-period-end]");
      const registrationPeriodEndNodes = cardNode.querySelectorAll(
        "[data-registrations-period-end]"
      );
      const adjustedPatientCountsNodes = cardNode.querySelectorAll(
        "[data-adjusted-registrations]"
      );

      const missedVisitsRate = this.formatPercentage(
        data.diabetesMissedVisitsRate[period]
      );
      const visitButNoBSMeasureRate = this.formatPercentage(
        data.visitButNoBSMeasureRate[period]
      );
      const bsOver300Rate = this.formatPercentage(data.bsOver300Rate[period]);
      const bs200To300Rate = this.formatPercentage(data.bs200to300Rate[period]);
      const bsBelow200Rate = this.formatPercentage(data.bsBelow200Rate[period]);

      const periodInfo = data.periodInfo[period];
      const adjustedPatientCounts = data.adjustedDiabetesPatientCounts[period];
      const totalMissedVisits = data.diabetesMissedVisits[period];
      const totalVisitButNoBSMeasure = data.visitButNoBSMeasure[period];
      const totalBSOver300Patients = data.bsOver300Patients[period];
      const totalBS200To300Patients = data.bs200to300Patients[period];
      const totalBSBelow200Patients = data.bsBelow200Patients[period];

      missedVisitsRateNode.innerHTML = missedVisitsRate;
      visitButNoBSMeasureRateNode.innerHTML = visitButNoBSMeasureRate;
      bsOver300RateNode.innerHTML = bsOver300Rate;
      bs200To300RateNode.innerHTML = bs200To300Rate;
      bsBelow200RateNode.innerHTML = bsBelow200Rate;
      missedVisitsPatientsNode.innerHTML =
        this.formatNumberWithCommas(totalMissedVisits);
      visitButNoBSMeasurePatientsNode.innerHTML = this.formatNumberWithCommas(
        totalVisitButNoBSMeasure
      );
      bsOver300PatientsNode.innerHTML = this.formatNumberWithCommas(
        totalBSOver300Patients
      );
      bs200To300PatientsNode.innerHTML = this.formatNumberWithCommas(
        totalBS200To300Patients
      );
      bsBelow200PatientsNode.innerHTML = this.formatNumberWithCommas(
        totalBSBelow200Patients
      );

      periodStartNodes.forEach(
        (node) => (node.innerHTML = periodInfo.bp_control_start_date)
      );
      periodEndNodes.forEach(
        (node) => (node.innerHTML = periodInfo.bp_control_end_date)
      );
      registrationPeriodEndNodes.forEach(
        (node) => (node.innerHTML = periodInfo.bp_control_registration_date)
      );
      adjustedPatientCountsNodes.forEach(
        (node) =>
          (node.innerHTML = this.formatNumberWithCommas(adjustedPatientCounts))
      );
    };

    const populateDiabetesVisitDetailsGraphDefault = () => {
      const cardNode = document.getElementById("diabetes-visit-details");
      const mostRecentPeriod = cardNode.getAttribute("data-period");

      populateDiabetesVisitDetailsGraph(mostRecentPeriod);
    };

    const diabetesVisitDetailsGraphCanvas = document.getElementById(
      "diabetesVisitDetails"
    );
    if (diabetesVisitDetailsGraphCanvas) {
      new Chart(
        diabetesVisitDetailsGraphCanvas.getContext("2d"),
        diabetesVisitDetailsGraphConfig
      );
      populateDiabetesVisitDetailsGraphDefault();
    }
  };

  this.initializeTables = () => {
    const tableSortAscending = { descending: false };
    const regionComparisonTable = document.getElementById(
      "region-comparison-table"
    );

    if (regionComparisonTable) {
      new Tablesort(regionComparisonTable, tableSortAscending);
    }
  };

  this.getReportingData = () => {
    const jsonData = JSON.parse(this.getChartDataNode().textContent);

    return {
      controlledPatients: jsonData.controlled_patients,
      controlRate: jsonData.controlled_patients_rate,
      controlWithLtfuRate: jsonData.controlled_patients_with_ltfu_rate,
      missedVisits: jsonData.missed_visits,
      missedVisitsWithLtfu: jsonData.missed_visits_with_ltfu,
      missedVisitsRate: jsonData.missed_visits_rate,
      missedVisitsWithLtfuRate: jsonData.missed_visits_with_ltfu_rate,
      diabetesMissedVisits: jsonData.diabetes_missed_visits,
      diabetesMissedVisitsWithLtfu: jsonData.diabetes_missed_visits_with_ltfu,
      diabetesMissedVisitsRate: jsonData.diabetes_missed_visits_rates,
      diabetesMissedVisitsWithLtfuRate:
        jsonData.diabetes_missed_visits_with_ltfu_rates,
      monthlyRegistrations: jsonData.registrations,
      monthlyDiabetesRegistrations: jsonData.diabetes_registrations,
      monthlyDiabetesFollowups: jsonData.monthly_diabetes_followups,
      adjustedPatientCounts: jsonData.adjusted_patient_counts,
      adjustedPatientCountsWithLtfu: jsonData.adjusted_patient_counts_with_ltfu,
      cumulativeRegistrations: jsonData.cumulative_registrations,
      cumulativeDiabetesRegistrations:
        jsonData.cumulative_diabetes_registrations,
      uncontrolledPatients: jsonData.uncontrolled_patients,
      uncontrolledRate: jsonData.uncontrolled_patients_rate,
      uncontrolledWithLtfuRate: jsonData.uncontrolled_patients_with_ltfu_rate,
      visitButNoBPMeasure: jsonData.visited_without_bp_taken,
      visitButNoBPMeasureRate: jsonData.visited_without_bp_taken_rates,
      periodInfo: jsonData.period_info,
      adjustedDiabetesPatientCounts: jsonData.adjusted_diabetes_patient_counts,
      adjustedDiabetesPatientCountsWithLtfu:
        jsonData.adjusted_diabetes_patient_counts_with_ltfu,
      bsBelow200Patients: jsonData.bs_below_200_patients,
      bsBelow200Rate: jsonData.bs_below_200_rates,
      bsBelow200WithLtfuRate: jsonData.bs_below_200_with_ltfu_rates,
      bsBelow200BreakdownRates: jsonData.bs_below_200_breakdown_rates,
      bs200to300Patients: jsonData.bs_200_to_300_patients,
      bs200to300Rate: jsonData.bs_200_to_300_rates,
      bs200to300WithLtfuRate: jsonData.bs_200_to_300_with_ltfu_rates,
      bsOver300Patients: jsonData.bs_over_300_patients,
      bsOver300Rate: jsonData.bs_over_300_rates,
      bsOver300WithLtfuRate: jsonData.bs_over_300_with_ltfu_rates,
      visitButNoBSMeasure: jsonData.visited_without_bs_taken,
      visitButNoBSMeasureRate: jsonData.visited_without_bs_taken_rates,
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
  };

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
      return numeral(value).format("0,0");
    }

    return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  };

  this.formatPercentage = (number) => {
    return (number || 0) + "%";
  };
};
