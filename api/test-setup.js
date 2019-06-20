require('dotenv-safe').config();

const axios = require('axios');
const axiosLogger = require('axios-logger');

global.testAxios = axios.create({
  baseURL: `http://localhost:3001`,
  timeout: 3000,
  headers: {
    'x-workspace-id': 1,
    'x-token': 't'
  },
  // Don't throw 400 errors
  validateStatus: status => status >= 200 && status < 500
});

global.testAxios.interceptors.response.use(
  axiosLogger.responseLogger,
  axiosLogger.errorLogger
);
