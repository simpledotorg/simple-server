// const intersectDataFlow = {
//   id: "intersectionLine",
//   beforeDraw: (chart) => {
//     if (chart.tooltip._active && chart.tooltip._active.length) {
//       const ctx = chart.ctx;
//       ctx.save();
//       console.log(chart);
//       const activePoint = chart.tooltip._active[0];
//       console.log(activePoint);
//       const chartArea = chart.chartArea;
//       console.log(chartArea);
//       ctx.beginPath();
//       // ctx.setLineDash([5,7])
//       ctx.moveTo(activePoint._model.x, chartArea.top);
//       ctx.lineTo(activePoint._model.x, chartArea.bottom);
//       ctx.lineWidth = 2;
//       ctx.strokeStyle = "rgba(0,0,0, 0.1)";
//       ctx.stroke();
//       ctx.restore();
//     }
//   },
// };
// controlledGraphConfig.plugins = [intersectDataFlow];

// // try x to prevent hover issue with being closer to larger node
// .options.hover = {
//       mode: "nearest",
//       intersect: false,
//     };

// toolTip: {
//   mode: "index",
//   intersect: false,
// },
// hover: {
//   mode: "index",
//   intersect: false,
// },

// code for additional line colours
// // any extra points after the highest point - hidden behind datapoints (including bars in bar charts)
// if (chart.tooltip._active && chart.tooltip._active.length > 1) {
//   for (let index = 1; index < chart.tooltip._active.length; index++) {
//     const activePointLoop = chart.tooltip._active[index];
//     ctx.beginPath();
//     ctx.moveTo(activePointLoop._model.x, activePointLoop._model.y + 6);
//     ctx.lineTo(activePointLoop._model.x, chartArea.bottom);
//     ctx.lineWidth = 2;
//     ctx.strokeStyle = activePointLoop._model.borderColor;
//     ctx.stroke();
//     ctx.restore();
//   }
// }
