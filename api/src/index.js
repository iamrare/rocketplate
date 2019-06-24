require('dotenv-safe').config();

const path = require('path');
const url = require('url');

const _ = require('lodash/fp');
const micro = require('micro');
const compress = require('micro-compress');
const cors = require('micro-cors');
const microOpenApi = require('micro-open-api');
const morgan = require('micro-morgan');

const handler = _.compose(
  [
    compress,
    morgan('tiny', {
      skip: (req, res) => {
        if (req.method.toUpperCase() === 'OPTIONS') return true;

        const parsed = url.parse(req.url);
        if (parsed.path === '/') return true;
        if (res.statusCode < 400) return true;

        return false;
      }
    }),
    process.env.NODE_ENV !== 'production' &&
      cors({
        origin: 'http://localhost:3000'
      }),
    microOpenApi(
      `
openapi: "3.0.0"
info:
  version: 1.0.0
  title: Rocketplate API
  description: The API for Rocketplate
  contact:
    name: Tucker Connelly
    email: web@tuckerconnelly.com
    url: https://tuckerconnelly.com
servers:
  - url: https://boilerplate.technology/api/v1
components:
  securitySchemes:
    - type: apiKey
      name: authorization
      in: header
  securityRequirementss:
    apiKey: []
`,
      path.join(__dirname, './modules')
    )
  ].filter(fn => fn)
)((req, res) => {
  if (req.method === 'OPTIONS') return { ok: true };

  micro.send(res, 404, { ok: false, errors: { general: 'Not found' } });
});

micro(handler).listen(process.env.PORT || 3001);
