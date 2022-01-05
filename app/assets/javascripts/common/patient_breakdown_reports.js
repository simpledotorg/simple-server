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
      cumulativeAssignedPatients: jsonData.cumulative_assigned_patients,
      periodInfo: jsonData.period_info
    }
  }

  this.initializeCharts = () => {
    this.initializeLtfuChart();
  }

  this.initializeLtfuChart = () => {
    const data = this.getLtfuChartData();

    const ltfuGraphConfig = reports.createBaseGraphConfig();
    ltfuGraphConfig.data = {
      labels: Object.keys(data.ltfuPatientsRate),
      datasets: [{
        label: "Lost to follow up",
        backgroundColor: reports.lightBlueColor,
        borderColor: reports.darkBlueColor,
        borderWidth: 2,
        pointBackgroundColor: reports.whiteColor,
        hoverBackgroundColor: reports.whiteColor,
        hoverBorderWidth: 2,
        data: Object.values(data.ltfuPatientsRate),
        type: "line",
        datalabels: {labels: {title: null}}
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
        const cumulativeAssignedPatients = data.cumulativeAssignedPatients[label];
        const totalPatients = data.ltfuPatients[label];

        rateNode.innerHTML = rate;
        totalPatientsNode.innerHTML = reports.formatNumberWithCommas(totalPatients);
        periodStartNode.innerHTML = period.ltfu_since_date;
        registrationsNode.innerHTML = reports.formatNumberWithCommas(cumulativeAssignedPatients);
        registrationsPeriodEndNode.innerHTML = period.bp_control_end_date;
      }
    };

    const ltfuGraphCanvas = document.getElementById("ltfuPatients");
    if (ltfuGraphCanvas) {
      new Chart(ltfuGraphCanvas.getContext("2d"), ltfuGraphConfig);
    }
  }
}