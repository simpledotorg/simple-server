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

  this.getPatientBreakdownData = () => {
    return JSON.parse(reports.getChartDataNode().textContent)["patient_breakdown"];
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

    const chartSegments = {
      "ltfu_patients": { "description" : "Lost to follow-up", color: reports.darkBlueColor},
      "not_ltfu_patients": { "description": "Not lost to follow-up", color: reports.mediumGreenColor},
      "dead_patients": {"description": "Died", color: reports.mediumRedColor}
    }

    const chartLabels = Object.keys(chartSegments).filter(el => data[el] !== 0)
    const chartData = chartLabels.map(el => data[el])
    const transferredPatients = {
      ltfu_patients: data["ltfu_transferred_patients"],
      not_ltfu_patients: data["not_ltfu_transferred_patients"],
    }

    const breakdownChartConfig = reports.createBaseGraphConfig();
    breakdownChartConfig.type = "outlabeledPie";
    breakdownChartConfig.data = {
      labels: chartLabels,
      datasets: [{
        borderColor: this.whiteColor,
        borderWidth: 1,
        data: chartData,
        backgroundColor: chartLabels.map(label => chartSegments[label]["color"])
      }]
    };
    breakdownChartConfig.options.layout.padding.left = 30;
    breakdownChartConfig.options.layout.padding.right = 30;
    breakdownChartConfig.options.zoomOutPercentage = 7;
    breakdownChartConfig.options.tooltips = {
      caretSize: 0,
      backgroundColor: "rgba(0,0,0,0.6)",
      xPadding: 10,
      yPadding: 10,
      displayColors: false,
      titleFontSize: 15,
      titleFontFamily: "Roboto Condensed",
      bodyFontSize: 14,
      bodyFontFamily: "Roboto Condensed",
      callbacks: {
        title: ([tooltipItem], tooltipData) => {
          const label = tooltipData.labels[tooltipItem.index];
          return chartSegments[label]["description"];
        },
        label: (tooltipItem, tooltipData) => {
          const label = tooltipData.labels[tooltipItem.index];
          let tooltipBody = [`Total: ${reports.formatNumberWithCommas(data[label])}`];
          if (transferredPatients[label] !== undefined) {
            tooltipBody.push(`Transferred-out: ${transferredPatients[label]}`)
          }
          return tooltipBody;
        },
      }
    }
    breakdownChartConfig.options.plugins = {
      outlabels: {
        text: '%p',
        backgroundColor: "rgba(255, 255, 255, 1)",
        color: "black",
        stretch: 15,
        lineColor: "#ADB2B8",
        padding: 1,
        lineWidth: 1,
        font: {
          family: "Roboto Condensed",
          resizable: true,
          minSize: 13,
          maxSize: 18
        }
      }
    }

    const breakdownChartCanvas = document.getElementById("patientBreakdownCanvas");
    if (breakdownChartCanvas) {
      new Chart(breakdownChartCanvas.getContext("2d"), breakdownChartConfig);
    }
  }
}
