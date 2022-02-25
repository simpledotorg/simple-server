// Subview navigation
function goToPage(startPageId, endPageId) {
  const startPage = document.getElementById(startPageId);
  addCSSClasses(startPage, ["d-none", "h-0px"]);
  removeCSSClasses(startPage, ["d-block", "h-auto"]);

  const endPage = document.getElementById(endPageId);
  addCSSClasses(endPage, ["d-block", "h-auto"]);
  removeCSSClasses(endPage, ["d-none", "h-0px"]);

  document.body.scrollTop = 0;
  document.documentElement.scrollTop = 0;
}

// Bar chart interactions
const barCharts = document.querySelectorAll("[data-graph-type='bar-chart'][data-with-tooltip='true']");
barCharts.forEach(barChart => {
  const bars = barChart.querySelectorAll("[data-graph-element='bar'");

  bars.forEach(bar => {
    bar.addEventListener("touchstart", handleBarTouchStart, false);
    bar.addEventListener("touchend", handleBarTouchEnd, false);
  });
});

function handleBarTouchStart(event) {
  event.preventDefault();

  const barChart = event.target.parentElement.parentElement;
  Array.from(barChart.children).forEach(barContainer => {
    const text = barContainer.querySelector("[data-element-type='text'");
    text.classList.add("c-grey-dark");
    text.classList.remove("c-black");

    const bar = barContainer.querySelector("[data-element-type='bar']");
    bar.classList.add("o-35");
  });

  const selectedDataPoint = event.target.parentElement;

  const selectedText = selectedDataPoint.querySelector("[data-element-type='text'");
  selectedText.classList.add("c-black");
  selectedText.classList.remove("c-grey-dark");

  const selectedBar = selectedDataPoint.querySelector("[data-element-type='bar'");
  selectedBar.classList.remove("o-35");

  const selectedTooltip = selectedDataPoint.querySelector("[data-element-type='tooltip']");
  const selectedTooltipTip = selectedTooltip.querySelector("[data-element-type='tip'");
  selectedTooltip.style.top = `${selectedText.offsetTop - selectedTooltip.offsetHeight - 12}px`;
  selectedTooltipTip.style.left = `${(selectedText.offsetLeft + (selectedText.offsetWidth / 2)) - (selectedTooltipTip.offsetWidth / 2)}px`;

  selectedTooltip.classList.remove("o-0");
}

function handleBarTouchEnd(event) {
  event.preventDefault();

  const barChart = event.target.parentElement.parentElement;
  Array.from(barChart.children).forEach(barContainer => {
    const text = barContainer.querySelector("[data-element-type='text']");
    text.classList.add("c-black");
    text.classList.remove("c-grey-dark");

    const bar = barContainer.querySelector("[data-element-type='bar']");
    bar.classList.remove("o-35");

    const tooltip = barContainer.querySelector("[data-element-type='tooltip'");
    tooltip.classList.add("o-0");
  });
}

// Card header tooltip interactions
const helpCircles = document.querySelectorAll("[data-element-type='help-circle']");
helpCircles.forEach(helpCircle => {
  helpCircle.addEventListener("touchstart", handleHelpCircleTouchStart, false);
  helpCircle.addEventListener("touchend", handleHelpCircleTouchEnd, false);
});

function handleHelpCircleTouchStart(event) {
  event.preventDefault();

  const header = event.target.parentElement;
  const helpCircle = header.querySelector("[data-element-type='help-circle']");
  const tooltip = header.querySelector("[data-element-type='tooltip']");
  const tooltipTip = header.querySelector("[data-element-type='tip']");

  tooltip.classList.remove("o-0");
  tooltip.style.top = `${helpCircle.offsetTop + helpCircle.offsetHeight + tooltipTip.offsetHeight + 4}px`;

  tooltipTip.style.left = `${helpCircle.offsetLeft + 2}px`;
}

function handleHelpCircleTouchEnd(event) {
  event.preventDefault();

  const header = event.target.parentElement.parentElement;
  const tooltip = header.querySelector("[data-element-type='tooltip']");
  tooltip.classList.add("o-0");
}

// Stacked bar chart interactions
const stackedBars = document.querySelectorAll("[data-graph-element='stacked-bar']");
stackedBars.forEach(stackedBar => {
  stackedBar.addEventListener("touchstart", handleStackedBarTouchStart, false);
  stackedBar.addEventListener("touchend", handleStackedBarTouchEnd, false);
});

function handleStackedBarTouchStart(event) {
  event.preventDefault();

  const selectedBar = event.target;
  const selectedBarChart = selectedBar.parentElement;
  const selectedBarChartBars = selectedBarChart.querySelectorAll("[data-graph-element='stacked-bar']");
  selectedBarChartBars.forEach(bar => {
    bar.classList.add("o-35");
  });

  selectedBar.classList.remove("o-35");
  const selectedTooltip = selectedBar.querySelector("[data-element-type='tooltip']");
  selectedTooltip.classList.remove("o-0");

  setTooltipPosition(selectedTooltip, selectedBar);
}

function handleStackedBarTouchEnd(event) {
  event.preventDefault();

  const selectedBarChart = event.target.parentElement;
  const selectedBarChartBars = selectedBarChart.querySelectorAll("[data-graph-element='stacked-bar']");
  selectedBarChartBars.forEach(bar => {
    bar.classList.remove("o-35");
  });

  const selectedTooltip = event.target.querySelector("[data-element-type='tooltip']");
  selectedTooltip.classList.add("o-0");
}

function setTooltipCopyPosition(copyElement, containerElement, barElement) {
  const index = parseInt(containerElement.getAttribute("data-tooltip-index"));
  const totalTooltips = parseInt(containerElement.getAttribute("data-tooltip-length"));

  if (index === 0) {
    copyElement.style.left = 0;
  }
  else if (index === totalTooltips - 1) {
    copyElement.style.left = `${containerElement.offsetLeft + (containerElement.offsetWidth - copyElement.offsetWidth) - 1}px`;
  }
  else {
    copyElement.style.left = `${barElement.offsetLeft + ((barElement.offsetWidth / 2) - (copyElement.offsetWidth / 2))}px`;
  }

  copyElement.style.top = `${-copyElement.offsetHeight}px`;
}

function setTooltipTipPosition(tipElement, barElement) {
  tipElement.style.left = `${(barElement.offsetLeft + (barElement.offsetWidth / 2)) - (tipElement.offsetWidth / 2)}px`;
}

function setTooltipPosition(tooltipElement, barElement) {
  // "tipElement" is the tooltrip triangle
  const tipElement = tooltipElement.querySelector("[data-element-type='tooltip-tip']");
  const copyElement = tooltipElement.querySelector("[data-element-type='tooltip-copy']");
  // Position container
  tooltipElement.style.top = `${tooltipElement.offsetHeight - tipElement.offsetHeight - 4}px`;
  // Position tooltip tip
  setTooltipTipPosition(tipElement, barElement);
  // Position tooltip copy
  setTooltipCopyPosition(copyElement, tooltipElement, barElement);
}

function addCSSClasses(element, cssClasses) {
  cssClasses.forEach(cssClass => {
    element.classList.add(cssClass);
  });
}

function removeCSSClasses(element, cssClasses) {
  cssClasses.forEach(cssClass => {
    element.classList.remove(cssClass);
  })
}