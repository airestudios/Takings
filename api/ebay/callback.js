const { requireMethod } = require('../../server/ebay');

module.exports = async function handler(request, response) {
  if (!requireMethod(request, response, 'GET')) return;
  const callback = new URL('takings://oauth/ebay');
  for (const name of ['code', 'state', 'error', 'error_description']) {
    const value = request.query[name];
    if (typeof value === 'string' && value) callback.searchParams.set(name, value);
  }
  response.setHeader('Cache-Control', 'no-store');
  return response.redirect(302, callback.toString());
};
