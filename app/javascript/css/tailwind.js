module.exports = {
  purge: [],
  theme: {
    extend: {
      transitionTimingFunction: {
        'cubic': 'cubic-bezier(0.785, 0.135, 0.15, 0.86)',
      },
      transitionDuration: {
        '250': '250ms',
        '350': '350ms',
      },
      inset: {
        '-1': '-1px',
        '1': '1px',
        '2': '2px',
        '3': '3px',
        '4': '4px',
        '8': '8px',
        '13': '13px',
        '16': '16px',
      },
      flexGrow: {
        '2': '2',
      },
      borderWidth: {
        '3': '3px',
      },
      height: {
        '96': '24rem',
      },
    },
    fontFamily: {
      'roboto': ['Roboto', 'Helvetica', 'Arial', 'sans-serif']
    },
    colors: {
      blue: {
        '100': '#e0f0ff',
        '200': '#0075eb',
        '300': '#0c3966',
        '400': '#0a2e52',
      },
      red: {
        '100': '#ffd6dd',
        '200': '#ff3355',
        '300': '#b81631',
      },
      purple: {
        '100': "#f3e1fc",
        '200': "#9d4ac7",
      },
      yellow: {
        '100': '#fff8e0',
        '200': '#ffc800',
        '300': '#e0b000',
      },
      green: {
        '100': '#007a31',
        '200': '#00b849',
        '300': '#5cff9d',
        '400': '#e0ffed',
      },
      grey: {
        '100': '#f0f2f5',
        '200': '#dadde0',
        '300': '#adb2b8',
        '400': '#6c737a',
        '500': '#2f363d',
      },
      white: '#ffffff',
      black: '#000000'
    },
  },
  variants: {},
  plugins: [],
}