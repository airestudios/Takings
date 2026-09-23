const {
  EBAY_AUTH,
  EBAY_SCOPE,
  requiredEnv,
  requireMethod,
  sendError,
  sendJson,
} = require('../../server/ebay');

module.exports = async function handler(request, response) {
  if (!requireMethod(request, response, 'GET')) return;
  try {
    const state = String(request.query.state || '');
    if (!state) return sendJson(response, 400, { error: 'Missing state' });

    const authorization = new URL(EBAY_AUTH);
    authorization.searchParams.set('client_id', requiredEnv('EBAY_CLIENT_ID'));
    authorization.searchParams.set('redirect_uri', requiredEnv('EBAY_RUNAME'));
    authorization.searchParams.set('response_type', 'code');
    authorization.searchParams.set('scope', EBAY_SCOPE);
    authorization.searchParams.set('state', state);

    response.setHeader('Cache-Control', 'no-store');
    return response.redirect(302, authorization.toString());
  } catch (error) {
    return sendError(response, error);
  }
};
