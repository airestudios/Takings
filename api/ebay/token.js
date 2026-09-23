const {
  requestBody,
  requiredEnv,
  requireMethod,
  sendError,
  sendJson,
  tokenRequest,
} = require('../../server/ebay');

module.exports = async function handler(request, response) {
  if (!requireMethod(request, response, 'POST')) return;
  try {
    const code = String(requestBody(request).code || '');
    if (!code) return sendJson(response, 400, { error: 'Missing code' });
    const tokens = await tokenRequest({
      grant_type: 'authorization_code',
      code,
      redirect_uri: requiredEnv('EBAY_RUNAME'),
    });
    return sendJson(response, 200, tokens);
  } catch (error) {
    return sendError(response, error);
  }
};
