const test = require("node:test");
const assert = require("node:assert/strict");
const {
  eligibilityEmailHash,
  normalizeEmail,
  subscriptionValues,
} = require("./subscription_logic");
const {closedTesterEmailHashes} = require("./closed_testers");

const productId = "mycarapp_subscription";
const now = new Date("2026-09-03T12:00:00Z").getTime();

function purchase(state, expiryTime, extra = {}) {
  return {
    subscriptionState: state,
    startTime: extra.startTime,
    lineItems: [{
      productId,
      expiryTime,
      offerDetails: {
        basePlanId: "premium_monthly",
        offerId: extra.offerId,
      },
      offerPhase: extra.offerPhase,
      autoRenewingPlan: {autoRenewEnabled: state === "SUBSCRIPTION_STATE_ACTIVE"},
    }],
  };
}

test("canceled subscription remains active until expiry", () => {
  const values = subscriptionValues(
      purchase("SUBSCRIPTION_STATE_CANCELED", "2026-09-10T12:00:00Z"),
      productId,
      now,
  );
  assert.equal(values.active, true);
  assert.equal(values.status, "canceled");
});

test("expired subscription loses entitlement", () => {
  const values = subscriptionValues(
      purchase("SUBSCRIPTION_STATE_EXPIRED", "2026-09-01T12:00:00Z"),
      productId,
      now,
  );
  assert.equal(values.active, false);
});

test("purchase for another product is rejected", () => {
  assert.throws(
      () => subscriptionValues(
          {subscriptionState: "SUBSCRIPTION_STATE_ACTIVE", lineItems: []},
          productId,
          now,
      ),
      {code: "wrong-product"},
  );
});

test("inFreeTrial true when offerPhase indicates free trial", () => {
  const values = subscriptionValues(
      purchase("SUBSCRIPTION_STATE_ACTIVE", "2026-09-10T12:00:00Z", {
        offerPhase: {freeTrial: {}},
      }),
      productId,
      now,
  );
  assert.equal(values.inFreeTrial, true);
});

test("inFreeTrial false when offerPhase indicates a paid phase", () => {
  const values = subscriptionValues(
      purchase("SUBSCRIPTION_STATE_ACTIVE", "2026-09-10T12:00:00Z", {
        offerId: "yearly-7daysfree",
        offerPhase: {basePrice: {}},
        startTime: "2026-09-01T12:00:00Z",
      }),
      productId,
      now,
  );
  assert.equal(values.inFreeTrial, false);
});

test("inFreeTrial falls back to date when offerPhase is missing", () => {
  const values = subscriptionValues(
      purchase("SUBSCRIPTION_STATE_ACTIVE", "2026-09-10T12:00:00Z", {
        offerId: "yearly-7daysfree",
        startTime: "2026-09-01T12:00:00Z",
      }),
      productId,
      now,
  );
  assert.equal(values.inFreeTrial, true);
});

test("inFreeTrial fallback expires after 7 days without offerPhase", () => {
  const values = subscriptionValues(
      purchase("SUBSCRIPTION_STATE_ACTIVE", "2026-09-20T12:00:00Z", {
        offerId: "yearly-7daysfree",
        startTime: "2026-08-01T12:00:00Z",
      }),
      productId,
      now,
  );
  assert.equal(values.inFreeTrial, false);
});

test("inFreeTrial fallback ignores other offers without offerPhase", () => {
  const values = subscriptionValues(
      purchase("SUBSCRIPTION_STATE_ACTIVE", "2026-09-10T12:00:00Z", {
        offerId: "referral-yr-30",
        startTime: "2026-09-01T12:00:00Z",
      }),
      productId,
      now,
  );
  assert.equal(values.inFreeTrial, false);
});

test("closed tester emails are normalized before hashing", () => {
  assert.equal(normalizeEmail(" User\\@Gmail.COM "), "user@gmail.com");
  assert.equal(
      eligibilityEmailHash("User@gmail.com"),
      eligibilityEmailHash(" user\\@GMAIL.COM "),
  );
});

test("frozen closed tester list has 28 unique hashes", () => {
  assert.equal(closedTesterEmailHashes.size, 28);
});
