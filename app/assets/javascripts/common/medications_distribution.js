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
    let datasets = Object.keys(graphData).map(function(bucket, index){
      return {
        label: bucket,
        data: Object.values(graphData[bucket]["percentages"]),
        borderColor: graphData[bucket]["color"],
        backgroundColor: graphData[bucket]["color"],
          numerator: "Numerator"
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
        label: function(tooltipItem, data) {
            console.log(data)
          return tooltipItem.y + " follow-up patients";
        },
      }
    }

    const medicationsGraphCanvas = document.getElementById("MedicationsDistribution");
    if (medicationsGraphCanvas) {
      new Chart(medicationsGraphCanvas.getContext("2d"), medicationsGraphConfig);
    }
  }
}
