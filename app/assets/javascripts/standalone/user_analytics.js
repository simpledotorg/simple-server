//
// stats
//
function statistics() {
  if(document.getElementById('statistics')) {
    let statistics = document.getElementById('statistics');
    return JSON.parse(statistics.attributes.getNamedItem('data-statistics').value);
  } else {
    return null;
  }
}

function dailyStatistics() {
  return Object.entries(statistics()
    .daily
    .grouped_by_date);
}

//
// dates
//
function formatDate(date) {
  return date.toJSON().slice(0, 10);
}

function today() {
  let local = new Date();
  local.setMinutes(local.getMinutes() - local.getTimezoneOffset());

  return local
}

function yesterday() {
  const todayDate = today();
  return new Date(todayDate.setDate(todayDate.getDate() - 1));
}

function todayString() {
  return statistics().metadata.today_string;
}

function formattedTomorrowDate() {
  return statistics().metadata.formatted_next_date;
}

function dailyStatisticsDates() {
  const dates =
    dailyStatistics().map(([_, stat]) => stat);

  return Object.keys(Object.assign(...dates));
}

function latestDateInDailyStatistics() {
  const dates =
    dailyStatisticsDates().map(date => Date.parse(date));

  return new Date(Math.max.apply(null, dates));
}

//
// elements
//
function $syncNudgeCard() {
  return document.querySelector('#daily-stats-card > .count-empty');
}

function $allDaysInCarousel() {
  return document.getElementsByClassName("day");
}

function $nextSlideButton() {
  return document.getElementsByClassName("button-next")[0];
}

function $prevSlideButton() {
  return document.getElementsByClassName("button-prev")[0];
}

//
// behaviour
//
function syncNudgeCardPosition() {
  const syncNudgeCardElement = $syncNudgeCard();
  const allDaysInCarousel = $allDaysInCarousel();

  for (let [position, element] of Object.entries(allDaysInCarousel)) {
    if (element === syncNudgeCardElement) {
      return parseInt(position) + 1;
    }
  }

  return -1
}

function showSyncNudge(currentSlide) {
  let dataForTodayPresent = false;
  let syncNudgeCardElement = $syncNudgeCard();

  for (let date of dailyStatisticsDates()) {
    if (date === formatDate(today())) {
      // don't count the sync nudge card as a real day card
      dataForTodayPresent = true;
      syncNudgeCardElement.classList.remove("day");
      break;
    }
  }

  if (!dataForTodayPresent && (currentSlide === syncNudgeCardPosition())) {
    // re-enable the nudge card if we don't have today's data
    syncNudgeCardElement.classList.add("day");
    syncNudgeCardElement.style.display = 'block';
  }
}

function updateDateAtEndOfCarousel() {
  const latestDate = formatDate(latestDateInDailyStatistics());
  const todayDate = formatDate(today());
  const yesterdayDate = formatDate(yesterday());
  const endOfCarouselElement = $allDaysInCarousel()[0].querySelector('.stat-day');

  if (latestDate === todayDate || latestDate === yesterdayDate) {
    endOfCarouselElement.innerHTML = todayString();
    return;
  }

  if (latestDate < yesterdayDate) {
    endOfCarouselElement.innerHTML = formattedTomorrowDate();
  }
}

function showDailyProgressCards(next) {
  const elementsForAllDays = $allDaysInCarousel();
  let nextButton = $nextSlideButton();
  let prevButton = $prevSlideButton();

  nextButton.disabled = false;
  prevButton.disabled = false;

  if (next === elementsForAllDays.length) {
    nextButton.disabled = true;
  }

  if (next === 1) {
    prevButton.disabled = true;
  }

  for (let i = 0; i < elementsForAllDays.length; i++) {
    elementsForAllDays[i].classList.remove("day-show");
  }

  elementsForAllDays[window.lastSlidePositionForProgressCards - 1].classList.add("day-show");
}

function refreshCarousel(slidePosition) {
  showSyncNudge(slidePosition);
  showDailyProgressCards(slidePosition);
  updateDateAtEndOfCarousel()
}

