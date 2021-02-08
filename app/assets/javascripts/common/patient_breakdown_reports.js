PatientBreakdownReports = function () {
  const reports = new Reports();

  this.listen = () => {
    this.initializeCharts();
  }

  this.getLtfuChartData = () => {
    const jsonData = JSON.parse(reports.getChartDataNode().textContent)["ltfu_trend"];

    return {
      ltfuPatients: jsonData.ltfu_patients,
      ltfuPatientsRate: jsonData.ltfu_patients_rate,
      cumulativeRegistrations: jsonData.cumulative_registrations,
      periodInfo: jsonData.period_info
    }
  }

  this.getPatientBreakdownData = () => {
    const jsonData = JSON.parse(reports.getChartDataNode().textContent)["patient_breakdown"];

    return {
      "Lost to follow-up" : jsonData["ltfu_patients"],
      "Not lost to follow-up" : jsonData["not_ltfu_patients"],
      "Died": jsonData["dead"]
    }
  }

  this.initializeCharts = () => {
    this.initializeLtfuChart();
    this.initializePatientBreakdownChart();
  }

  this.initializeLtfuChart = () => {
    const data = this.getLtfuChartData();

    const ltfuGraphConfig = reports.createBaseGraphConfig();
    ltfuGraphConfig.data = {
      labels: Object.keys(data.ltfuPatientsRate),
      datasets: [{
        label: "Lost to follow up",
        backgroundColor: reports.lightPurpleColor,
        borderColor: reports.darkPurpleColor,
        borderWidth: 2,
        pointBackgroundColor: reports.whiteColor,
        hoverBackgroundColor: reports.whiteColor,
        hoverBorderWidth: 2,
        data: Object.values(data.ltfuPatientsRate),
        type: "line",
      }],
    };
    ltfuGraphConfig.options.scales = {
      xAxes: [{
        stacked: false,
        display: true,
        gridLines: {
          display: false,
          drawBorder: true,
        },
        ticks: {
          autoSkip: false,
          fontColor: reports.darkGreyColor,
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
          fontColor: reports.darkGreyColor,
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
    ltfuGraphConfig.options.tooltips = {
      enabled: false,
      custom: (tooltip) => {
        const cardNode = document.getElementById("ltfu-trend");
        const mostRecentPeriod = cardNode.getAttribute("data-period");
        const rateNode = cardNode.querySelector("[data-rate]");
        const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
        const periodStartNode = cardNode.querySelector("[data-period-start]");
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
        const cumulativeRegistrations = data.cumulativeRegistrations[label];
        const totalPatients = data.ltfuPatients[label];

        rateNode.innerHTML = rate;
        totalPatientsNode.innerHTML = reports.formatNumberWithCommas(totalPatients);
        periodStartNode.innerHTML = period.start_date;
        registrationsNode.innerHTML = reports.formatNumberWithCommas(cumulativeRegistrations);
        registrationsPeriodEndNode.innerHTML = period.start_date;
      }
    };

    const ltfuGraphCanvas = document.getElementById("ltfuPatients");
    if (ltfuGraphCanvas) {
      new Chart(ltfuGraphCanvas.getContext("2d"), ltfuGraphConfig);
    }
  }

  this.initializePatientBreakdownChart = () => {
    const data = this.getPatientBreakdownData();

    const breakdownChartConfig = reports.createBaseGraphConfig();
    breakdownChartConfig.type = "pie";
    breakdownChartConfig.data = {
      labels: Object.keys(data),
      datasets: [{
        borderColor: this.whiteColor,
        borderWidth: 1,
        data: Object.values(data),
        backgroundColor: [
          reports.mediumRedColor,
          reports.mediumGreenColor,
          reports.mediumBlueColor
        ]
      }]
    };

    const breakdownChartCanvas = document.getElementById("patientBreakdownCanvas");
    if (breakdownChartCanvas) {
      new Chart(breakdownChartCanvas.getContext("2d"), breakdownChartConfig);
    }
  }
}
