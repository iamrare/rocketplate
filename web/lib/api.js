import axios from 'axios';
import axiosRetry from 'axios-retry';
import merge from 'lodash/merge';
import { parse as cookieParse } from 'cookie';

// axios instead of fetch for timeouts, retries, and cancellations

const apiAxios = axios.create({
  baseURL: process.env.API_URL,
  timeout: 3000,
  withCredentials: true
});

axiosRetry(apiAxios, { retries: 3 });

export default function api(config) {
  const cookie = config.req
    ? config.req.headers.cookie
    : typeof window !== 'undefined' && window.document.cookie;

  delete config.req;

  const _headers = cookie
    ? merge(config.headers || {}, {
        // Sending authorization instead of cookie because cookie is a forbidden header
        // https://fetch.spec.whatwg.org/#forbidden-header-name
        authorization: `Token ${cookieParse(cookie)['token']}`
      })
    : config.headers;

  return apiAxios(merge(config, { headers: _headers }));
}