//
// loads at page refresh
//
window.onload = function () {
  if(statistics() === null) {
    return;
  }

  window.lastSlidePositionForProgressCards = 1;
  refreshCarousel(window.lastSlidePositionForProgressCards)
};

//
// on-click events
//
function nextSlide(increment) {
  refreshCarousel(window.lastSlidePositionForProgressCards += increment)
}

function filterDataByGender(tableName) {
  let tableElements = document.getElementsByClassName('progress-table ' + tableName);
  const tableFilterElement = document.getElementsByClassName('card-dropdown ' + tableName);
  const selectedOption = tableFilterElement[0].selectedOptions[0].value;
  let selectedTableElement = document.getElementsByClassName('progress-table ' + tableName + ' ' + selectedOption);

  for (let i = 0; i < tableElements.length; i++) {
    tableElements[i].style.display = 'none';
  }

  selectedTableElement[0].style.display = 'inline-table';
}

//
// Overlays
//
function openWindow(id, parentId) {
  let element = document.getElementById(id);
  element.style.display = 'block';
  element.style.height = 'auto';

  if (parentId) {
    let parent = document.getElementById(parentId);
    parent.style.display = 'none';
    parent.style.height = '0';
  }

  document.body.scrollTop = 0; // For Safari
  document.documentElement.scrollTop = 0; // For Chrome, Firefox, IE and Opera
}

function closeWindow(id, parentId) {
  let element = document.getElementById(id);
  element.style.display = 'none';
  element.style.height = '0';

  if (parentId) {
    let parent = document.getElementById(parentId);
    parent.style.display = 'block';
    parent.style.height = 'auto';
  }

  document.body.scrollTop = 0;
  document.documentElement.scrollTop = 0;
}
//
// Card header tooltip interactions
//
const headerTitles = document.querySelectorAll("[data-element-type='header-title']");
headerTitles.forEach(headerTitle => {
  headerTitle.addEventListener("touchstart", handleHeaderTitleTouchStart, false);
  headerTitle.addEventListener("touchend", handleHeaderTitleTouchEnd, false);
});

function handleHeaderTitleTouchStart(event) {
  event.preventDefault();

  const header = event.target.parentElement;
  const headerTitle = header.querySelector("[data-element-type='header-title']");
  const helpCircle = header.querySelector("[data-element-type='help-circle']");
  const tooltip = header.querySelector("[data-element-type='tooltip']");
  const tooltipTip = header.querySelector("[data-element-type='tip']");

  tooltip.classList.remove("o-0");
  tooltip.style.top = `${headerTitle.offsetTop - tooltip.offsetHeight - 8}px`;
  tooltip.style.left = `${headerTitle.offsetLeft}px`;

  tooltipTip.style.left = `${helpCircle.offsetLeft}px`;
}

function handleHeaderTitleTouchEnd(event) {
  event.preventDefault();

  const header = event.target.parentElement.parentElement;
  const tooltip = header.querySelector("[data-element-type='tooltip']");
  tooltip.classList.add("o-0");
}

//
// Bar chart interactions
//
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

//
// Stacked bar chart interactions
//
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
//
// Daily report
//
function updateDailyReport() {
  const dropdown = document.getElementById("period-dropdown");
  const selectValue = dropdown.value;

  const dailyCards = document.querySelectorAll("[data-element='daily-cards']");

  dailyCards.forEach($card => {
    if ($card.getAttribute("data-date") == selectValue) {
      $card.classList.remove("d-none");
      $card.classList.add("d-block");
    } else {
      $card.classList.remove("d-block");
      $card.classList.add("d-none");
    }
  });
}

//
// Monthly report
//
function updateMonthlyReport(elementId) {
  const registrationsDropdown = document.getElementById(elementId);
  const selectValue = registrationsDropdown.value;

  const querySelector = "[data-element='monthly-" + elementId + "-card']";

  const monthlyTables = document.querySelectorAll(querySelector);

  monthlyTables.forEach($table => {
    if ($table.getAttribute("data-dimension-field") == selectValue) {
      $table.classList.remove("d-none");
      $table.classList.add("d-block");
    } else {
      $table.classList.remove("d-block");
      $table.classList.add("d-none");
    }
  });
}