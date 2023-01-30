function dashboardReportsChartJSColors() {
  return {
    darkGreen: "rgba(0, 122, 49, 1)",
    mediumGreen: "rgba(0, 184, 73, 1)",
    lightGreen: "rgba(242, 248, 245, 0.5)",
    darkRed: "rgba(184, 22, 49, 1)",
    mediumRed: "rgba(255, 51, 85, 1)",
    lightRed: "rgba(255, 235, 238, 0.5)",
    darkPurple: "rgba(83, 0, 224, 1)",
    lightPurple: "rgba(169, 128, 239, 0.5)",
    darkBlue: "rgba(12, 57, 102, 1)",
    mediumBlue: "rgba(0, 117, 235, 1)",
    lightBlue: "rgba(233, 243, 255, 0.75)",
    darkGrey: "rgba(108, 115, 122, 1)",
    mediumGrey: "rgba(173, 178, 184, 1)",
    lightGrey: "rgba(240, 242, 245, 0.9)",
    white: "rgba(255, 255, 255, 1)",
    amber: "rgba(250, 190, 70, 1)",
    darkAmber: "rgba(223, 165, 50, 1)",
    transparent: "rgba(0, 0, 0, 0)",
    teal: "rgba(48, 184, 166, 1)",
    darkTeal: "rgba(34,140,125,1)",
    maroon: "rgba(71, 0, 0, 1)",
    darkMaroon: "rgba(60,0,0,1)",
  };
}

