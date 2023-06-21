// Check for scroll position and scroll
window.addEventListener("DOMContentLoaded", (event) => {
  if (doesYPositionExistInLocalStorage()) {
    scrollToYPosition();
    removeYPositionLocalStorage();
  }
});

// Create toggle change listener and add y position on 'change' event
function createToggleListener(id) {
  const toggleElement = document.getElementById(id);
  toggleElement.addEventListener("change", (event) => {
    setYPositionLocalStorage();
  });
}

function setYPositionLocalStorage() {
  localStorage.setItem("toggleScrollToPosition", window.pageYOffset);
}

function removeYPositionLocalStorage() {
  localStorage.removeItem("toggleScrollToPosition");
}

function doesYPositionExistInLocalStorage() {
    return localStorage.getItem("toggleScrollToPosition")
}

function scrollToYPosition() {
  window.scrollTo(0, parseInt(localStorage.getItem("toggleScrollToPosition")));
}
