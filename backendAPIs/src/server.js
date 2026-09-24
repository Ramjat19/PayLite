const express = require('express');
const accountRoutes = require('./routes/account.routes');
const authRoutes = require('./routes/auth.routes');
const paymentRoutes = require('./routes/payment.routes');
const vpaRoutes = require('./routes/vpa.routes');
const collectRoutes = require('./routes/collect.routes');
const { allowCors } = require('./middleware/cors');
const {
  assignTraceId,
  errorHandler,
  notFound,
} = require('./middleware/error-handler');

const app = express();
app.disable('x-powered-by');
app.use(assignTraceId);
app.use(allowCors);
app.use(express.json({ limit: '16kb' }));

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});
app.use('/auth', authRoutes);
app.use('/accounts', accountRoutes);
app.use('/vpa', vpaRoutes);
app.use('/payments', paymentRoutes);
app.use('/collect-requests', collectRoutes);
app.use(notFound);
app.use(errorHandler);

if (require.main === module) {
  const port = Number(process.env.PORT || 3000);
  app.listen(port, () => {
    console.log(`PayLite mock API listening on http://localhost:${port}`);
  });
}

module.exports = { app };
