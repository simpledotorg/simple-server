window.addEventListener("DOMContentLoaded", initializeCharts);

let lightGreenColor = "rgba(242, 248, 245, 1)";
let darkGreenColor = "rgba(0, 122, 49, 1)";
let mediumGreenColor = "rgba(0, 184, 73, 1)";
let lightRedColor = "rgba(255, 235, 238, 1)";
let darkRedColor = "rgba(255, 51, 85, 1)";
let lightPurpleColor = "rgba(238, 229, 252, 1)";
let darkPurpleColor = "rgba(83, 0, 224, 1)";
let darkGreyColor = "rgba(108, 115, 122, 1)";
let mediumGreyColor = "rgba(173, 178, 184, 1)";
let lightGreyColor = "rgba(240, 242, 245, 1)";

function getReportingData() {
  const $newData = document.getElementById("data-json");
  const jsonData = JSON.parse($newData.textContent);

  let data = {
    controlRate: jsonData.controlled_patients_rate,
    controlledPatients: jsonData.controlled_patients,
    missedVisits: jsonData.missed_visits,
    missedVisitsRate: jsonData.missed_visits_rate,
    registrations: jsonData.cumulative_registrations,
    adjustedRegistrations: jsonData.adjusted_registrations,
    uncontrolledRate: jsonData.uncontrolled_patients_rate,
    uncontrolledPatients: jsonData.uncontrolled_patients,
    visitButNoBPMeasure: jsonData.visited_without_bp_taken,
    visitButNoBPMeasureRate: jsonData.visited_without_bp_taken_rate
  };

  return data;
};

function initializeCharts() {
  const data = getReportingData();

  const controlledGraphConfig = createGraphConfig([{
    data: data.controlRate,
    borderWidth: 2,
    rgbaLineColor: mediumGreenColor,
    rgbaPointColor: lightGreenColor,
    rgbaBackgroundColor: lightGreenColor,
    label: "HTN controlled",
  }], "line");
  controlledGraphConfig.options = createGraphOptions(
    false,
    25,
    100,
    formatValueAsPercent,
    formatRateTooltipText,
    [data.controlledPatients],
    data.adjustedRegistrations,
  );
  const controlledGraphCanvas = document.getElementById("controlledPatientsTrend");
  if (controlledGraphCanvas) {
    new Chart(controlledGraphCanvas.getContext("2d"), controlledGraphConfig);
  }

  const noRecentBPConfig = createGraphConfig([
    {
      data: data.visitButNoBPMeasureRate,
      borderWidth: 0,
      rgbaLineColor: darkGreyColor,
      rgbaBackgroundColor: darkGreyColor,
      hoverBackgroundColor: darkGreyColor,
      label: "visited in the last 3 months",
    },
    {
      data: data.missedVisitsRate,
      borderWidth: 0,
      rgbaLineColor: mediumGreyColor,
      rgbaBackgroundColor: mediumGreyColor,
      label: "last BP >3 months ago",
    },
  ], "bar");
  noRecentBPConfig.options = createGraphOptions(
    true,
    25,
    100,
    formatValueAsPercent,
    formatRateTooltipText,
    [data.visitButNoBPMeasure, data.missedVisits],
    data.adjustedRegistrations,
  );

  const noRecentBPGraphCanvas = document.getElementById("noRecentBPTrend");
  if (noRecentBPGraphCanvas) {
    new Chart(noRecentBPGraphCanvas.getContext("2d"), noRecentBPConfig);
  }

  const uncontrolledGraphConfig = createGraphConfig([
    {
      data: data.uncontrolledRate,
      borderWidth: 2,
      rgbaLineColor: darkRedColor,
      rgbaPointColor: lightRedColor,
      rgbaBackgroundColor: lightRedColor,
      label: "HTN not under control",
    }
  ], "line");
  uncontrolledGraphConfig.options = createGraphOptions(
    false,
    25,
    100,
    formatValueAsPercent,
    formatRateTooltipText,
    [data.uncontrolledPatients],
    data.adjustedRegistrations,
  );
  const uncontrolledGraphCanvas = document.getElementById("uncontrolledPatientsTrend");
  if (uncontrolledGraphCanvas) {
    new Chart(uncontrolledGraphCanvas.getContext("2d"), uncontrolledGraphConfig);
  }

  const maxRegistrations = Math.max(...Object.values(data.registrations));
  const suggestedMax = Math.round(maxRegistrations) * 1.15;
  const stepSize = Math.round(suggestedMax / 3);
  const cumulativeRegistrationsGraphConfig = createGraphConfig([
    {
      data: data.registrations,
      borderWidth: { top: 2 },
      rgbaLineColor: darkPurpleColor,
      rgbaBackgroundColor: lightPurpleColor,
      hoverBackgroundColor: lightPurpleColor,
    },
  ], "bar");
  cumulativeRegistrationsGraphConfig.options = createGraphOptions(
    false,
    stepSize,
    suggestedMax,
    formatNumberWithCommas,
    formatSumTooltipText,
  );
  const cumulativeRegistrationsGraphCanvas = document.getElementById("cumulativeRegistrationsTrend");
  if (cumulativeRegistrationsGraphCanvas) {
    new Chart(cumulativeRegistrationsGraphCanvas.getContext("2d"), cumulativeRegistrationsGraphConfig);
  }

  const visitDetailsGraphConfig = createGraphConfig([
    {
      data: data.controlRate,
      rgbaBackgroundColor: mediumGreenColor,
      hoverBackgroundColor: mediumGreenColor,
      label: "control rate",
    },
    {
      data: data.uncontrolledRate,
      rgbaBackgroundColor: darkRedColor,
      hoverBackgroundColor: darkRedColor,
      label: "not under control rate",
    },
    {
      data: data.visitButNoBPMeasureRate,
      rgbaBackgroundColor: darkGreyColor,
      hoverBackgroundColor: darkGreyColor,
      label: "visited in the last 3 months",
    },
    {
      data: data.missedVisitsRate,
      rgbaBackgroundColor: mediumGreyColor,
      hoverBackgroundColor: mediumGreyColor,
      label: "last BP >3 months ago",
    }
  ], "bar");
  visitDetailsGraphConfig.options = createGraphOptions(
    true,
    25,
    100,
    formatValueAsPercent,
    formatRateTooltipText,
    [data.controlledPatients, data.uncontrolledPatients, data.visitButNoBPMeasure, data.missedVisits],
    data.adjustedRegistrations,
  );
  const visitDetailsGraphCanvas = document.getElementById("missedVisitDetails");
  if (visitDetailsGraphCanvas) {
    new Chart(visitDetailsGraphCanvas.getContext("2d"), visitDetailsGraphConfig);
  }
};

