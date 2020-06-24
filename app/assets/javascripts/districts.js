window.addEventListener("DOMContentLoaded", initializeCharts);

function initializeCharts() {
  const data = getReportingData();
  console.log(data);
};

function getReportingData() {
  const $reportingDiv = document.getElementById("reporting");
  const controlledPatients = 
    JSON.parse($reportingDiv.attributes.getNamedItem("data-controlled-patients").value);
  const registrations =
    JSON.parse($reportingDiv.attributes.getNamedItem("data-registrations").value);
  const quarterlyRegistrations =
    JSON.parse($reportingDiv.attributes.getNamedItem("data-quarterly-registrations").value);
  
  let data = {
    controlledPatients: Object.entries(controlledPatients),
    registrations: Object.entries(registrations),
  };

  let controlRate = computeControlRate(data.controlledPatients, data.registrations);
  data.controlRate = controlRate;

  return data;
};

function computeControlRate(controlledPatients, registrations) {
  return controlledPatients.map(function(key, index) {
    const registrationData = registrations[index];
    const controlRate = numberToPercent(key[1], registrationData[1]);

    return [key[0], controlRate];
  });
};

function numberToPercent(numerator, denominator) {
  return parseFloat(((numerator/denominator)*100).toFixed(0));
}; 

// var controlledPatientsTrendCanvas =
//   document.getElementById("controlledPatientsTrend").getContext("2d");
// var greenGradientFill =
//   controlledPatientsTrendCanvas.createLinearGradient(0, 400, 0, -300);
// greenGradientFill.addColorStop(0, "rgba(81, 205, 130, 0)");
// greenGradientFill.addColorStop(1, "rgba(81, 205, 130, 0.2)");
// var controlledPatientsTrendChart = new Chart(
//   controlledPatientsTrendCanvas,
//   {
//     type: "line",
//     data: {
//       labels: controlRate.map(key => key[0]),
//       datasets: [{
//         backgroundColor: greenGradientFill,
//         borderColor: "rgba(81, 205, 130, 1)",
//         data: controlRate.map(key => key[1]),
//       }],
//     },
//     options: {
//       animation: false,
//       responsive: true,
//       maintainAspectRatio: false,
//       elements: {
//         point: {
//           pointStyle: "circle",
//           backgroundColor: "rgba(81, 205, 130, 1)",
//           hoverRadius: 5,
//         },
//       },
//       legend: {
//         display: false,
//       },
//       scales: {
//         xAxes: [{
//           display: false,
//           gridLines: {
//             display: false,
//             drawBorder: false,
//           },
//         }],
//         yAxes: [{
//           display: false,
//           gridLines: {
//             display: false,
//             drawBorder: false,
//           },
//         }],
//       },
//       tooltips: {
//         titleFontFamily: "Roboto",
//         bodyFontFamily: "Roboto",
//         backgroundColor: "rgb(0, 0, 0)",
//         titleFontSize: 16,
//         bodyFontSize: 14,
//         displayColors: false,
//         yPadding: 12,
//         xPadding: 12,
//         callbacks: {
//           label: function(tooltipItem, data) {
//             const controlledPatientValue = controlledPatients.map(key => key[1])[tooltipItem.index];
//             const formattedValue = controlledPatientValue.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
//             let value = parseInt(tooltipItem.value).toFixed(1);
//             return `${value}% (${formattedValue} patients)`;
//           },
//         },
//       }
//     }
//   }
// );
// var cumulativeRegistrationsCanvas =
//   document.getElementById("cumulativeRegistrations").getContext("2d");
// var purpleGradientFill =
//   cumulativeRegistrationsCanvas.createLinearGradient(0, 400, 0, -300);
//   purpleGradientFill.addColorStop(0, "rgba(157, 74, 199, 0)");
//   purpleGradientFill.addColorStop(1, "rgba(157, 74, 199, 0.2)");
// var cumulativeRegistrationsChart = new Chart(
//   cumulativeRegistrationsCanvas,
//   {
//     type: "bar",
//     data: {
//       labels: registrations.map(key => key[0]),
//       datasets: [{
//         data: registrations.map(key => key[1]),
//         backgroundColor: purpleGradientFill,
//         borderColor: "rgba(157, 74, 199, 1)",
//         borderWidth:{ top:2, right:0, bottom:0, left:0 },
//         hoverBackgroundColor: "rgba(157, 74, 199, 1)",
//       },],
//     },
//     options: {
//       animation: false,
//       responsive: true,
//       maintainAspectRatio: false,
//       elements: {
//         point: {
//           radius: 0,
//         },
//       },
//       legend: {
//         display: false,
//       },
//       scales: {
//         xAxes: [{
//           stacked: true,
//           barPercentage: 1,
//           display: false,
//           gridLines: {
//             display: false,
//             drawBorder: false,
//           },
//         }],
//         yAxes: [{
//           stacked: true,
//           display: false,
//           gridLines: {
//             display: false,
//             drawBorder: false,
//           },
//         }],
//       },
//       tooltips: {
//         titleFontFamily: "Roboto",
//         bodyFontFamily: "Roboto",
//         backgroundColor: "rgb(0, 0, 0)",
//         titleFontSize: 16,
//         bodyFontSize: 14,
//         displayColors: false,
//         yPadding: 12,
//         xPadding: 12,
//         callbacks: {
//           label: function(tooltipItem, data) {
//             var value = tooltipItem.value.replace(/\B(?=(\d{3})+(?!\d))/g, ",");
//             value += " registered patients";
//             return value;
//           },
//         },
//       }
//     }
//   }
// );
// const barChartNodes = document.querySelectorAll('[data-element="bar-chart"]');
// const tooltipNodes = document.querySelectorAll('[data-element="tooltip"]');
// barChartNodes.forEach(node => {
//   const tooltipId = node.getAttribute("data-id");
//   node.addEventListener("mouseenter", () => {
//     toggleTooltipVisibility(tooltipId);
//   });
//   node.addEventListener("mouseleave", () => {
//     toggleTooltipVisibility(tooltipId);
//   });
// });
// function toggleTooltipVisibility(tooltipId) {
//   const tooltipNode =
//     Array.from(tooltipNodes).find(node => node.getAttribute("data-id") === tooltipId);
//   tooltipNode.classList.toggle("hidden");
//   tooltipNode.classList.toggle("block");
// }
// // Nav
// let isUserDropdownVisible = false;
// const lightBackgroundToggle = ['bg-white', 'bg-grey-100'];
// const lightOpacityToggle = ['opacity-0', 'opacity-25'];
// const fullOpacityToggle = ['opacity-0', 'opacity-100'];
// const translateXFullToggle = ['translate-x-0', 'translate-x-full'];
// const pointerEventToggle = ['pointer-events-none', 'pointer-events-auto'];
// const translateYToggle = ['translate-y-0', 'translate-y-1'];
// const $body = document.getElementsByTagName('body')[0];
// const $menuButton = document.querySelector('[data-js="menu-button"]');
// const $sidebarButton = document.querySelector('[data-js="sidebar-button"]');
// const $overlay = document.querySelector('[data-js="overlay"]');
// const $sidebar = document.querySelector('[data-js="sidebar"]');
// const $accountButton = document.querySelector('[data-js="account-button"]');
// const $accountDropdown = document.querySelector('[data-js="account-dropdown"]');

