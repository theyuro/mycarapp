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

function purchase(state, expiryTime) {
  return {
    subscriptionState: state,
    lineItems: [{
      productId,
      expiryTime,
      offerDetails: {basePlanId: "premium_monthly"},
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
