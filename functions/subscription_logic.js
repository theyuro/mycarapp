const {createHash} = require("node:crypto");

function normalizeEmail(value) {
  return String(value || "").trim().replace(/\\@/g, "@").toLowerCase();
}

function eligibilityEmailHash(value) {
  return createHash("sha256").update(normalizeEmail(value)).digest("hex");
}

function subscriptionValues(subscription, productId, now = Date.now()) {
  const lineItems = (subscription.lineItems || [])
      .filter((item) => item.productId === productId);
  if (lineItems.length === 0) {
    const error = new Error("A compra não pertence ao produto esperado.");
    error.code = "wrong-product";
    throw error;
  }

  const expiryTimes = lineItems.map((item) => item.expiryTime)
      .filter(Boolean).map((value) => new Date(value));
  const expiry = expiryTimes.sort((a, b) => b - a)[0] || null;
  const lineItem = lineItems.reduce((latest, item) => {
    if (!latest) return item;
    return new Date(item.expiryTime || 0) > new Date(latest.expiryTime || 0) ?
      item : latest;
  }, null) || {};
  const state = subscription.subscriptionState || "SUBSCRIPTION_STATE_UNSPECIFIED";
  const activeStates = new Set([
    "SUBSCRIPTION_STATE_ACTIVE",
    "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
    "SUBSCRIPTION_STATE_CANCELED",
  ]);
  const status = {
    SUBSCRIPTION_STATE_ACTIVE: "active",
    SUBSCRIPTION_STATE_IN_GRACE_PERIOD: "grace_period",
    SUBSCRIPTION_STATE_CANCELED: "canceled",
    SUBSCRIPTION_STATE_ON_HOLD: "past_due",
    SUBSCRIPTION_STATE_EXPIRED: "expired",
    SUBSCRIPTION_STATE_PAUSED: "paused",
    SUBSCRIPTION_STATE_PENDING: "pending",
  }[state] || "unknown";

  return {
    active: Boolean(activeStates.has(state) && expiry && expiry.getTime() > now),
    state,
    status,
    accessType: "subscription",
    source: "google_play",
    productId: lineItem.productId || productId,
    basePlanId: lineItem.offerDetails?.basePlanId || null,
    planId: lineItem.offerDetails?.basePlanId || null,
    offerId: lineItem.offerDetails?.offerId || null,
    expiryTime: expiry,
    expiresAt: expiry,
    autoRenewing: Boolean(lineItem.autoRenewingPlan?.autoRenewEnabled),
  };
}

module.exports = {eligibilityEmailHash, normalizeEmail, subscriptionValues};
