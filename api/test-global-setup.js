const axios = require('axios');

// Make sure server is alive before starting tests
const MAX_REQUESTS = 20;
module.exports = async () => {
  let serverReady = false;
  for (let i = 0; i <= MAX_REQUESTS; i++) {
    try {
      await axios('http://localhost:3001');
      serverReady = true;
      break;
    } catch (err) {
      await new Promise(resolve => setTimeout(resolve, 100));
      continue;
    }
  }

  if (!serverReady) throw new Error(`Server never became ready.`);
};