DashboardReports = () => {
  const colors = dashboardReportsChartJSColors();
  const formatPercentage = (number) => {
    return (number || 0) + "%";
  };

  const formatNumberWithCommas = (value) => {
    if (value === undefined) {
      return 0;
    }

    if (numeral(value) !== undefined) {
      return numeral(value).format("0,0");
    }

    return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  };

  const formatValue = (format, value) => {
    if (!format) {
      return value;
    }

    switch (format) {
      case "percentage":
        return formatPercentage(value)
      case "numberWithCommas":
        return formatNumberWithCommas(value)
      default:
        throw `Unknown format ${format}`;
    }
  }

  const createAxisMaxAndStepSize = (data) => {
    const maxDataValue = Math.max(...Object.values(data));
    const maxAxisValue = Math.round(maxDataValue * 1.15);
    const axisStepSize = Math.round(maxAxisValue / 2);

    return {
      max: maxAxisValue,
      stepSize: axisStepSize,
    };
  };

  const ReportsGraphConfig = {
    bsBelow200PatientsTrend: function (data) {
      const config = {
        data: {
          labels: Object.keys(data.bsBelow200Rate),
          datasets: [
            {
              label: "Blood sugar <200",
              backgroundColor: colors.lightGreen,
              borderColor: colors.mediumGreen,
              borderWidth: 2,
              pointBackgroundColor: colors.white,
              hoverBackgroundColor: colors.white,
              hoverBorderWidth: 2,
              data: Object.values(data.bsBelow200Rate),
            },
          ],
        },
      };
      return withBaseLineConfig(config);
    },

    cumulativeDiabetesRegistrationsTrend: function(data) {
      const cumulativeDiabetesRegistrationsYAxis = createAxisMaxAndStepSize(data.cumulativeDiabetesRegistrations);
      const monthlyDiabetesRegistrationsYAxis = createAxisMaxAndStepSize(data.monthlyDiabetesRegistrations);

      const additionalCumulativeDiabetesRegistrationsTrendConfig = {
        type: "bar",
        data: {
          labels: Object.keys(data.cumulativeDiabetesRegistrations),
          datasets: [
            {
              yAxisID: "yCumulativeDiabetesRegistrations",
              label: "cumulative diabetes registrations",
              backgroundColor: colors.transparent,
              borderColor: colors.darkPurple,
              borderWidth: 2,
              pointBackgroundColor: colors.white,
              hoverBackgroundColor: colors.white,
              hoverBorderWidth: 2,
              data: Object.values(data.cumulativeDiabetesRegistrations),
              type: "line",
            },
            {
              yAxisID: "yMonthlyDiabetesFollowups",
              label: "monthly diabetes followups",
              backgroundColor: colors.transparent,
              borderColor: colors.darkTeal,
              borderWidth: 2,
              pointBackgroundColor: colors.white,
              hoverBackgroundColor: colors.white,
              hoverBorderWidth: 2,
              data: Object.values(data.monthlyDiabetesFollowups),
              type: "line",
            },
            {
              yAxisID: "yMonthlyDiabetesRegistrations",
              label: "monthly diabetes registrations",
              backgroundColor: colors.lightPurple,
              hoverBackgroundColor: colors.darkPurple,
              data: Object.values(data.monthlyDiabetesRegistrations),
              type: "bar",
            },
          ],
        },
      };

      // will dry this post upgrade
      const config = withBaseLineConfig(
        additionalCumulativeDiabetesRegistrationsTrendConfig
      );
    
      config.options.scales = {
        x: {
          stacked: true,
          display: true,
          grid: {
            display: false,
            drawBorder: false,
          },
          ticks: {
            autoSkip: false,
            color: colors.darkGrey,
            font: {
              size: 12,
              family: "Roboto",
            },
            padding: 8,
          },
          beginAtZero: true,
          min: 0,
        },

        // temporary fix for hiding y axis
        y: {
          display: false,
        },

        yCumulativeDiabetesRegistrations: {
          // id: "cumulativeDiabetesRegistrations",
          position: "left",
          stacked: true,
          display: true,
          grid: {
            display: false,
            drawBorder: false,
          },
          ticks: {
            display: false,
            autoSkip: false,
            color: colors.darkGrey,
            font: {
              size: 10,
              family: "Roboto",
            },
            padding: 8,
            stepSize: cumulativeDiabetesRegistrationsYAxis.stepSize,
            callback: formatNumberWithCommas
          },
          beginAtZero: true,
          min: 0,
          max: cumulativeDiabetesRegistrationsYAxis.max,
        },

        yMonthlyDiabetesRegistrations: {
          position: "right",
          stacked: true,
          display: true,
          grid: {
            display: true,
            drawBorder: false,
          },
          ticks: {
            display: false,
            autoSkip: false,
            color: colors.darkGrey,
            font: {
              size: 10,
              family: "Roboto",
            },
            padding: 8,
            stepSize: monthlyDiabetesRegistrationsYAxis.stepSize,
            callback: formatNumberWithCommas
          },
          beginAtZero: true,
          min: 0,
          max: monthlyDiabetesRegistrationsYAxis.max,
        },

        yMonthlyDiabetesFollowups: {
          position: "right",
          stacked: true,
          display: true,
          grid: {
            display: false,
            drawBorder: false,
          },
          ticks: {
            display: false,
            autoSkip: false,
            color: colors.darkGrey,
            font: {
              size: 10,
              family: "Roboto",
            },
            padding: 8,
            stepSize: cumulativeDiabetesRegistrationsYAxis.stepSize,
            callback: formatNumberWithCommas
          },
          beginAtZero: true,
          min: 0,
          max: cumulativeDiabetesRegistrationsYAxis.max,
        },

      }
      
      return config;
    },

    bsOver200PatientsTrend: function (data) {
      const additionalbsOver200PatientsTrendconfig = {
        type: "bar",
        data: {
          labels: Object.keys(data.bsOver300Rate),
          datasets: [
            {
              label: "Blood sugar 200-299",
              backgroundColor: colors.amber,
              hoverBackgroundColor: colors.darkAmber,
              data: Object.values(data.bs200to300Rate),
            },
            {
              label: "Blood sugar ≥300",
              backgroundColor: colors.mediumRed,
              hoverBackgroundColor: colors.darkRed,
              data: Object.values(data.bsOver300Rate),
            },
          ],
        },
      };

      // will dry this post upgrade
      const config = withBaseLineConfig(
        additionalbsOver200PatientsTrendconfig
      );

      config.options.scales = {
        x: {
          stacked: true,
          display: true,
          grid: {
            display: false,
            drawBorder: true,
          },
          ticks: {
            autoSkip: false,
            color: colors.darkGrey,
            font: {
              size: 12,
              family: "Roboto",
            },
            padding: 8,
          },
          beginAtZero: true,
          min: 0,
        },
        y: {
          stacked: true,
          display: true,
          grid: {
            display: true,
            drawBorder: false,
          },
          ticks: {
            autoSkip: false,
            color: colors.darkGrey,
            font: {
              size: 10,
              family: "Roboto",
            },
            padding: 8,
            stepSize: 25,
          },
          beginAtZero: true,
          min: 0,
          max: 100,
        },
      }

      return config;
    },

    diabetesMissedVisitsTrend: function (data) {
      const config = {
        data: {
          labels: Object.keys(data.diabetesMissedVisitsGraphRate),
          datasets: [
            {
              label: "Missed visits",
              backgroundColor: colors.lightBlue,
              borderColor: colors.mediumBlue,
              borderWidth: 2,
              pointBackgroundColor: colors.white,
              hoverBackgroundColor: colors.white,
              hoverBorderWidth: 2,
              data: Object.values(data.diabetesMissedVisitsGraphRate),
              type: "line",
            },
          ],
        },
      };
      return withBaseLineConfig(config);
    },
  
    diabetesVisitDetails: function(data) {
      const maxBarsToDisplay = 6;
      const barsToDisplay = Math.min(
          Object.keys(data.bsBelow200Rate).length,
          maxBarsToDisplay
      );
      const config = {
        data: {
          labels: Object.keys(data.bsBelow200Rate).slice(-barsToDisplay),
          datasets: [
            {
              label: "Blood sugar <200",
              backgroundColor: colors.mediumGreen,
              hoverBackgroundColor: colors.darkGreen,
              data: Object.values(data.bsBelow200Rate).slice(-barsToDisplay),
              type: "bar",
            },
            {
              label: "Blood sugar 200-299",
              backgroundColor: colors.amber,
              hoverBackgroundColor: colors.darkAmber,
              data: Object.values(data.bs200to300Rate).slice(-barsToDisplay),
              type: "bar",
            },
            {
              label: "Blood sugar ≥300",
              backgroundColor: colors.mediumRed,
              hoverBackgroundColor: colors.darkRed,
              data: Object.values(data.bsOver300Rate).slice(-barsToDisplay),
              type: "bar",
            },
            {
              label: "Visit but no blood sugar measure",
              backgroundColor: colors.mediumGrey,
              hoverBackgroundColor: colors.darkGrey,
              data: Object.values(data.visitButNoBSMeasureRate).slice(
                  -barsToDisplay
              ),
              type: "bar",
            },
            {
              label: "Missed visits",
              backgroundColor: colors.mediumBlue,
              hoverBackgroundColor: colors.darkBlue,
              data: Object.values(data.diabetesMissedVisitsRate).slice(
                  -barsToDisplay
              ),
              type: "bar",
            },
          ],
        }
      }

      return withBaseBarConfig(config);
    },
    MedicationsDispensation: function(data) {
      const graphPeriods = Object.keys(Object.values(data)[0]["counts"])

      let datasets = Object.keys(data).map(function (bucket, index) {
        return {
          label: bucket,
          data: Object.values(data[bucket]["percentages"]),
          numerators: data[bucket]["counts"],
          denominators: data[bucket]["totals"],
          borderColor: data[bucket]["color"],
          backgroundColor: data[bucket]["color"],
        };
      });
      const config = {
        data: {
          labels: graphPeriods,
          datasets: datasets,
        },
        options: {
          interaction: {
            mode: "x",
          },
          minBarLength: 4,
          plugins: {
            datalabels: {
              align: "end",
              color: "black",
              anchor: "end",
              offset: 1,
              font: {
                family: "Roboto Condensed",
                size: 12,
              },
              formatter: function (value) {
                return value + "%";
              },
            },
            tooltip: {
              mode: "x", // not required
              intersect: false, // not required
              enabled: true, // not required?

              displayColors: false,
              xAlign: "center",
              yAlign: "top",
              xPadding: 6,
              yPadding: 6,
              caretSize: 3,
              caretPadding: 1,
              callbacks: {
                title: function (context) {
                  return "";
                },
                // label: function (tooltipItem, data) {
                //   let numerators = Object.values(
                //       data.datasets[tooltipItem.datasetIndex].numerators
                //   );
                //   let denominators = Object.values(
                //       data.datasets[tooltipItem.datasetIndex].denominators
                //   );
                //   return (
                //       formatNumberWithCommas(numerators[tooltipItem.index]) +
                //       " of " +
                //       formatNumberWithCommas(denominators[tooltipItem.index]) +
                //       " follow-up patients"
                //   );
                // },
                label: function (context) {
                  // console.log(context);
                  // console.log(context.dataIndex);
                  // console.log(context.dataset);
                  // console.log(
                  //   context.dataset.numerators[context.label],
                  //   context.dataset.denominators[context.label]
                  // );
                  let numerator = context.dataset.numerators[context.label];
                  let denominator = context.dataset.denominators[context.label];
                  return `${formatNumberWithCommas(
                    numerator
                  )} of ${formatNumberWithCommas(
                    denominator
                  )} follow-up patients`;
                },
              },
            }
          },
        },
        plugins: [ChartDataLabels],
      }

      const medicationsDispensationConfig = withBaseBarConfig(config)

      // will dry after update
      medicationsDispensationConfig.options.scales = {
        x: {
          stacked: false,
          display: true,
          grid: {
            display: false,
            drawBorder: true,
          },
          ticks: {
            autoSkip: false,
            color: colors.darkGrey,
            font: {
              size: 12,
              family: "Roboto Condensed",
            },
            padding: 0,
          },
          beginAtZero: true,
          min: 0,
        },

        y: {
          stacked: false,
          display: true,
          grid: {
            display: true,
            drawBorder: false,
          },
          ticks: {
            display: false,
            autoSkip: false,
            color: colors.darkGrey,
            font: {
              size: 12,
              family: "Roboto Condensed",
            },
            padding: 8,
            stepSize: 25,
          },
          beginAtZero: true,
          min: 0,
          max: 100,
        },

      };

      return medicationsDispensationConfig;
    },
    
    lostToFollowUpTrend: function (data) {
      const config = {
        data: {
          labels: Object.keys(data.ltfuPatientsRate),
          datasets: [
            {
              label: "Lost to follow-up",
              backgroundColor: colors.lightBlue,
              borderColor: colors.darkBlue,
              borderWidth: 2,
              pointBackgroundColor: colors.white,
              hoverBackgroundColor: colors.white,
              hoverBorderWidth: 2,
              data: Object.values(data.ltfuPatientsRate),
              type: "line",
            },
          ],
        },
      };
      return withBaseLineConfig(config);
    },
  
  };

  return {
      ReportsTable: (id) => {
        const tableSortAscending = { descending: false };
        const table = document.getElementById(id);

        if (table) {
            new Tablesort(table, tableSortAscending);
        }
      },
      ReportsGraph: (id, data) => {
        const container = document.querySelector(`#${id}`);
        const graphCanvas = container.querySelector('canvas')
        const defaultPeriod = container.getAttribute("data-period");
        const dataKeyNodes = container.querySelectorAll("[data-key]");

        const populateDynamicComponents = (period) => {
            dataKeyNodes.forEach(dataNode => {
                const format = dataNode.dataset.format;
                const key = dataNode.dataset.key;

                if(!data[key]) {
                    throw `${key}: Key not present in data.`
                }

                dataNode.innerHTML = formatValue(format, data[key][period]);
            })
        };

        if(!ReportsGraphConfig[id]) {
            throw `Config for ${id} is not defined`;
        }

        const graphConfig = ReportsGraphConfig[id](data);
        if(!graphConfig) {
            throw `Graph config not known for ${id}`
        }

        if (!graphConfig.options.plugins.tooltip) {
          graphConfig.options.plugins.tooltip = {
            enabled: false,
            mode: "index",
            intersect: false,
            external: (context) => {
              const isTooltipActive = context.tooltip._active.length > 0;
              if (isTooltipActive) {
                let hoveredDatapoint = context.tooltip.dataPoints;
                populateDynamicComponents(hoveredDatapoint[0].label);
              }
              else populateDynamicComponents(defaultPeriod);
            },
          };
        }

        if(graphCanvas) {
            // Assumes ChartJS is already imported
            new Chart(graphCanvas.getContext("2d"), graphConfig);
            populateDynamicComponents(defaultPeriod);
        }
      }
  }
}

