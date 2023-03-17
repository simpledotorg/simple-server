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
        return formatPercentage(value);
      case "numberWithCommas":
        return formatNumberWithCommas(value);
      default:
        throw `Unknown format ${format}`;
    }
  };

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
              data: Object.values(data.bsBelow200Rate),
            },
          ],
        },
      };
      return withBaseLineConfig(config);
    },

    cumulativeDiabetesRegistrationsTrend: function (data) {
      const cumulativeDiabetesRegistrationsYAxis = createAxisMaxAndStepSize(
        data.cumulativeDiabetesRegistrations
      );
      const monthlyDiabetesRegistrationsYAxis = createAxisMaxAndStepSize(
        data.monthlyDiabetesRegistrations
      );
      const config = {
        data: {
          labels: Object.keys(data.cumulativeDiabetesRegistrations),
          datasets: [
            {
              type: "line",
              data: Object.values(data.cumulativeDiabetesRegistrations),
              label: "cumulative diabetes registrations",
              yAxisID: "y",
              backgroundColor: colors.transparent,
              borderColor: colors.darkPurple,
            },
            {
              type: "line",
              data: Object.values(data.monthlyDiabetesFollowups),
              label: "monthly diabetes followups",
              yAxisID: "y",
              backgroundColor: colors.transparent,
              borderColor: colors.darkTeal,
            },
            {
              type: "bar",
              data: Object.values(data.monthlyDiabetesRegistrations),
              label: "monthly diabetes registrations",
              yAxisID: "yMonthlyDiabetesRegistrations",
              backgroundColor: colors.lightPurple,
              hoverBackgroundColor: colors.darkPurple,
            },
          ],
        },
        options: {
          scales: {
            y: {
              grid: {
                drawTicks: false,
              },
              ticks: {
                display: false,
                stepSize: cumulativeDiabetesRegistrationsYAxis.stepSize,
              },
              max: cumulativeDiabetesRegistrationsYAxis.max,
            },

            yMonthlyDiabetesRegistrations: {
              display: false,
              beginAtZero: true,
              min: 0,
              max: monthlyDiabetesRegistrationsYAxis.max,
            },
          },
        },
      };
      return withBaseLineConfig(config);
    },

    bsOver200PatientsTrend: function (data) {
      const config = {
        type: "bar",
        data: {
          labels: Object.keys(data.bsOver300Rate),
          datasets: [
            {
              label: "Blood sugar 200-299",
              data: Object.values(data.bs200to300Rate),
              backgroundColor: colors.amber,
              hoverBackgroundColor: colors.darkAmber,
            },
            {
              label: "Blood sugar ≥300",
              data: Object.values(data.bsOver300Rate),
              backgroundColor: colors.mediumRed,
              hoverBackgroundColor: colors.darkRed,
            },
          ],
        },
        options: {
          scales: {
            x: {
              stacked: true,
            },
            y: {
              stacked: true,
            },
          },
        },
      };
      return withBaseLineConfig(config);
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
              data: Object.values(data.diabetesMissedVisitsGraphRate),
            },
          ],
        },
      };
      return withBaseLineConfig(config);
    },

    diabetesVisitDetails: function (data) {
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
              data: Object.values(data.bsBelow200Rate).slice(-barsToDisplay),
              backgroundColor: colors.mediumGreen,
              hoverBackgroundColor: colors.darkGreen,
            },
            {
              label: "Blood sugar 200-299",
              data: Object.values(data.bs200to300Rate).slice(-barsToDisplay),
              backgroundColor: colors.amber,
              hoverBackgroundColor: colors.darkAmber,
            },
            {
              label: "Blood sugar ≥300",
              data: Object.values(data.bsOver300Rate).slice(-barsToDisplay),
              backgroundColor: colors.mediumRed,
              hoverBackgroundColor: colors.darkRed,
            },
            {
              label: "Visit but no blood sugar measure",
              data: Object.values(data.visitButNoBSMeasureRate).slice(
                -barsToDisplay
              ),
              backgroundColor: colors.mediumGrey,
              hoverBackgroundColor: colors.darkGrey,
            },
            {
              label: "Missed visits",
              data: Object.values(data.diabetesMissedVisitsRate).slice(
                -barsToDisplay
              ),
              backgroundColor: colors.mediumBlue,
              hoverBackgroundColor: colors.darkBlue,
            },
          ],
        },
      };
      return withBaseBarConfig(config);
    },

    MedicationsDispensation: function (data) {
      const graphPeriods = Object.keys(Object.values(data)[0]["counts"]);

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
        type: "bar",
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
              anchor: "end",
              align: "end",
              color: "black",
              offset: 1,
              font: {
                family: "Roboto Condensed",
              },
              formatter: function (value) {
                return value + "%";
              },
            },
            tooltip: {
              enabled: true,
              displayColors: false,
              xAlign: "center",
              yAlign: "top",
              caretSize: 4,
              caretPadding: 4,

              callbacks: {
                title: function () {
                  return "";
                },
                label: function (context) {
                  let numerator = context.dataset.numerators[context.label];
                  let denominator = context.dataset.denominators[context.label];
                  return `${formatNumberWithCommas(
                    numerator
                  )} of ${formatNumberWithCommas(
                    denominator
                  )} follow-up patients`;
                },
              },
            },
          },
          scales: {
            y: {
              grid: {
                drawTicks: false,
              },
              ticks: {
                display: false,
              },
            },
          },
        },
        plugins: [ChartDataLabels],
      };
      return withBaseLineConfig(config);
    },

    lostToFollowUpTrend: function (data) {
      const config = {
        data: {
          labels: Object.keys(data.ltfuPatientsRate),
          datasets: [
            {
              label: "Lost to follow-up",
              data: Object.values(data.ltfuPatientsRate),
              backgroundColor: colors.lightBlue,
              borderColor: colors.darkBlue,
            },
          ],
        },
      };
      return withBaseLineConfig(config);
    },

    overduePatients: function (data) {
      const overdueDataLabels = [
        "Apr-2022",
        "May-2022",
        "Jun-2022",
        "Jul-2022",
        "Aug-2022",
        "Sep-2022",
        "Oct-2022",
        "Nov-2022",
        "Dec-2022",
        "Jan-2023",
        "Feb-2023",
        "Mar-2023",
      ];
      const patients_under_care = [
        253, 275, 309, 361, 406, 450, 500, 528, 579, 613, 667, 669,
      ];

      const overdue_patients = [
        29, 123, 113, 174, 142, 141, 130, 97, 194, 226, 180, 127,
      ];
      const overdue_patients_percent = percentArray(
        overdue_patients,
        patients_under_care
      );

      console.log(overdue_patients_percent);

      console.log(Object.keys(data.ltfuPatientsRate));
      console.log(Object.values(data.ltfuPatientsRate));
      const config = {
        data: {
          labels: overdueDataLabels,
          // labels: Object.keys(data.ltfuPatientsRate),
          datasets: [
            {
              label: "Lost to follow-up",
              data: overdue_patients_percent,
              backgroundColor: "rgba(255, 165, 0, 0.15)",
              borderColor: "chocolate",
            },
          ],
        },
      };
      return withBaseLineConfig(config);
    },

    overduePatientsCalled: function (data) {
      console.log("data called", data);
      // const agreedToReturn = [
      //   26, 27, 25, 29, 31, 38, 46, 43, 42, 45, 56, 56, 42, 47, 59, 64, 68, 24,
      // ];
      // const remindToCall = [
      //   10, 15, 25, 29, 31, 38, 25, 25, 20, 17, 13, 10, 12, 12, 14, 15, 20, 10,
      // ];
      // const removedFromOverdue = [
      //   4, 4, 5, 6, 3, 3, 1, 1, 4, 6, 10, 12, 34, 12, 8, 2, 1, 5,
      // ];
      // const overduePatientsData2 = overduePatientsData.map((number) => number - randomNumber(0, number))
      const overdueDataLabels = [
        "Apr-2022",
        "May-2022",
        "Jun-2022",
        "Jul-2022",
        "Aug-2022",
        "Sep-2022",
        "Oct-2022",
        "Nov-2022",
        "Dec-2022",
        "Jan-2023",
        "Feb-2023",
        "Mar-2023",
      ];

      const overdue_patients = [
        29, 123, 113, 174, 142, 141, 130, 97, 194, 226, 180, 127,
      ];
      const patients_called = [0, 7, 2, 34, 21, 36, 34, 13, 13, 140, 77, 30];

      const patients_called_agreed_to_visit = [
        0, 3, 2, 16, 6, 15, 17, 5, 8, 70, 34, 8,
      ];
      const patients_called_remind_to_call = [
        0, 0, 0, 0, 0, 1, 0, 1, 2, 0, 0, 0,
      ];
      const patients_called_removed_from_overdue_list = [
        0, 4, 0, 18, 15, 20, 17, 7, 3, 70, 43, 22,
      ];

      const overdue_patients_called_percent = percentArray(
        patients_called,
        overdue_patients
      );
      const overdue_patients_called_agree = percentArray(
        patients_called_agreed_to_visit,
        overdue_patients
      );
      const overdue_patients_called_remid = percentArray(
        patients_called_remind_to_call,
        overdue_patients
      );
      const overdue_patients_called_removed = percentArray(
        patients_called_removed_from_overdue_list,
        overdue_patients
      );
      // red yellow green
      colorAgree = "78, 206, 0";
      colorRemind = "255, 201, 63";
      colorRemoved = "232, 144, 80";
      colorCalledChart = "228, 180, 57";

      // colorAgree = "245, 220, 0";
      // colorRemind = "255, 201, 63";
      // colorRemoved = "232, 144, 80";
      // colorRemoved = "255, 149, 26";
      console.log("data:", data.ltfuPatientsRate);
      console.log(Object.keys(data.ltfuPatientsRate));
      console.log(Object.values(data.ltfuPatientsRate));
      const config = {
        data: {
          labels: overdueDataLabels,
          datasets: [
            {
              // type: "bar",
              label: "agreed to return",
              data: overdue_patients_called_agree,
              // backgroundColor: 'rgba(134, 193, 98, 0.20)',
              // borderColor: '#86C162',
              // backgroundColor: `rgba(${colorAgree}, 0.10)`,
              backgroundColor: `rgba(${colorAgree}, 0.10)`,
              borderColor: `rgba(${colorAgree}, 0.25)`,
              borderWidth: 0,
              radius: 0,
              // yAxisID: "y1",

              segment: {
                borderDash: (ctx) =>
                  dynamicChartSegementDashed(ctx, overdueDataLabels.length),
              },
            },
            {
              // type: "bar",
              label: "remind to call",
              data: overdue_patients_called_remid,
              backgroundColor: `rgba(${colorRemind}, 0.10)`,
              borderColor: `rgba(${colorRemind}, .45)`,
              borderWidth: 0,
              radius: 0,
              // yAxisID: "y1",

              segment: {
                borderDash: (ctx) =>
                  dynamicChartSegementDashed(ctx, overdueDataLabels.length),
              },
            },
            {
              // type: "bar",
              label: "removed from overdue list",
              data: overdue_patients_called_removed,
              backgroundColor: `rgba(${colorRemoved}, 0.10)`,
              // borderColor: `rgba(${colorRemoved}, 1)`,
              borderColor: `rgba(${colorCalledChart}, 1)`,
              // borderWidth: 0,
              // yAxisID: "y1",
              segment: {
                borderDash: (ctx) =>
                  dynamicChartSegementDashed(ctx, overdueDataLabels.length),
              },
            },
            // {
            //   type: "line",
            //   label: "all called",
            //   data: overdue_patients_called_percent,
            //   backgroundColor: `rgba(${colorRemoved}, 0.10)`,
            //   // borderColor: `rgba(${colorRemoved}, 1)`,
            //   borderColor: `rgba(${colorCalledChart}, 1)`,
            //   // borderWidth: 0,
            //   fill: false,
            //   segment: {
            //     borderDash: (ctx) =>
            //       dynamicChartSegementDashed(ctx, overdueDataLabels.length),
            //   },
            // },
          ],
        },
        options: {
          scales: {
            y: {
              stacked: true,
              //     min: 0,
              //     max: 100,
              //     display: false,
            },
            //   x: {
            //     stacked: true,
            //   },
          },
        },
      };
      return withBaseLineConfig(config);
    },

    //   returnedToCare: function (data) {
    //     const overdueDataLabels = [
    //       "Apr-2022",
    //       "May-2022",
    //       "Jun-2022",
    //       "Jul-2022",
    //       "Aug-2022",
    //       "Sep-2022",
    //       "Oct-2022",
    //       "Nov-2022",
    //       "Dec-2022",
    //       "Jan-2023",
    //       "Feb-2023",
    //       "Mar-2023",
    //     ];
    //     const patients_called = [1, 7, 2, 34, 21, 36, 34, 13, 13, 140, 77, 30];
    //     const patients_called_agreed_to_visit = [
    //       0, 3, 2, 16, 6, 15, 17, 5, 8, 70, 34, 8,
    //     ];
    //     const returned_to_care = [0, 1, 0, 6, 5, 15, 12, 5, 4, 38, 66, 6];
    //     const returned_to_care_agreed = [, 0, 0, 4, 2, 8, 10, 3, 4, 26, 23, 2];
    //     const returned_to_care_remind = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    //     const returned_to_care_removed = [0, 1, 0, 2, 3, 7, 2, 2, 0, 10, 13, 4];

    //     const allReturnToCare = percentArray(returned_to_care, patients_called);
    //     const AgreeToVisit = percentArray(
    //       patients_called_agreed_to_visit,
    //       patients_called
    //     );
    //     const AgreeToVisitANDReturnTOCare = percentArray(
    //       returned_to_care_agreed,
    //       patients_called
    //     );
    //     // const AgreeToVisit = [
    //     //   26, 27, 25, 29, 31, 38, 46, 43, 42, 45, 56, 56, 42, 47, 59, 64, 68, 72,
    //     // ];

    //     // const AgreeToVisitANDReturnTOCare = [
    //     //   10, 12, 12, 15, 26, 21, 23, 26, 20, 20, 25, 27, 38, 44, 47, 60, 60, 61,
    //     // ];

    //     // const allReturnToCare = [
    //     //   13, 14, 15, 18, 31, 26, 29, 44, 49, 49, 56, 34, 60, 53, 61, 71, 66, 70,
    //     // ];

    //     // console.log(Object.keys(data.ltfuPatientsRate));
    //     // console.log(Object.values(data.ltfuPatientsRate));

    //     const returnToCareColor = "91, 0, 206";

    //     const config = {
    //       data: {
    //         labels: overdueDataLabels,
    //         datasets: [
    //           {
    //             label: "Returned to care",
    //             data: allReturnToCare,
    //             fill: false,
    //             //  backgroundColor: `rgba(${returnToCareColor}, 0.2)`,
    //             borderColor: `rgba(${returnToCareColor}, 1)`,
    //           },
    //           {
    //             label: "Agree to visit",
    //             data: AgreeToVisitANDReturnTOCare,
    //             backgroundColor: "rgba(134, 193, 98, 0.25)",
    //             borderColor: "#86C162",
    //           },
    //           {
    //             label: "Agreed to visit",
    //             data: AgreeToVisit,
    //             backgroundColor: "rgba(78, 206, 0, 0.15)",
    //             borderColor: "rgba(78, 206, 0, 1)",
    //             pointStyle: "line",
    //             pointBackgroundColor: `rgba(${colorAgree}, 1)`,
    //             borderWidth: 0,
    //             radius: 0,
    //             line: 1,
    //           },
    //         ],
    //       },
    //       // options: {
    //       //   scales: {
    //       //     y: {
    //       //       stacked: true,
    //       //     }
    //       //   }
    //       // }
    //     };
    //     return withBaseLineConfig(config);
    //   },
    // };
    returnedToCare: function (data) {
      console.log("PUC", data);
      const overdueDataLabels = [
        "Apr-2022",
        "May-2022",
        "Jun-2022",
        "Jul-2022",
        "Aug-2022",
        "Sep-2022",
        "Oct-2022",
        "Nov-2022",
        "Dec-2022",
        "Jan-2023",
        "Feb-2023",
        "Mar-2023",
      ];
      // const patients_called = [1, 7, 2, 34, 21, 36, 34, 13, 13, 140, 77, 30];
      // const patients_called_agreed_to_visit = [
      //   0, 3, 2, 16, 6, 15, 17, 5, 8, 70, 34, 8,
      // ];
      // const returned_to_care = [0, 1, 0, 6, 5, 15, 12, 5, 4, 38, 66, 6];
      // const returned_to_care_agreed = [, 0, 0, 4, 2, 8, 10, 3, 4, 26, 23, 2];
      // const returned_to_care_remind = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
      // const returned_to_care_removed = [0, 1, 0, 2, 3, 7, 2, 2, 0, 10, 13, 4];
      colorAgree = "78, 206, 0";
      colorRemind = "255, 201, 63";
      colorRemoved = "232, 144, 80";

      const allReturnToCare = percentArray(
        data.returned_to_care,
        data.patients_called
      );

      const AgreeToVisitReturnRate = percentArray(
        data.returned_to_care_agreed,
        data.patients_called_agreed_to_visit
      );
      const RemindToCallReturnRate = percentArray(
        data.returned_to_care_remind,
        data.patients_called_remind_to_call
      );

      const RemovedFromListReturnRate = percentArray(
        data.returned_to_care_removed,
        data.patients_called_removed_from_overdue_list
      );

      const returnToCareColor = "91, 0, 206";

      const config = {
        data: {
          labels: overdueDataLabels,
          datasets: [
            {
              label: "Agree to visit",
              data: AgreeToVisitReturnRate,
              backgroundColor: "rgba(134, 193, 98, 0.25)",
              borderColor: `rgba(${colorAgree},0.8)`,
              fill: false,
              radius: 0,

              segment: {
                borderDash: (ctx) =>
                  dynamicChartSegementDashed(ctx, overdueDataLabels.length),
              },
            },
            {
              label: "Remind to call",
              data: RemindToCallReturnRate,
              backgroundColor: "rgba(134, 193, 98, 0.25)",
              borderColor: `rgba(${colorRemind}, 0.8)`,
              fill: false,
              radius: 0,
              segment: {
                borderDash: (ctx) =>
                  dynamicChartSegementDashed(ctx, overdueDataLabels.length),
              },
            },
            {
              label: "Removed from overdue list",
              data: RemovedFromListReturnRate,
              backgroundColor: "rgba(134, 193, 98, 0.25)",
              borderColor: `rgba(${colorRemoved}, 0.8)`,
              fill: false,
              radius: 0,

              segment: {
                borderDash: (ctx) =>
                  dynamicChartSegementDashed(ctx, overdueDataLabels.length),
              },
            },
            {
              label: "Returned to care",
              data: allReturnToCare,
              fill: true,
              backgroundColor: `rgba(${returnToCareColor}, 0.05)`,
              borderColor: `rgba(${returnToCareColor}, 1)`,
              segment: {
                borderDash: (ctx) =>
                  dynamicChartSegementDashed(ctx, overdueDataLabels.length),
              },
            },
            // {
            //   label: "Agreed to visit",
            //   data: AgreeToVisitANDReturnTOCare,
            //   backgroundColor: "rgba(78, 206, 0, 0.15)",
            //   borderColor: "rgba(78, 206, 0, 1)",
            //   pointStyle: "line",
            //   pointBackgroundColor: `rgba(${colorAgree}, 1)`,
            //   borderWidth: 0,
            //   radius: 0,
            //   line: 1,
            // },
          ],
        },
        options: {
          // plugins: {
          //   tooltip: {
          //     enabled: true,
          //   },
          // },
          // scales: {
          //   y: {
          //     stacked: true,
          //   }
          // }
        },
      };
      return withBaseLineConfig(config);
    },

    returnedToCareAll: function (data) {
      console.log("PUC", data);
      const overdueDataLabels = [
        "Apr-2022",
        "May-2022",
        "Jun-2022",
        "Jul-2022",
        "Aug-2022",
        "Sep-2022",
        "Oct-2022",
        "Nov-2022",
        "Dec-2022",
        "Jan-2023",
        "Feb-2023",
        "Mar-2023",
      ];
      // const patients_called = [1, 7, 2, 34, 21, 36, 34, 13, 13, 140, 77, 30];
      // const patients_called_agreed_to_visit = [
      //   0, 3, 2, 16, 6, 15, 17, 5, 8, 70, 34, 8,
      // ];
      // const returned_to_care = [0, 1, 0, 6, 5, 15, 12, 5, 4, 38, 66, 6];
      // const returned_to_care_agreed = [, 0, 0, 4, 2, 8, 10, 3, 4, 26, 23, 2];
      // const returned_to_care_remind = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
      // const returned_to_care_removed = [0, 1, 0, 2, 3, 7, 2, 2, 0, 10, 13, 4];
      colorAgree = "78, 206, 0";
      colorRemind = "255, 201, 63";
      colorRemoved = "232, 144, 80";

      const allReturnToCare = percentArray(
        data.returned_to_care,
        data.patients_called
      );

      const allReturnToCareFilter = percentArray(
        data.returned_to_care_filter,
        data.patients_called_filter
      );


      const AgreeToVisitReturnRate = percentArray(
        data.returned_to_care_agreed,
        data.patients_called_agreed_to_visit
      );
      const RemindToCallReturnRate = percentArray(
        data.returned_to_care_remind,
        data.patients_called_remind_to_call
      );

      const RemovedFromListReturnRate = percentArray(
        data.returned_to_care_removed,
        data.patients_called_removed_from_overdue_list
      );

      const returnToCareColor = "91, 0, 206";

      const config = {
        data: {
          labels: overdueDataLabels,
          datasets: [
            {
              label: "Agree to visit",
              data: AgreeToVisitReturnRate,
              backgroundColor: "rgba(134, 193, 98, 0.25)",
              borderColor: `rgba(${colorAgree},0.8)`,
              fill: false,
              radius: 0,

              segment: {
                borderDash: (ctx) =>
                  dynamicChartSegementDashed(ctx, overdueDataLabels.length),
              },
            },
            {
              label: "Remind to call",
              data: RemindToCallReturnRate,
              backgroundColor: "rgba(134, 193, 98, 0.25)",
              borderColor: `rgba(${colorRemind}, 0.8)`,
              fill: false,
              radius: 0,
              segment: {
                borderDash: (ctx) =>
                  dynamicChartSegementDashed(ctx, overdueDataLabels.length),
              },
            },
            {
              label: "Removed from overdue list",
              data: RemovedFromListReturnRate,
              backgroundColor: "rgba(134, 193, 98, 0.25)",
              borderColor: `rgba(${colorRemoved}, 0.8)`,
              fill: false,
              radius: 0,

              segment: {
                borderDash: (ctx) =>
                  dynamicChartSegementDashed(ctx, overdueDataLabels.length),
              },
            },
            // {
            //   label: "Returned to care filter",
            //   data: allReturnToCareFilter,
            //   fill: true,
            //   backgroundColor: `rgba(${returnToCareColor}, 0.1)`,
            //   borderColor: `rgba(${returnToCareColor}, 1)`,
            //   borderWidth: 0,
            //   radius: 0,
            //   segment: {
            //     borderDash: (ctx) =>
            //       dynamicChartSegementDashed(ctx, overdueDataLabels.length),
            //   },
            // },
            {
              label: "Returned to care",
              data: allReturnToCare,
              fill: true,
              backgroundColor: `rgba(${returnToCareColor}, 0.05)`,
              borderColor: `rgba(${returnToCareColor}, 1)`,
              segment: {
                borderDash: (ctx) =>
                  dynamicChartSegementDashed(ctx, overdueDataLabels.length),
              },
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
      const graphCanvas = container.querySelector("canvas");
      const defaultPeriod = container.getAttribute("data-period");
      const dataKeyNodes = container.querySelectorAll("[data-key]");
      // console.log('datanodes', dataKeyNodes);
      const populateDynamicComponents = (period) => {
        console.log(period);
        console.log(dataKeyNodes);
        dataKeyNodes.forEach((dataNode) => {
          const format = dataNode.dataset.format;
          const key = dataNode.dataset.key;
          console.log(id + "-data-key", data[key]);
          if (!data[key]) {
            throw `${key}: Key not present in data.`;
          }

          dataNode.innerHTML = formatValue(format, data[key][period]);
        });
      };

      if (!ReportsGraphConfig[id]) {
        throw `Config for ${id} is not defined`;
      }

      const graphConfig = ReportsGraphConfig[id](data);
      if (!graphConfig) {
        throw `Graph config not known for ${id}`;
      }

      // comeback and improve
      if (!graphConfig.options.plugins.tooltip.enabled) {
        graphConfig.options.plugins.tooltip = {
          enabled: false,
          external: (context) => {
            const isTooltipActive = context.tooltip._active.length > 0;
            if (isTooltipActive) {
              let hoveredDatapoint = context.tooltip.dataPoints;
              populateDynamicComponents(hoveredDatapoint[0].label);
            } else populateDynamicComponents(defaultPeriod); // remove 'defaultPeriod' parameter - internalise
          },
        };
      }

      if (graphCanvas) {
        // Assumes ChartJS is already imported
        new Chart(graphCanvas.getContext("2d"), graphConfig);
        populateDynamicComponents(defaultPeriod);
      }
    },
  };
};

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
            data: Object.values(controlledGraphRate),
            backgroundColor: colors.lightGreen,
            borderColor: colors.mediumGreen,
          },
        ],
      },
      options: {
        plugins: {
          tooltip: {
            external: (context) => {
              const isTooltipActive = context.tooltip._active.length > 0;
              if (isTooltipActive) {
                let hoveredDatapoint = context.tooltip.dataPoints;
                populateControlledGraph(hoveredDatapoint[0].label);
              } else populateControlledGraphDefault();
            },
          },
        },
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
            data: Object.values(uncontrolledGraphRate),
            backgroundColor: colors.lightRed,
            borderColor: colors.mediumRed,
          },
        ],
      },
      options: {
        plugins: {
          tooltip: {
            external: (context) => {
              const isTooltipActive = context.tooltip._active.length > 0;
              if (isTooltipActive) {
                let hoveredDatapoint = context.tooltip.dataPoints;
                populateUncontrolledGraph(hoveredDatapoint[0].label);
              } else populateUncontrolledGraphDefault();
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
            data: Object.values(missedVisitsGraphRate),
            backgroundColor: colors.lightBlue,
            borderColor: colors.mediumBlue,
          },
        ],
      },
      options: {
        plugins: {
          tooltip: {
            external: (context) => {
              const isTooltipActive = context.tooltip._active.length > 0;
              if (isTooltipActive) {
                let hoveredDatapoint = context.tooltip.dataPoints;
                populateMissedVisitsGraph(hoveredDatapoint[0].label);
              } else populateMissedVisitsGraphDefault();
            },
          },
        },
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
      data: {
        labels: Object.keys(data.cumulativeRegistrations),
        datasets: [
          {
            type: "line",
            label: "cumulative registrations",
            data: Object.values(data.cumulativeRegistrations),
            yAxisID: "y",
            backgroundColor: colors.transparent,
            borderColor: colors.darkPurple,
          },
          {
            type: "bar",
            label: "monthly registrations",
            data: Object.values(data.monthlyRegistrations),
            yAxisID: "yMonthlyRegistrations",
            backgroundColor: colors.lightPurple,
            hoverBackgroundColor: colors.darkPurple,
          },
        ],
      },
      options: {
        plugins: {
          tooltip: {
            external: (context) => {
              const isTooltipActive = context.tooltip._active.length > 0;
              if (isTooltipActive) {
                let hoveredDatapoint = context.tooltip.dataPoints;
                populateCumulativeRegistrationsGraph(hoveredDatapoint[0].label);
              } else populateCumulativeRegistrationsGraphDefault();
            },
          },
        },
        scales: {
          y: {
            grid: {
              drawTicks: false,
            },
            ticks: {
              display: false,
              stepSize: cumulativeRegistrationsYAxis.stepSize,
            },
            max: cumulativeRegistrationsYAxis.max,
          },
          yMonthlyRegistrations: {
            display: false,
            beginAtZero: true,
            min: 0,
            max: monthlyRegistrationsYAxis.max,
          },
        },
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

      const hypertensionOnlyRegistrationsNode = cardNode.querySelector(
        "[data-hypertension-only-registrations]"
      );

      const hypertensionAndDiabetesOnlyRegistrationsNode =
        cardNode.querySelector(
          "[data-hypertension-and-diabetes-registrations]"
        );

      const periodInfo = data.periodInfo[period];
      const cumulativeRegistrations = data.cumulativeRegistrations[period];
      const cumulativeHypertensionAndDiabetesRegistrations =
        data.cumulativeHypertensionAndDiabetesRegistrations[period];
      const monthlyRegistrations = data.monthlyRegistrations[period];

      monthlyRegistrationsNode.innerHTML =
        this.formatNumberWithCommas(monthlyRegistrations);
      totalPatientsNode.innerHTML = this.formatNumberWithCommas(
        cumulativeRegistrations
      );
      registrationsPeriodEndNode.innerHTML = periodInfo.bp_control_end_date;
      registrationsMonthEndNode.innerHTML = period;

      if (hypertensionOnlyRegistrationsNode) {
        hypertensionOnlyRegistrationsNode.innerHTML =
          this.formatNumberWithCommas(
            cumulativeRegistrations -
              cumulativeHypertensionAndDiabetesRegistrations
          );
      }

      if (hypertensionAndDiabetesOnlyRegistrationsNode) {
        hypertensionAndDiabetesOnlyRegistrationsNode.innerHTML =
          this.formatNumberWithCommas(
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
        withBaseLineConfig(config)
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
            data: Object.values(data.controlRate).slice(-barsToDisplay),
            backgroundColor: colors.mediumGreen,
            hoverBackgroundColor: colors.darkGreen,
          },
          {
            label: "BP uncontrolled",
            data: Object.values(data.uncontrolledRate).slice(-barsToDisplay),
            backgroundColor: colors.mediumRed,
            hoverBackgroundColor: colors.darkRed,
          },
          {
            label: "Visit but no BP measure",
            data: Object.values(data.visitButNoBPMeasureRate).slice(
              -barsToDisplay
            ),
            backgroundColor: colors.mediumGrey,
            hoverBackgroundColor: colors.darkGrey,
          },
          {
            label: "Missed visits",
            data: Object.values(data.missedVisitsRate).slice(-barsToDisplay),
            backgroundColor: colors.mediumBlue,
            hoverBackgroundColor: colors.darkBlue,
          },
        ],
      },
      options: {
        plugins: {
          tooltip: {
            external: (context) => {
              const isTooltipActive = context.tooltip._active.length > 0;
              if (isTooltipActive) {
                let hoveredDatapoint = context.tooltip.dataPoints;
                populateVisitDetailsGraph(hoveredDatapoint[0].label);
              } else populateVisitDetailsGraphDefault();
            },
          },
        },
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
      cumulativeDiabetesRegistrations:
        jsonData.cumulative_diabetes_registrations,
      cumulativeHypertensionAndDiabetesRegistrations:
        jsonData.cumulative_hypertension_and_diabetes_registrations,
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
  const colors = dashboardReportsChartJSColors();
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
          pointBackgroundColor: colors.white,
          hoverBackgroundColor: colors.white,
          borderWidth: 2,
          hoverRadius: 5,
          hoverBorderWidth: 2,
        },
        line: {
          tension: 0.4,
          borderWidth: 2,
          fill: true,
        },
      },
      interaction: {
        mode: "index",
        intersect: false,
      },
      plugins: {
        legend: {
          display: false,
        },
        tooltip: {
          enabled: false,
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
              family: "Roboto",
              size: 10,
            },
            padding: 8,
            stepSize: 25,
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
  const colors = dashboardReportsChartJSColors();
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
        tooltip: {
          enabled: false,
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
              family: "Roboto",
              size: 10,
            },
            padding: 8,
          },
          min: 0,
          beginAtZero: true,
        },
      },
    },
    plugins: [intersectDataVerticalLine],
  };
}

// ----------------------------
// Segment Functions

// Create a dashed line for the last segment of dynamic charts
const dynamicChartSegementDashed = (
  ctx,
  numberOfXAxisTicks,
  numberOfDashedSegments
) => {
  // console.log("ctx", ctx);
  // console.log(numberOfXAxisTicks);
  return ctx.p0DataIndex === numberOfXAxisTicks - 2 ? [4, 3] : undefined;
};

// Create a different line color for segments that go down
const down = (ctx, color) =>
  ctx.p0.parsed.y > ctx.p1.parsed.y ? color : undefined;

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

function randomNumber(min, max) {
  return Math.random() * (max - min) + min;
}

function getPercent(figure1, figure2) {
  if (figure1 === 0 && figure2 === 0) {
    return 0;
  }
  return (figure1 * 100) / figure2;
}
function percentArray(array1, array2) {
  const percentArray = [];
  for (let index = 0; index < array1.length; index++) {
    percentArray.push(getPercent(array1[index], array2[index]));
  }
  return percentArray;
}
