// Toggle page refresh scroll
window.addEventListener("DOMContentLoaded", (event) => {
if (localStorage.getItem("toggleScrollToPosition")) {
  scrollToPositionAndRemoveStorage();
  removeYPositionLocalStorage();
}
})

// Create toggle listener
function createToggleListener(id) {
  const toggleElement = document.getElementById(id);
  toggleElement.addEventListener("change", (event) => {
    setYPositionLocalStorage();
  });
}


// window.addEventListener("DOMContentLoaded", (event) => {
//   const ltfuControlledBPToggleElement = document.getElementById(
//     "controlledGraphLtfuToggle"
//   );
//   const ltfuUncontrolledBPToggleElement = document.getElementById(
//     "uncontrolledGraphLtfuToggle"
//   );
//   const ltfuMissedVisitToggleElement = document.getElementById(
//     "missedVisitsGraphLtfuToggle"
//   );
//   const ltfuDiaMissedVisitToggleElement = document.getElementById(
//     "overControlledGraphLtfuToggle"
//   );
//   const overdueToggleElement = document.getElementById("overdue-section");

//   if (localStorage.getItem("toggleScrollToPosition")) {
//     scrollToPositionAndRemoveStorage();
//     removeYPositionLocalStorage();
//   }

//   ltfuControlledBPToggleElement.addEventListener("change", (event) => {
//     setYPositionLocalStorage();
//   });
//   ltfuUncontrolledBPToggleElement.addEventListener("change", (event) => {
//     setYPositionLocalStorage();
//   });
//   ltfuMissedVisitToggleElement.addEventListener("change", (event) => {
//     setYPositionLocalStorage();
//   });
//   ltfuDiaMissedVisitToggleElement.addEventListener("change", (event) => {
//     setYPositionLocalStorage();
//   });
//   overdueToggleElement.addEventListener("change", (event) => {
//     setYPositionLocalStorage();
//   });
// });

function setYPositionLocalStorage() {
  localStorage.setItem("toggleScrollToPosition", window.pageYOffset);
}

function removeYPositionLocalStorage() {
  localStorage.removeItem("toggleScrollToPosition");
}

function scrollToPositionAndRemoveStorage() {
  window.scrollTo(0, parseInt(localStorage.getItem("toggleScrollToPosition")));
}
