// Check for scroll position and scroll
window.addEventListener("DOMContentLoaded", (event) => {
  if (localStorage.getItem("yScrollPosition")) {
    window.scrollTo(
      0,
      parseInt(localStorage.getItem("yScrollPosition"))
    );
    localStorage.removeItem("yScrollPosition");
  }
});

// Create toggle change listener and add y position on 'change' event
function createScrollTrackingListener(id) {
  const toggleElement = document.getElementById(id);
  toggleElement.addEventListener("change", (event) => {
    localStorage.setItem("yScrollPosition", window.pageYOffset);
  });
}