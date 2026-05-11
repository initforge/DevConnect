const { startServer, pool } = require('./app');

const server = startServer();

process.on('SIGINT', () => {
  pool.end(() => server.close(() => process.exit(0)));
});
