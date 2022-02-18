// Subview navigation
function goToPage(startPageId, endPageId) {
  const startPage = document.getElementById(startPageId);
  startPage.style.display = "none";
  startPage.style.height = "0";
  const endPage = document.getElementById(endPageId);
  endPage.style.display = "block";
  endPage.style.height = "auto";
  document.body.scrollTop = 0;
  document.documentElement.scrollTop = 0;
}

// Bar chart interactions
const barCharts = document.querySelectorAll("[data-graph-type='bar-chart']");
barCharts.forEach(barChart => {
  const dataPoints = barChart.querySelectorAll("[data-data-point='bar'");
  dataPoints.forEach(dataPoint => {
    dataPoint.addEventListener("touchstart", handleBarTouchStart, false);
    dataPoint.addEventListener("touchend", handleBarTouchEnd, false);
  });
});

function handleBarTouchStart(event) {
  event.preventDefault();
  const barChart = event.target.parentElement.parentElement;
  Array.from(barChart.children).forEach(dataPoint => {
    const value = dataPoint.querySelector("[data-point-type='value'");
    value.classList.remove("c-black");
    value.classList.add("c-grey-dark");
    const bar = dataPoint.querySelector("[data-point-type='bar'");
    bar.classList.add("o-35");
  });
  const selectedDataPoint = event.target.parentElement;
  const selectedValue = selectedDataPoint.querySelector("[data-point-type='value'");
  selectedValue.classList.remove("c-grey-dark");
  selectedValue.classList.add("c-black");
  const selectedBar = selectedDataPoint.querySelector("[data-point-type='bar'");
  selectedBar.classList.remove("o-35");
  if (barChart.getAttribute("data-with-tooltip") === "true") {
    const selectedTooltip = selectedDataPoint.querySelector("[data-point-type='tooltip']");
    const selectedTooltipTip = selectedTooltip.querySelector("[data-element='tip'");
    selectedTooltip.classList.remove("d-none");
    selectedTooltip.classList.add("d-block");
    selectedTooltip.style.top = `${selectedValue.offsetTop - selectedTooltip.offsetHeight - 12}px`;
    selectedTooltipTip.style.left = `${(selectedValue.offsetLeft + (selectedValue.offsetWidth / 2)) - (selectedTooltipTip.offsetWidth / 2)}px`;
  }
}

function handleBarTouchEnd(event) {
  event.preventDefault();
  const barChart = event.target.parentElement.parentElement;
  Array.from(barChart.children).forEach(dataPoint => {
    const value = dataPoint.querySelector("[data-point-type='value'");
    value.classList.remove("c-black");
    value.classList.add("c-grey-dark");
    const bar = dataPoint.querySelector("[data-point-type='bar'");
    bar.classList.add("o-35");
    if (barChart.getAttribute("data-with-tooltip") === "true") {
      const tooltip = dataPoint.querySelector("[data-point-type='tooltip'");
      tooltip.classList.remove("d-block");
      tooltip.classList.add("d-none");
    }
  });
  const currentDataPoint = barChart.children[barChart.children.length - 1];
  const currentValue = currentDataPoint.querySelector("[data-point-type='value'");
  currentValue.classList.remove("c-grey-dark");
  currentValue.classList.add("c-black");
  const currentBar = currentDataPoint.querySelector("[data-point-type='bar'");
  currentBar.classList.remove("o-35");
}

// Card header tooltip interactions
const helpCircles = document.querySelectorAll("[data-element-type='help-circle']");
helpCircles.forEach(helpCircle => {
  helpCircle.addEventListener("touchstart", handleHelpCircleTouchStart, false);
  helpCircle.addEventListener("touchend", handleHelpCircleTouchEnd, false);
});

function handleHelpCircleTouchStart(event) {
  event.preventDefault();
  const header = event.target.parentElement.parentElement;
  const helpCircle = header.querySelector("[data-element-type='help-circle']");
  const tooltip = header.querySelector("[data-element-type='tooltip']");
  const tooltipTip = header.querySelector("[data-element-type='tip']");
  tooltip.classList.remove("d-none");
  tooltip.classList.add("d-block");
  tooltip.style.top = `${helpCircle.offsetTop + helpCircle.offsetHeight + tooltipTip.offsetHeight + 4}px`;
  tooltipTip.style.left = `${helpCircle.offsetLeft + 2}px`;
}

function handleHelpCircleTouchEnd(event) {
  event.preventDefault();
  const header = event.target.parentElement.parentElement;
  const tooltip = header.querySelector("[data-element-type='tooltip']");
  tooltip.classList.remove("d-block");
  tooltip.classList.add("d-none");
}