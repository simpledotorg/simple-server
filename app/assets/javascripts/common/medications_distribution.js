MedicationsDispensationGraph = function () {
  const reports = new Reports();

  this.listen = () => {
    this.initializeMedicationsGraph();
  }

  this.getMedicationsGraphData = () => {
    return JSON.parse(reports.getChartDataNode().textContent)["medications_dispensation"];
  }

  this.getMedicationsGraphPeriods = () => {
    return JSON.parse(reports.getChartDataNode().textContent)["medications_dispensation_months"];
  }

  this.initializeMedicationsGraph = () => {
    const graphData = this.getMedicationsGraphData();
    const medicationsGraphConfig = reports.createBaseGraphConfig();
    console.log(graphData)

    let colors = ["#BD3838", "#E77D27", "#729C26", "#007AA6"]
    let datasets = Object.keys(graphData).map(function(bucket, index){
      return {
        label: bucket,
        data: Object.values(graphData[bucket]["percentage"]),
        borderColor: colors[index],
        backgroundColor: colors[index]
      }
    })

    medicationsGraphConfig.plugins = [ChartDataLabels];
    medicationsGraphConfig.type = 'bar';

    console.log(this.getMedicationsGraphPeriods())
    medicationsGraphConfig.data = {
      labels: this.getMedicationsGraphPeriods(),
      datasets: datasets
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
          padding: 0,
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

    medicationsGraphConfig.options.plugins = {
      datalabels: {
        align: 'end',
        color: 'black',
        anchor: 'end',
        offset: 3
      }
    }

    medicationsGraphConfig.options.tooltips = {
      displayColors: false,
      xAlign: 'center',
      yAlign: 'bottom',
      callbacks: {
        title: function(tooltipItem) {
          return ""
        },
        label: function(tooltipItem) {
          return tooltipItem.yLabel + " of X patients";
        },
      }
    }

    const medicationsGraphCanvas = document.getElementById("MedicationsDistribution");
    if (medicationsGraphCanvas) {
      new Chart(medicationsGraphCanvas.getContext("2d"), medicationsGraphConfig);
    }
  }
}
