const formatPercentage = (number) => {
    return (number || 0) + "%";
};

const formatNumberWithCommas = (value) => {
    if (value === undefined) {
        return 0;
    }

    if (numeral(value) !== undefined) {
        return numeral(value).format("0,0");
    }

    return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
};

const formatValue = (format, value) => {
    switch (format) {
        case "percentage":
           return formatPercentage(value)
        case "numberWithCommas":
            return formatNumberWithCommas(value)
        default:
            return value;
    }
}

window.addEventListener("load", () => {
    const chartContainers = document.querySelectorAll("[data-chart-container]");
    chartContainers.forEach((container) => {
        const charts = container.querySelectorAll("[data-render-chart]");
        const dataKeyNodes = container.querySelectorAll("[data-key]");
        const mostRecentPeriod = container.getAttribute("data-period");

        charts.forEach((chart) => {
            const type = chart.dataset.chartType;
            const data = JSON.parse(chart.dataset.chartData);
            console.log(data);

            // The latest version of Chart.js has an option to use only a specific
            // key from a map of data. Unfortunately this is not available in the
            // version we are currently using. This is a workaround that mimics the
            // behaviour from the latest version of Chart.js
            const datasetOptions = JSON.parse(chart.dataset.chartDatasetOptions);
            datasetOptions.datasets.forEach(dataset => {
                const parsingKey = dataset["parsing"]["yAxisKey"];
                dataset.data = Object.entries(data)
                    .map(([period, values]) => values[parsingKey]);
            })

            const options = JSON.parse(chart.dataset.chartOptions);
            const config = {
                type: type,
                data: datasetOptions,
                options: options
            };

            const updateDataNodes = (period) => {
                dataKeyNodes.forEach(dataNode => {
                    const format = dataNode.dataset.format;
                    const key = dataNode.dataset.key;

                    dataNode.innerHTML = formatValue(format, data[period][key]);
                })
            }

            Object.assign(options.tooltips, {
                custom: (tooltip) => {
                    const hoveredDatapoint = tooltip.dataPoints;
                    if (hoveredDatapoint) {
                        updateDataNodes(hoveredDatapoint[0].label);
                    } else {
                        updateDataNodes(mostRecentPeriod)
                    }

                }
            });
            new Chart(chart.getContext("2d"), config);
            updateDataNodes(mostRecentPeriod)
        });
    });
})