function createGraphConfig(datasetsConfig, graphType) {
  return {
    type: graphType,
    data: {
      labels: Object.keys(datasetsConfig[0].data),
      datasets: datasetsConfig.map(dataset => {
        return {
          label: dataset.label,
          backgroundColor: dataset.rgbaBackgroundColor,
          borderColor: dataset.rgbaLineColor ? dataset.rgbaLineColor : undefined,
          borderWidth: dataset.borderWidth ? dataset.borderWidth : undefined,
          pointBackgroundColor: dataset.rgbaPointColor,
          hoverBackgroundColor: dataset.hoverBackgroundColor,
          data: Object.values(dataset.data),
        };
      }),
    },
  };
};

function createGraphOptions(isStacked, stepSize, suggestedMax, tickCallbackFunction, tooltipCallbackFunction, numerators, denominators) {
  return {
    animation: false,
    responsive: true,
    maintainAspectRatio: false,
    layout: {
      padding: {
        left: 0,
        right: 0,
        top: 48,
        bottom: 0
      }
    },
    elements: {
      point: {
        pointStyle: "circle",
        hoverRadius: 5,
      },
    },
    legend: {
      display: false,
    },
    scales: {
      xAxes: [{
        stacked: isStacked,
        display: true,
        gridLines: {
          display: true,
          drawBorder: false,
        },
        ticks: {
          fontColor: mediumGreyColor,
          fontSize: 12,
          fontFamily: "Roboto Condensed",
          padding: 8,
          maxRotation: 0,
          minRotation: 0,
          autoSkip: true,
          maxTicksLimit: 10 
        }
      }],
      yAxes: [{
        stacked: isStacked,
        display: true,
        gridLines: {
          display: true,
          drawBorder: false,
        },
        ticks: {
          fontColor: "#ADB2B8",
          fontSize: 12,
          fontFamily: "Roboto Condensed",
          padding: 8,
          stepSize,
          suggestedMax,
          suggestedMin: 0,
          callback: tickCallbackFunction,
        }
      }],
    },
    tooltips: {
      mode: "index",
      intersect: false,
      position: "average",
      callbacks: {
        label: function (tooltipItem, data) {
          return tooltipCallbackFunction(tooltipItem, data, numerators, denominators);
        },
        labelColor: function(tooltipItem, data) {
          const pointBackgroundColor = data.config.data.datasets[tooltipItem.datasetIndex].pointBackgroundColor;
          const borderColor = data.config.data.datasets[tooltipItem.datasetIndex].borderColor;
          const backgroundColor = data.config.data.datasets[tooltipItem.datasetIndex].backgroundColor;

          let styles = {};

          if (pointBackgroundColor === undefined) {
            styles.borderColor = backgroundColor;
            styles.backgroundColor = backgroundColor;
          } else {
            styles.borderColor = borderColor;
            styles.backgroundColor = borderColor;
          }

          return styles;
        }
      }
    }
  };
};

