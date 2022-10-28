// ----------------------------
// Segment Functions

// Create a dashed line for the last segment of dynamic charts
const dynamicChartSegementDashed = (ctx, numberOfXAxisTicks) => {
  // console.log("ctx", ctx);
  // console.log(numberOfXAxisTicks);
  return ctx.p0DataIndex === numberOfXAxisTicks - 2 ? [4, 3] : undefined;
};

// Create a different line color for segments that go down
const down = (ctx, color) =>
  ctx.p0.parsed.y > ctx.p1.parsed.y ? color : undefined;

// Bar chart 'Treatment Status' design updates
//   borderRadius: { bottomLeft: 4, bottomRight: 4 },
//   borderSkipped: false,
//   categoryPercentage: 0.84,
//   barPercentage: 1,
// barThickness: "flex",
// minBarLength: 4,

//// different hover colour on ticks --- NOT WORKING

function changeHoverTickColor() {
  // trying highlight x index
  console.log(activePoint.index);
  console.log(chart.scales.x.ticks.length);
  console.log(chart.scales.x.ticks[activePoint.index]);
  const tickColors = [];
  for (let index = 0; index < chart.scales.x.ticks.length; index++) {
    if (index === activePoint.index) {
      tickColors.push("#000000");
    } else {
      tickColors.push("#f55");
    }
  }
  console.log(tickColors);
  console.log("chart options", chart.config.options.scales.x);
  chart.config.options.scales.x.ticks.color = "#f55";
  console.log(
    "chart options edited",
    chart.config._config.options.scales.x.ticks
  );
}

// onHover: function (context) {
//   if (context.chart.tooltip._active && chart.tooltip._active.length) {
//     const activePoint = chart.tooltip._active[0];

//     console.log("context Hover:", context);
//     // trying highlight x index
//     console.log(activePoint.index);
//     console.log(chart.scales.x.ticks.length);
//     console.log(chart.scales.x.ticks[activePoint.index]);
//     const tickColors = [];
//     for (let index = 0; index < chart.scales.x.ticks.length; index++) {
//       if (index === activePoint.index) {
//         tickColors.push("#000000");
//       } else {
//         tickColors.push("#f55");
//       }
//     }
//     console.log(tickColors);
//     console.log("chart options", chart.config.options.scales.x);
//     chart.config.options.scales.x.ticks.color = "#f55";
//     console.log(
//       "chart options edited",
//       chart.config._config.options.scales.x.ticks
//     );
// }
// },
