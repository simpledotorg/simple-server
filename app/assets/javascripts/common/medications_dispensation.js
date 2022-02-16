MedicationsDispensationGraph = function () {
  const reports = new Reports();

  this.listen = () => {
    this.initializeGraph();
  }

  this.getGraphData = () => {
    return JSON.parse(reports.getChartDataNode().textContent)["medications_dispensation"];
  }

  this.getGraphPeriods = () => {
    let firstBucketData = Object.values(this.getGraphData())[0];
    return Object.keys(firstBucketData["counts"]);
  }

  this.initializeGraph = () => {
    const graphData = this.getGraphData();
    const graphConfig = reports.createBaseGraphConfig();
    let datasets = Object.keys(graphData).map(function(bucket, index){
      return {
        label: bucket,
        data: Object.values(graphData[bucket]["percentages"]),
        numerators: graphData[bucket]["counts"],
        denominators: graphData[bucket]["totals"],
        borderColor: graphData[bucket]["color"],
        backgroundColor: graphData[bucket]["color"]
      }
    })

    graphConfig.plugins = [ChartDataLabels];
    graphConfig.type = 'bar';
    graphConfig.data = {
      labels: this.getGraphPeriods(),
      datasets: datasets
    };

    graphConfig.options.scales = {
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
        minBarLength: 4,
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

    graphConfig.options.plugins = {
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

    graphConfig.options.tooltips = {
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
            let numerators = Object.values(data.datasets[tooltipItem.datasetIndex].numerators);
            let denominators = Object.values(data.datasets[tooltipItem.datasetIndex].denominators);
          return numerators[tooltipItem.index].toLocaleString() + " of " + denominators[tooltipItem.index].toLocaleString() + " follow-up patients";
        },
      }
    }

    const graphCanvas = document.getElementById("MedicationsDispensation");
    if (graphCanvas) {
      new Chart(graphCanvas.getContext("2d"), graphConfig);
    }
  }
}
