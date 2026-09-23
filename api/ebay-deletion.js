const crypto = require('crypto');

function sendJson(response, statusCode, payload) {
  response.setHeader('Content-Type', 'application/json; charset=utf-8');
  response.setHeader('Cache-Control', 'no-store');
  return response.status(statusCode).json(payload);
}

module.exports = async function handler(request, response) {
  if (request.method === 'GET') {
    const challengeCode = request.query.challenge_code;
    const verificationToken = process.env.EBAY_DELETION_VERIFICATION_TOKEN;
    const forwardedHost = request.headers['x-forwarded-host'];
    const host = forwardedHost || request.headers.host;
    const forwardedProto = request.headers['x-forwarded-proto'];
    const protocol = forwardedProto || 'https';
    const pathname = new URL(request.url, `${protocol}://${host}`).pathname;
    const endpoint =
      process.env.EBAY_DELETION_ENDPOINT ||
      (host ? `${protocol}://${host}${pathname}` : null);

    if (!challengeCode) {
      return sendJson(response, 400, { error: 'Missing challenge_code' });
    }

    if (!verificationToken || !endpoint) {
      return sendJson(response, 500, { error: 'Endpoint is not configured' });
    }

    const challengeResponse = crypto
      .createHash('sha256')
      .update(challengeCode, 'utf8')
      .update(verificationToken, 'utf8')
      .update(endpoint, 'utf8')
      .digest('hex');

    return sendJson(response, 200, { challengeResponse });
  }

  if (request.method === 'POST') {
    // Takings currently keeps imported sales on the user's device and does not
    // persist eBay marketplace account data in this endpoint. Acknowledge the
    // notification without logging its user identifiers. If server-side eBay
    // storage is added later, deletion/revocation must be performed here.
    const topic = request.body?.metadata?.topic;
    if (topic !== 'MARKETPLACE_ACCOUNT_DELETION') {
      return sendJson(response, 400, { error: 'Unsupported notification' });
    }

    return response.status(204).end();
  }

  response.setHeader('Allow', 'GET, POST');
  return sendJson(response, 405, { error: 'Method not allowed' });
};
