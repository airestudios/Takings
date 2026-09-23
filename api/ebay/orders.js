const {
  EBAY_API,
  amountMinor,
  bearerToken,
  requireMethod,
  sendError,
  sendJson,
} = require('../../server/ebay');

function refundMinor(lineItem) {
  return (lineItem.refunds || []).reduce(
    (total, refund) =>
      total + amountMinor(refund.refundAmount || refund.amount),
    0,
  );
}

function lineState(order, lineItem, sellingPriceMinor) {
  const cancelState = order.cancelStatus?.cancelState || '';
  if (cancelState && cancelState !== 'NONE_REQUESTED') return 'cancelled';
  const refunded = refundMinor(lineItem);
  if (refunded >= sellingPriceMinor && sellingPriceMinor > 0) return 'refunded';
  if (refunded > 0) return 'partiallyRefunded';
  return 'completed';
}

module.exports = async function handler(request, response) {
  if (!requireMethod(request, response, 'GET')) return;
  try {
    const token = bearerToken(request);
    const limit = Math.min(Math.max(Number(request.query.limit) || 50, 1), 200);
    const offset = Math.max(Number(request.query.offset) || 0, 0);
    const earliest = new Date(Date.now() - 89 * 24 * 60 * 60 * 1000);
    const requestedSince = new Date(String(request.query.since || ''));
    const since =
      Number.isNaN(requestedSince.getTime()) || requestedSince < earliest
        ? earliest
        : requestedSince;

    const url = new URL(`${EBAY_API}/sell/fulfillment/v1/order`);
    url.searchParams.set('limit', String(limit));
    url.searchParams.set('offset', String(offset));
    url.searchParams.set(
      'filter',
      `creationdate:[${since.toISOString()}..${new Date().toISOString()}]`,
    );

    const ebayResponse = await fetch(url, {
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: 'application/json',
        'X-EBAY-C-MARKETPLACE-ID': 'EBAY_GB',
      },
    });
    const body = await ebayResponse.json().catch(() => ({}));
    if (!ebayResponse.ok) {
      const error = new Error(
        body.errors?.[0]?.longMessage ||
          body.errors?.[0]?.message ||
          'eBay orders could not be retrieved.',
      );
      error.statusCode = ebayResponse.status;
      throw error;
    }

    const items = [];
    for (const order of body.orders || []) {
      for (const lineItem of order.lineItems || []) {
        const quantity = Math.max(Number(lineItem.quantity) || 1, 1);
        const sellingPriceMinor = amountMinor(lineItem.lineItemCost) * quantity;
        const title = String(lineItem.title || '').trim();
        if (!title || sellingPriceMinor <= 0) continue;
        items.push({
          externalOrderId: String(order.orderId || ''),
          externalListingId: String(
            lineItem.legacyItemId || lineItem.itemId || lineItem.sku || '',
          ),
          externalTransactionId: String(lineItem.lineItemId || ''),
          title,
          soldAt: order.creationDate,
          sellingPriceMinor,
          feeMinor: 0,
          postageMinor: 0,
          currencyCode: lineItem.lineItemCost?.currency || 'GBP',
          state: lineState(order, lineItem, sellingPriceMinor),
        });
      }
    }

    const total = Number(body.total) || 0;
    const nextOffset = offset + limit < total ? offset + limit : null;
    return sendJson(response, 200, { items, nextOffset });
  } catch (error) {
    return sendError(response, error);
  }
};
