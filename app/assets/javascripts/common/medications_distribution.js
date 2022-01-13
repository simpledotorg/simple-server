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
    let datasets = Object.keys(graphData).map(function(bucket, index){
      return {
        label: bucket,
        data: Object.values(graphData[bucket]["percentages"]),
        counts :  graphData[bucket]["counts"],
        totals : graphData[bucket]["totals"],
        borderColor: graphData[bucket]["color"],
        backgroundColor: graphData[bucket]["color"]
      }
    })

    medicationsGraphConfig.plugins = [ChartDataLabels];
    medicationsGraphConfig.type = 'bar';
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
        offset: 1,
        font: {
          family:'Roboto Condensed',
          size: 12,
        },
        formatter: function(value) {
            return value + '%';
        }
      }
    }

    medicationsGraphConfig.options.tooltips = {
      displayColors: false,
      xAlign: 'center',
      yAlign: 'top',
      xPadding: 6,
      yPadding: 6,
      caretSize: 3,
      caretPadding: 1,
      callbacks: {
        title: function() {
          return ""
        },
        label: function(tooltipItem, data) {
            let counts = Object.values(data.datasets[tooltipItem.datasetIndex].counts)
            let totals = Object.values(data.datasets[tooltipItem.datasetIndex].totals)
          return counts[tooltipItem.index] + " of "  + totals[tooltipItem.index] + " follow-up patients";
        },
      }
    }

    const medicationsGraphCanvas = document.getElementById("MedicationsDistribution");
    if (medicationsGraphCanvas) {
      new Chart(medicationsGraphCanvas.getContext("2d"), medicationsGraphConfig);
    }
    }
}
