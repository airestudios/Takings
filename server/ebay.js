const EBAY_API = 'https://api.ebay.com';
const EBAY_AUTH = 'https://auth.ebay.com/oauth2/authorize';
const EBAY_SCOPE =
  'https://api.ebay.com/oauth/api_scope/sell.fulfillment.readonly';

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) throw new Error(`${name} is not configured`);
  return value;
}

function sendJson(response, statusCode, payload) {
  response.setHeader('Content-Type', 'application/json; charset=utf-8');
  response.setHeader('Cache-Control', 'no-store');
  return response.status(statusCode).json(payload);
}

function sendError(response, error) {
  const statusCode = Number(error?.statusCode) || 500;
  const message =
    statusCode >= 500 ? 'The eBay connection service is unavailable.' : error.message;
  return sendJson(response, statusCode, { error: message });
}

function requireMethod(request, response, method) {
  if (request.method === method) return true;
  response.setHeader('Allow', method);
  sendJson(response, 405, { error: 'Method not allowed' });
  return false;
}

function requestBody(request) {
  if (request.body && typeof request.body === 'object') return request.body;
  if (typeof request.body === 'string') return JSON.parse(request.body);
  return {};
}

function bearerToken(request) {
  const authorization = request.headers.authorization || '';
  const match = authorization.match(/^Bearer\\s+(.+)$/i);
  if (!match) {
    const error = new Error('Missing eBay access token');
    error.statusCode = 401;
    throw error;
  }
  return match[1];
}

async function tokenRequest(parameters) {
  const clientId = requiredEnv('EBAY_CLIENT_ID');
  const clientSecret = requiredEnv('EBAY_CLIENT_SECRET');
  const response = await fetch(`${EBAY_API}/identity/v1/oauth2/token`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${Buffer.from(`${clientId}:${clientSecret}`).toString('base64')}`,
      'Content-Type': 'application/x-www-form-urlencoded',
      Accept: 'application/json',
    },
    body: new URLSearchParams(parameters),
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    const error = new Error(
      body.error_description || body.error || 'eBay rejected the token request.',
    );
    error.statusCode = response.status;
    throw error;
  }
  return body;
}

function amountMinor(amount) {
  const value = Number(amount?.value ?? 0);
  return Number.isFinite(value) ? Math.round(value * 100) : 0;
}

module.exports = {
  EBAY_API,
  EBAY_AUTH,
  EBAY_SCOPE,
  amountMinor,
  bearerToken,
  requestBody,
  requiredEnv,
  requireMethod,
  sendError,
  sendJson,
  tokenRequest,
};