function formatRateTooltipText(tooltipItem, data, numerators, denominators) {
  const datasetIndex = tooltipItem.datasetIndex;
  const numerator = formatNumberWithCommas(numerators[datasetIndex][tooltipItem.label]);
  const denominator = formatNumberWithCommas(denominators[tooltipItem.label]);
  const label = data.datasets[datasetIndex].label;
  const percent = Math.round(tooltipItem.value);

  return ` ${percent}% ${label} (${numerator} of ${denominator} patients)`;
}

function formatSumTooltipText(tooltipItem) {
  return `${formatNumberWithCommas(tooltipItem.value)} cumulative registrations in ${tooltipItem.label}`;
}

function formatValueAsPercent(value) {
  return `${value}%`;
}

function formatNumberWithCommas(value) {
  return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function customTooltip(tooltipModel) {
  // Tooltip element
  var tooltipEl = document.getElementById('chartjs-tooltip');
  // Create element
  if (!tooltipEl) {
      tooltipEl = document.createElement('div');
      tooltipEl.id = 'chartjs-tooltip';
      document.body.appendChild(tooltipEl);
  }
  // Hide if no tooltip
  if (tooltipModel.opacity === 0) {
    tooltipEl.style.opacity = 0;
    return;
  }
  // Set caret position
  tooltipEl.classList.remove('above', 'below', 'no-transform');
  if (tooltipModel.yAlign) {
    tooltipEl.classList.add(tooltipModel.yAlign);
  } else {
    tooltipEl.classList.add('no-transform');
  }

  // Set tooltip content 
  if (tooltipModel.body) {
    // Set title
    const tooltipTitle = tooltipModel.title[0];
    const titleStyle =
      `
        margin: 0;
        margin-bottom: 4px;
        font-size: 14px;
        font-weight: 600;
      `;
    let innerHtml = `<p style="${titleStyle}">${tooltipTitle}</p>`;
    // Set labels
    const labelsContainerStyle =
      `
        display: flex;
        flex-direction: column;
      `;
    innerHtml += `<div style="${labelsContainerStyle}">`;

    const labels = tooltipModel.body.map(item => item.lines);

    labels.forEach(function(label, index) {
      const labelRowStyle =
        `
          display: flex;
          align-items: baseline;
          margin-bottom: 4px;
        `;
      innerHtml += `<div style="${labelRowStyle}">`;
      const colors = tooltipModel.labelColors[index];
      const labelSwatchStyle =
        `
          background: ${colors.backgroundColor};
          width: 10px;
          height: 10px;
          margin-right: 6px;
          border-radius: 2px;
        `;
      const labelSwatch = `<span style="${labelSwatchStyle}"></span>`;
      const labelTextStyle = 'margin: 0; font-family: Roboto Condensed; font-size: 14px; color: #ffffff;';
      const labelText = `<p style="${labelTextStyle}">${label}</p>`;
      innerHtml += labelSwatch + labelText;
      innerHtml += "</div>";
    });

    innerHtml += "</div>";

    tooltipEl.innerHTML = innerHtml;
  }

  // `this` will be the overall tooltip
  var position = this._chart.canvas.getBoundingClientRect();

  // Display, position, and set styles for font
  tooltipEl.style.opacity = 1;
  tooltipEl.style.width = 'auto';
  tooltipEl.style.position = 'absolute';
  tooltipEl.style.backgroundColor = "#000000";
  tooltipEl.style.left = position.left + window.pageXOffset + tooltipModel.caretX + 'px';
  tooltipEl.style.top = position.top + window.pageYOffset + tooltipModel.caretY + 'px';
  tooltipEl.style.fontFamily = "Roboto Condensed";
  tooltipEl.style.fontSize = tooltipModel.bodyFontSize + 'px';
  tooltipEl.style.fontStyle = tooltipModel._bodyFontStyle;
  tooltipEl.style.color = "#ffffff";
  tooltipEl.style.padding = "10px 12px";
  tooltipEl.style.borderRadius = "4px";
  tooltipEl.style.pointerEvents = 'none';
}