// document.addEventListener('click', (event) => {
//   const wasAccountDropdownClicked = $accountDropdown.contains(event.target);
//   const wasAccountButtonClicked = $accountButton.contains(event.target);

//   if (!wasAccountDropdownClicked && !wasAccountButtonClicked && isUserDropdownVisible) {
//     toggleAccountDropdownPosition();
//   }
// });

// $menuButton.addEventListener('click', () => {
//   toggleMenuBackground();
//   toggleSidebarPosition();
// });

// $menuButton.addEventListener('touchstart', () => {
//   toggleMenuBackground();
// });

// $menuButton.addEventListener('touchend', () => {
//   toggleMenuBackground();
//   toggleSidebarPosition();
// });

// $overlay.addEventListener('touchend', () => {
//   toggleSidebarPosition();
// });

// $sidebarButton.addEventListener('click', () => {
//   toggleSidebarPosition();
// });

// $accountButton.addEventListener('click', () => {
//   toggleAccountDropdownPosition();
// });

// function toggleAccountDropdownPosition() {
//   if (isUserDropdownVisible) {
//     isUserDropdownVisible = false;
//   } else {
//     isUserDropdownVisible = true;
//   };

//   toggleClasses($accountDropdown, translateYToggle);
//   toggleClasses($accountDropdown, fullOpacityToggle);
// }

// function toggleMenuBackground() {
//   toggleClasses($menuButton, lightBackgroundToggle);
// }

// function toggleSidebarPosition() {
//   toggleClasses($overlay, lightOpacityToggle);
//   toggleClasses($overlay, pointerEventToggle);
//   toggleClasses($sidebar, translateXFullToggle);
// }

// function toggleClasses($element, cssClasses) {
//   cssClasses.forEach(cssClass => {
//     $element.classList.toggle(cssClass);
//   });
// }