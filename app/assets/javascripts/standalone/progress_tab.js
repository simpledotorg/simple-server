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
    const bar = dataPoint.querySelector("[data-point-type='bar'");
    value.classList.remove("c-black");
    value.classList.add("c-grey-dark");
    bar.classList.add("o-35");
  });

  const selectedDataPoint = event.target.parentElement;
  const selectedValue = selectedDataPoint.querySelector("[data-point-type='value'");
  const selectedBar = selectedDataPoint.querySelector("[data-point-type='bar'");
  selectedValue.classList.remove("c-grey-dark");
  selectedValue.classList.add("c-black");
  selectedBar.classList.remove("o-35");
}

function handleBarTouchEnd(event) {
  event.preventDefault();

  const barChart = event.target.parentElement.parentElement;
  Array.from(barChart.children).forEach(dataPoint => {
    const value = dataPoint.querySelector("[data-point-type='value'");
    const bar = dataPoint.querySelector("[data-point-type='bar'");
    value.classList.remove("c-black");
    value.classList.add("c-grey-dark");
    bar.classList.add("o-35");
  });

  const currentDataPoint = barChart.children[barChart.children.length - 1];
  const currentValue = currentDataPoint.querySelector("[data-point-type='value'");
  const currentBar = currentDataPoint.querySelector("[data-point-type='bar'");
  currentValue.classList.remove("c-grey-dark");
  currentValue.classList.add("c-black");
  currentBar.classList.remove("o-35");
}