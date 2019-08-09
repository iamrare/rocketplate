require('dotenv-safe').config({ allowEmptyValues: true });

const axios = require('axios');
const axiosRetry = require('axios-retry');
const testListen = require('test-listen');

const server = require('./src/index.js');

global.testAxiosCreate = async () => {
  const baseURL = await testListen(server());

  const theAxios = axios.create({
    baseURL,
    timeout: 3000,
    headers: {
      authorization: 'test-workspace/t'
    },
    // Don't throw 400 errors
    validateStatus: status => status >= 200 && status < 500
  });

  axiosRetry(theAxios, { retries: 3 });

  return theAxios;
};
