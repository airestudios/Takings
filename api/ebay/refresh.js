const {
  EBAY_SCOPE,
  requestBody,
  requireMethod,
  sendError,
  sendJson,
  tokenRequest,
} = require('../../server/ebay');

module.exports = async function handler(request, response) {
  if (!requireMethod(request, response, 'POST')) return;
  try {
    const refreshToken = String(requestBody(request).refreshToken || '');
    if (!refreshToken) {
      return sendJson(response, 400, { error: 'Missing refresh token' });
    }
    const tokens = await tokenRequest({
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
      scope: EBAY_SCOPE,
    });
    return sendJson(response, 200, tokens);
  } catch (error) {
    return sendError(response, error);
  }
};
