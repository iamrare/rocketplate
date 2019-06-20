require('dotenv-safe').config();

const _ = require('lodash/fp');
const micro = require('micro');
const fsRouter = require('fs-router');
const compress = require('micro-compress');
const visualize = require('micro-visualize');

const match = fsRouter(__dirname + '/routes');

const handler = _.compose(
  [process.env.NODE_ENV !== 'production' && visualize, compress].filter(
    fn => fn
  )
)((req, res, ...args) => {
  const matched = match(req);
  if (matched) return matched(req, res, ...args);
  micro.send(res, 404, { ok: false, errors: { general: 'Not found' } });
});

micro(handler).listen(process.env.PORT || 3001);