Reports = function (withLtfu) {
  const colors = dashboardReportsChartJSColors();

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
  };

  this.setupControlledGraph = (data) => {
    const adjustedPatients = withLtfu
      ? data.adjustedPatientCountsWithLtfu
      : data.adjustedPatientCounts;
    const controlledGraphNumerator = data.controlledPatients;
    const controlledGraphRate = withLtfu
      ? data.controlWithLtfuRate
      : data.controlRate;

    const config = {
      data: {
        labels: Object.keys(controlledGraphRate),
        datasets: [
          {
            label: "BP controlled",
            backgroundColor: colors.lightGreen,
            borderColor: colors.mediumGreen,
            borderWidth: 2,
            pointBackgroundColor: colors.white,
            hoverBackgroundColor: colors.white,
            hoverBorderWidth: 2,
            data: Object.values(controlledGraphRate),
          },
        ],
      },
      options: {
        plugins: {
          tooltip: {
            enabled: false,
            mode: "index",
            intersect: false,
            // custom: (tooltip) => {
            //   let hoveredDatapoint = tooltip.dataPoints;
            //   if (hoveredDatapoint)
            //     populateControlledGraph(hoveredDatapoint[0].label);
            //   else populateControlledGraphDefault();
            // },
            external: (context, defaultPeriod) => {
              const isTooltipActive = context.tooltip._active.length > 0;
              if (isTooltipActive) {
                let hoveredDatapoint = context.tooltip.dataPoints;
                populateControlledGraph(hoveredDatapoint[0].label);
              }
              else populateControlledGraphDefault(defaultPeriod);
            },
          },
        },
      }
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
      new Chart(
        controlledGraphCanvas.getContext("2d"),
        withBaseLineConfig(config)
      );
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

    const config = {
      data: {
        labels: Object.keys(uncontrolledGraphRate),
        datasets: [
          {
            label: "BP uncontrolled",
            backgroundColor: colors.lightRed,
            borderColor: colors.mediumRed,
            borderWidth: 2,
            pointBackgroundColor: colors.white,
            hoverBackgroundColor: colors.white,
            hoverBorderWidth: 2,
            data: Object.values(uncontrolledGraphRate),
          },
        ],
      },
      options: {
        plugins: {
          tooltip: {
            enabled: false,
            mode: "index",
            intersect: false,
            // custom: (tooltip) => {
            //   let hoveredDatapoint = tooltip.dataPoints;
            //   if (hoveredDatapoint)
            //     populateUncontrolledGraph(hoveredDatapoint[0].label);
            //   else populateUncontrolledGraphDefault();
            // },
            external: (context, defaultPeriod) => {
              const isTooltipActive = context.tooltip._active.length > 0;
              if (isTooltipActive) {
                let hoveredDatapoint = context.tooltip.dataPoints;
                populateUncontrolledGraph(hoveredDatapoint[0].label);
              }
              else populateUncontrolledGraphDefault(defaultPeriod);
            },
          },
        },
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
        withBaseLineConfig(config)
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

    const config = {
      data: {
        labels: Object.keys(missedVisitsGraphRate),
        datasets: [
          {
            label: "Missed visits",
            backgroundColor: colors.lightBlue,
            borderColor: colors.mediumBlue,
            borderWidth: 2,
            pointBackgroundColor: colors.white,
            hoverBackgroundColor: colors.white,
            hoverBorderWidth: 2,
            data: Object.values(missedVisitsGraphRate),
          },
        ],
      },
      options: {
        plugins: {
          tooltip: {
            enabled: false,
            mode: "index",
            intersect: false,
            external: (context, defaultPeriod) => {
              const isTooltipActive = context.tooltip._active.length > 0;
              if (isTooltipActive) {
                let hoveredDatapoint = context.tooltip.dataPoints;
                populateMissedVisitsGraph(hoveredDatapoint[0].label);
              }
              else populateMissedVisitsGraphDefault(defaultPeriod);
            },
            // custom: (tooltip) => {
            //   let hoveredDatapoint = tooltip.dataPoints;
            //   if (hoveredDatapoint)
            //     populateMissedVisitsGraph(hoveredDatapoint[0].label);
            //   else populateMissedVisitsGraphDefault();
            // },
          },
        }
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
      new Chart(
        missedVisitsGraphCanvas.getContext("2d"), 
        withBaseLineConfig(config)
      );
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

    const config = {
      type: "bar",
      data: {
        labels: Object.keys(data.cumulativeRegistrations),
        datasets: [
          {
            yAxisID: "yCumulativeRegistrations",
            label: "cumulative registrations",
            backgroundColor: colors.transparent,
            borderColor: colors.darkPurple,
            borderWidth: 2,
            pointBackgroundColor: colors.white,
            hoverBackgroundColor: colors.white,
            hoverBorderWidth: 2,
            data: Object.values(data.cumulativeRegistrations),
            type: "line",
          },
          {
            yAxisID: "yMonthlyRegistrations",
            label: "monthly registrations",
            backgroundColor: colors.lightPurple,
            hoverBackgroundColor: colors.darkPurple,
            data: Object.values(data.monthlyRegistrations),
            type: "bar",
          },
        ],
      },
      options: {
        plugins: {
          tooltip: {
            enabled: false,
            mode: "index",
            intersect: false,
            // custom: (tooltip) => {
            //   let hoveredDatapoint = tooltip.dataPoints;
            //   if (hoveredDatapoint)
            //     populateCumulativeRegistrationsGraph(hoveredDatapoint[0].label);
            //   else populateCumulativeRegistrationsGraphDefault();
            // },
            external: (context, defaultPeriod) => {
              const isTooltipActive = context.tooltip._active.length > 0;
              if (isTooltipActive) {
                let hoveredDatapoint = context.tooltip.dataPoints;
                populateCumulativeRegistrationsGraph(hoveredDatapoint[0].label);
              }
              else populateCumulativeRegistrationsGraphDefault(defaultPeriod);
            },
          },
        },
      }
    };

    // Will comeback and dry this after upgrade
    const cumulativeRegistrationsGraphConfig = withBaseLineConfig(
      config
    );

    cumulativeRegistrationsGraphConfig.options.scales.y = {
      display: false,
    }

    cumulativeRegistrationsGraphConfig.options.scales.yCumulativeRegistrations = {
      position: "left",
      stacked: true,
      display: true,
      grid: {
        display: false,
        drawBorder: false,
      },
      ticks: {
        display: false,
        autoSkip: false,
        color: colors.darkGrey,
        font: {
          size: 10,
          family: "Roboto",
        },
        padding: 8,
        stepSize: cumulativeRegistrationsYAxis.stepSize, // not used?
        callback: (label) => {
          return this.formatNumberWithCommas(label);
        },
      },
      beginAtZero: true,
      min: 0,
      max: cumulativeRegistrationsYAxis.max,
    }
    cumulativeRegistrationsGraphConfig.options.scales.yMonthlyRegistrations = {
      position: "right",
      stacked: true,
      display: true,
      grid: {
        display: true,
        drawBorder: false,
        drawTicks: false,
      },
      ticks: {
        display: false,
        autoSkip: false,
        color: colors.darkGrey,
        font: {
          size: 10,
          family: "Roboto",
        },
        padding: 8,
        stepSize: monthlyRegistrationsYAxis.stepSize,
        callback: (label) => {
          return this.formatNumberWithCommas(label); // no numbers shown?
        },
      },
      beginAtZero: true,
      min: 0,
      max: monthlyRegistrationsYAxis.max,
    }

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

      const hypertensionOnlyRegistrationsNode = cardNode.querySelector(
          "[data-hypertension-only-registrations]"
      );

      const hypertensionAndDiabetesOnlyRegistrationsNode = cardNode.querySelector(
          "[data-hypertension-and-diabetes-registrations]"
      );

      const periodInfo = data.periodInfo[period];
      const cumulativeRegistrations = data.cumulativeRegistrations[period];
      const cumulativeHypertensionAndDiabetesRegistrations = data.cumulativeHypertensionAndDiabetesRegistrations[period];
      const monthlyRegistrations = data.monthlyRegistrations[period];

      monthlyRegistrationsNode.innerHTML =
        this.formatNumberWithCommas(monthlyRegistrations);
      totalPatientsNode.innerHTML = this.formatNumberWithCommas(
        cumulativeRegistrations
      );
      registrationsPeriodEndNode.innerHTML = periodInfo.bp_control_end_date;
      registrationsMonthEndNode.innerHTML = period;

      if(hypertensionOnlyRegistrationsNode) {
        hypertensionOnlyRegistrationsNode.innerHTML = this.formatNumberWithCommas(
            cumulativeRegistrations - cumulativeHypertensionAndDiabetesRegistrations
        );
      }

      if(hypertensionAndDiabetesOnlyRegistrationsNode) {
        hypertensionAndDiabetesOnlyRegistrationsNode.innerHTML = this.formatNumberWithCommas(
            cumulativeHypertensionAndDiabetesRegistrations
        );
      }
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
    const maxBarsToDisplay = 6;
    const barsToDisplay = Math.min(
      Object.keys(data.controlRate).length,
      maxBarsToDisplay
    );
    const config = {
      data: {
        labels: Object.keys(data.controlRate).slice(-barsToDisplay),
        datasets: [
          {
            label: "BP controlled",
            backgroundColor: colors.mediumGreen,
            hoverBackgroundColor: colors.darkGreen,
            data: Object.values(data.controlRate).slice(-barsToDisplay),
            type: "bar",
          },
          {
            label: "BP uncontrolled",
            backgroundColor: colors.mediumRed,
            hoverBackgroundColor: colors.darkRed,
            data: Object.values(data.uncontrolledRate).slice(-barsToDisplay),
            type: "bar",
          },
          {
            label: "Visit but no BP measure",
            backgroundColor: colors.mediumGrey,
            hoverBackgroundColor: colors.darkGrey,
            data: Object.values(data.visitButNoBPMeasureRate).slice(
              -barsToDisplay
            ),
            type: "bar",
          },
          {
            label: "Missed visits",
            backgroundColor: colors.mediumBlue,
            hoverBackgroundColor: colors.darkBlue,
            data: Object.values(data.missedVisitsRate).slice(-barsToDisplay),
            type: "bar",
          },
        ],
      },
      options: {
        plugins: {
          tooltip: {
            enabled: false,
            mode: "index",
            intersect: false,
            external: (context, defaultPeriod) => {
              const isTooltipActive = context.tooltip._active.length > 0;
              if (isTooltipActive) {
                let hoveredDatapoint = context.tooltip.dataPoints;
                populateVisitDetailsGraph(hoveredDatapoint[0].label);
              }
              else populateVisitDetailsGraphDefault(defaultPeriod);
            },
            // custom: (tooltip) => {
            //   let hoveredDatapoint = tooltip.dataPoints;
            //   if (hoveredDatapoint)
            //     populateVisitDetailsGraph(hoveredDatapoint[0].label);
            //   else populateVisitDetailsGraphDefault();
            // },
          }
        },
      }
    }

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
        withBaseBarConfig(config)
      );
      populateVisitDetailsGraphDefault();
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
      cumulativeDiabetesRegistrations: jsonData.cumulative_diabetes_registrations,
      cumulativeHypertensionAndDiabetesRegistrations: jsonData.cumulative_hypertension_and_diabetes_registrations,
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
      bsOver200BreakdownRates: jsonData.bs_over_200_breakdown_rates,
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

function baseLineGraphConfig() {
  const colors = dashboardReportsChartJSColors()
  return {
    type: "line",
    options: {
      animation: false,
      clip: false,
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
        line: {
          tension: 0.4,
          fill: true,
        }
      },
      interaction: {
        mode: "index",
        intersect: false,
      },
      plugins: {
        legend: {
          display: false,
        },
      },
      scales: {
        x: {
          stacked: false,
          display: true,
          grid: {
            display: false,
            drawBorder: true,
          },
          ticks: {
            autoSkip: false,
            color: colors.darkGrey,
            font: {
              size: 12, // default is 12
              family: "Roboto",
            },
            padding: 6,
          },
          beginAtZero: true,
          min: 0,
        },
        y: {
          stacked: false,
          display: true,
          grid: {
            display: true,
            drawBorder: false,
          },
          ticks: {
            autoSkip: false,
            color: colors.darkGrey,
            font: {
              size: 10,
              family: "Roboto",
            },
            padding: 8,
            stepSize: 25, // unitStepSize??
          },
          beginAtZero: true,
          min: 0,
          max: 100,
        },
      },
    },
    plugins: [intersectDataVerticalLine],
  };
}

function baseBarChartConfig() {
  const colors = dashboardReportsChartJSColors()
  return {
    type: "bar",
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
      plugins: {
        legend: {
          display: false,
        },
      },
      interaction: {
        mode: "index",
        intersect: false,
      },
      scales: {
        x: {
          stacked: true,
          display: true,
          grid: {
            display: false,
            drawBorder: false,
          },
          ticks: {
            autoSkip: false,
            color: colors.darkGrey,
            font: {
              size: 12,
              family: "Roboto",
            },
            padding: 6,
          },
          min: 0,
          beginAtZero: true,
        },
        y: {
          stacked: true,
          display: false,
          grid: {
            display: false,
            drawBorder: false,
          },
          ticks: {
            autoSkip: false,
            color: colors.darkGrey,
            font: {
              size: 10,
              family: "Roboto",
            },
            padding: 8,
          },
          min: 0,
          beginAtZero: true,
        },
      }
    },
    plugins: [intersectDataVerticalLine],
  }
}

// [plugin] vertical instersect line
const intersectDataVerticalLine = {
  id: "intersectDataVerticalLine",
  beforeDraw: (chart) => {
    if (chart.tooltip._active && chart.tooltip._active.length) {
      const ctx = chart.ctx;
      ctx.save();
      const activePoint = chart.tooltip._active[0];
      const chartArea = chart.chartArea;
      // grey vertical hover line - full chart height
      ctx.beginPath();
      ctx.moveTo(activePoint.element.x, chartArea.top);
      ctx.lineTo(activePoint.element.x, chartArea.bottom);
      ctx.lineWidth = 2;
      ctx.strokeStyle = "rgba(0,0,0, 0.1)";
      ctx.stroke();
      ctx.restore();
      // colored vertical hover line - ['node' point to chart bottom] - only for line graphs (graphs with 1 data point)
      if (chart.tooltip._active.length === 1) {
        ctx.beginPath();
        ctx.moveTo(activePoint.element.x, activePoint.element.y);
        ctx.lineTo(activePoint.element.x, chartArea.bottom);
        ctx.lineWidth = 2;
        ctx.stroke();
        ctx.restore();
      }
    }
  },
};

function withBaseLineConfig(config) {
  return _.mergeWith(
    baseLineGraphConfig(),
    config,
    mergeArraysWithConcatenation
  );
}

function withBaseBarConfig(config) {
  return _.mergeWith(
    baseBarChartConfig(),
    config,
    mergeArraysWithConcatenation
  );
}


function mergeArraysWithConcatenation(objValue, srcValue) {
  if (_.isArray(objValue)) {
    return objValue.concat(srcValue);
  }
}

// update font on load issue
// document.fonts.onloadingdone = () => {
// 	Chart.update();
// };