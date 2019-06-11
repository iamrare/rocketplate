const pg = require('pg').native;
const bluebird = require('bluebird');
const sqornPg = require('@sqorn/pg');

// Postgres
bluebird.config({ longStackTraces: true });

const pgWrite = new pg.Pool({
  connectionString: process.env.PG_WRITE_URL,
  Promise: bluebird
});

pgWrite.on('error', err => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

exports.pgWrite = pgWrite;

const pgRead = new pg.Pool({
  connectionString: process.env.PG_READ_URL,
  Promise: bluebird
});

pgRead.on('error', err => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

exports.pgRead = pgRead;

// sqorn

exports.rsq = sqornPg({ pg, pool: pgRead });
exports.wsq = sqornPg({ pg, pool: pgWrite });
