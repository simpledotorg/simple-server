//
// stats
//
function statistics() {
  return JSON.parse(document
    .getElementById('statistics')
    .attributes
    .getNamedItem('data-statistics')
    .value);
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
  return new Date();
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
