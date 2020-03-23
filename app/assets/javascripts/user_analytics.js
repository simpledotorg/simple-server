function formatDate(date) {
  return date.toJSON().slice(0, 10);
}

function statistics() {
  return JSON.parse(document.getElementById('statistics').attributes.getNamedItem('data-statistics').value);
}

function dailyStatistics() {
  return Object.entries(statistics().daily.grouped_by_date);
}

function today() {
  return new Date();
}

function yesterday() {
  var todayDate = today();
  return new Date(todayDate.setDate(todayDate.getDate() - 1));
}

function formattedTomorrowDate() {
  return statistics().metadata.formatted_next_date;
}

function formattedTodayString() {
  return statistics().metadata.formatted_today_string;
}

function latestDateInDailyStatistics() {
  var listOfDates = [];

  for (let [date, _] of dailyStatistics()) {
    listOfDates.push(Date.parse(date));
  }

  return new Date(Math.max.apply(null, listOfDates));
}

function syncNudgeCardElement() {
  return document.querySelector('#daily-stats-card > .count-empty');
}

function allDaysInCarouselElements() {
  return document.getElementsByClassName("day");
}

function syncNudgeCardPosition() {
  for (let [position, element] of Object.entries(allDaysInCarouselElements())) {
    if (element === syncNudgeCardElement()) {
      return parseInt(position);
    }
  }

  return -1
}

function showSyncNudge(currentSlide) {
  var weHaveDataForToday = false;

  for (let [date, _] of dailyStatistics()) {
    if (date === formatDate(today())) {
      // don't count the sync nudge card as a real day card
      weHaveDataForToday = true;
      syncNudgeCardElement().classList.remove("day");
      break;
    }
  }

  if (!weHaveDataForToday && (currentSlide === syncNudgeCardPosition())) {
    // re-enable the nudge card if we don't have today's data
    syncNudgeCardElement().classList.add("day");
    syncNudgeCardElement().style.display = 'block';
  }
}

function updateDateAtEndOfCarousel() {
  var endOfCarouselElement = allDaysInCarouselElements()[0].querySelector('.stat-day');

  if (formatDate(latestDateInDailyStatistics()) === formatDate(today())) {
    endOfCarouselElement.innerHTML = formattedTodayString();
  } else if (formatDate(latestDateInDailyStatistics()) === formatDate(yesterday())) {
    endOfCarouselElement.innerHTML = formattedTodayString();
  } else if (formatDate(latestDateInDailyStatistics()) < formatDate(yesterday())) {
    endOfCarouselElement.innerHTML = formattedTomorrowDate();
  }
}

function nextSlide(increment) {
  nextSlidePosition = window.lastSlidePositionForProgressCards += increment;

  showSyncNudge(nextSlidePosition);
  showDailyProgressCards(nextSlidePosition);
  updateDateAtEndOfCarousel();
}

function showDailyProgressCards(next) {
  var elementsForAllDays = allDaysInCarouselElements();
  var nextButton = document.getElementsByClassName("button-next")[0];
  var prevButton = document.getElementsByClassName("button-prev")[0];

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

function filterDataByGender(tableName) {
  var tableElements = document.getElementsByClassName('progress-table ' + tableName);
  var tableFilterElement = document.getElementsByClassName('card-dropdown ' + tableName);
  var selectedOption = tableFilterElement[0].selectedOptions[0].value;
  var selectedTableElement = document.getElementsByClassName('progress-table ' + tableName + ' ' + selectedOption);

  for (let i = 0; i < tableElements.length; i++) {
    tableElements[i].style.display = 'none';
  }

  selectedTableElement[0].style.display = 'inline-table';
}

window.onload = function () {
  window.lastSlidePositionForProgressCards = 1;

  showSyncNudge(window.lastSlidePositionForProgressCards);
  showDailyProgressCards(window.lastSlidePositionForProgressCards);
  updateDateAtEndOfCarousel()
};
