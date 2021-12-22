MonthlyMedicationsDistribution = function () {
  const reports = new Reports();

  this.listen = () => {
    this.initializeMedicationsGraph();
  }

  this.getMedicationsGraphData = () => {
    const jsonData = {};

    return jsonData;
  }

  this.initializeMedicationsGraph = () => {
    // const data = this.getMedicationsGraphData();
    const medicationsGraphConfig = reports.createBaseGraphConfig();
    medicationsGraphConfig.type = 'bar';
    medicationsGraphConfig.data = {
      labels: ["January", "February", "March"],
      datasets: [
        {
          label: 'Dataset 1',
          data: [10, 25, 30],
          borderColor: "#BD3838",
          backgroundColor: "#BD3838"
        },
        {
          label: 'Dataset 2',
          data: [23, 33, 44],
          borderColor: "#E77D27",
          backgroundColor: "#E77D27"
        },
        {
          label: 'Dataset 3',
          data: [33, 24, 35],
          borderColor: "#729C26",
          backgroundColor: "#729C26"
        },
        {
          label: 'Dataset 4',
          data: [44, 46, 56],
          borderColor: "#007AA6",
          backgroundColor: "#007AA6"
        }
      ]
    };

    medicationsGraphConfig.options.scales = {
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
      }]
    };

    console.log(medicationsGraphConfig);

    const medicationsGraphCanvas = document.getElementById("monthlyMedicationsDistribution");
    if (medicationsGraphCanvas) {
      new Chart(medicationsGraphCanvas.getContext("2d"), medicationsGraphConfig);
    }
  }
}
