const {createHash} = require("node:crypto");
const {getApps, initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {setGlobalOptions} = require("firebase-functions/v2/options");
const {GoogleAuth} = require("google-auth-library");
const {
  eligibilityEmailHash,
  normalizeEmail,
  subscriptionValues: deriveSubscriptionValues,
} = require("./subscription_logic");
const {closedTesterEmailHashes} = require("./closed_testers");

if (getApps().length === 0) initializeApp();

const db = getFirestore();
const region = "southamerica-east1";
const packageName = "com.gilesdesenvolvimento.mycarapp";
const subscriptionProductId = "mycarapp_subscription";
const adminEmail = "giles.softwares@gmail.com";
const defaultPremiumFreeUntil = new Date("2026-08-31T03:00:00.000Z");

setGlobalOptions({region, maxInstances: 10});

function requireAuth(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Entre na sua conta para continuar.");
  }
  return request.auth.uid;
}

function isAdmin(request) {
  return String(request.auth?.token?.email || "").toLowerCase() === adminEmail;
}

function requireAdmin(request) {
  requireAuth(request);
  if (!isAdmin(request)) {
    throw new HttpsError("permission-denied", "Acesso exclusivo do administrador.");
  }
}

function referralCodeFor(uid) {
  return createHash("sha256").update(`mycarapp:${uid}`).digest("hex")
      .slice(0, 10).toUpperCase();
}

async function ensureProfile(uid, token = {}) {
  const userRef = db.collection("users").doc(uid);
  const referralCode = referralCodeFor(uid);
  const codeRef = db.collection("referralCodes").doc(referralCode);
  const normalizedEmail = normalizeEmail(token.email);
  const testerRef = normalizedEmail ? db.collection("testerEligibilityEmails")
      .doc(eligibilityEmailHash(normalizedEmail)) : null;

  await db.runTransaction(async (transaction) => {
    const [snapshot, testerSnapshot] = await Promise.all([
      transaction.get(userRef),
      testerRef ? transaction.get(testerRef) : Promise.resolve(null),
    ]);
    const frozenTesterEligible = normalizedEmail &&
      closedTesterEmailHashes.has(eligibilityEmailHash(normalizedEmail));
    const testerEligible = Boolean(frozenTesterEligible ||
      (testerSnapshot?.exists === true && testerSnapshot.data().active !== false));
    if (!snapshot.exists) {
      transaction.create(userRef, {
        email: token.email || null,
        displayName: token.name || null,
        referralCode,
        testerEligible,
        testerEligibilitySource: testerEligible ? "closed_test" : null,
        referralRewardCredits: 0,
        isAdmin: String(token.email || "").toLowerCase() === adminEmail,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    } else {
      transaction.set(userRef, {
        email: token.email || snapshot.data().email || null,
        displayName: token.name || snapshot.data().displayName || null,
        isAdmin: String(token.email || "").toLowerCase() === adminEmail,
        testerEligible: snapshot.data().testerEligible === true || testerEligible,
        testerEligibilitySource: testerEligible ? "closed_test" :
          snapshot.data().testerEligibilitySource || null,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
    }
    transaction.set(codeRef, {ownerUid: uid, createdAt: FieldValue.serverTimestamp()},
        {merge: true});
  });

  return referralCode;
}

exports.ensureUserProfile = onCall({enforceAppCheck: false}, async (request) => {
  const uid = requireAuth(request);
  const referralCode = await ensureProfile(uid, request.auth.token);
  return {referralCode};
});

exports.getAppAccess = onCall({enforceAppCheck: false}, async (request) => {
  const snapshot = await db.collection("appConfig").doc("public").get();
  const configured = snapshot.data()?.premiumFreeUntil?.toDate?.() ||
    defaultPremiumFreeUntil;
  return {
    premiumFreeUntil: configured.toISOString(),
    freePremiumActive: configured.getTime() > Date.now(),
    // Build mínimo do app: abaixo dele o app bloqueia e pede atualização.
    minimumBuild: Number(snapshot.data()?.minimumBuild || 0),
    isAdmin: isAdmin(request),
  };
});

exports.updatePremiumFreeUntil = onCall(
    {enforceAppCheck: false}, async (request) => {
      requireAdmin(request);
      const value = new Date(String(request.data?.until || ""));
      if (Number.isNaN(value.getTime())) {
        throw new HttpsError("invalid-argument", "Informe uma data válida.");
      }
      await db.collection("appConfig").doc("public").set({
        premiumFreeUntil: value,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: request.auth.uid,
      }, {merge: true});
      return {premiumFreeUntil: value.toISOString()};
    });

exports.importClosedTesters = onCall(
    {enforceAppCheck: true, timeoutSeconds: 60}, async (request) => {
      requireAdmin(request);
      const rawEmails = Array.isArray(request.data?.emails) ?
        request.data.emails : [];
      const emails = [...new Set(rawEmails.map(normalizeEmail).filter(Boolean))];
      const invalidEmails = emails.filter((email) =>
        !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email));
      if (emails.length === 0 || emails.length > 400 || invalidEmails.length > 0) {
        throw new HttpsError(
            "invalid-argument",
            "Envie entre 1 e 400 endereços de e-mail válidos.",
        );
      }

      const resolvedUsers = await Promise.all(emails.map(async (email) => {
        try {
          const user = await getAuth().getUserByEmail(email);
          return {email, uid: user.uid};
        } catch (error) {
          if (error.code === "auth/user-not-found") return {email, uid: null};
          throw error;
        }
      }));

      const batch = db.batch();
      const importedAt = FieldValue.serverTimestamp();
      for (const item of resolvedUsers) {
        const emailHash = eligibilityEmailHash(item.email);
        batch.set(db.collection("testerEligibilityEmails").doc(emailHash), {
          emailHash,
          active: true,
          source: "closed_test",
          importedAt,
          importedBy: request.auth.uid,
        }, {merge: true});
        if (item.uid) {
          batch.set(db.collection("users").doc(item.uid), {
            testerEligible: true,
            testerEligibilitySource: "closed_test",
            testerEligibilityUpdatedAt: importedAt,
            updatedAt: importedAt,
          }, {merge: true});
        }
      }

      const importRef = db.collection("testerEligibilityImports").doc();
      const unresolvedEmails = resolvedUsers
          .filter((item) => !item.uid).map((item) => item.email);
      batch.set(importRef, {
        total: emails.length,
        matchedUsers: emails.length - unresolvedEmails.length,
        pendingUsers: unresolvedEmails.length,
        emailHashes: emails.map(eligibilityEmailHash),
        importedAt,
        importedBy: request.auth.uid,
      });
      await batch.commit();

      return {
        importId: importRef.id,
        total: emails.length,
        matchedUsers: emails.length - unresolvedEmails.length,
        pendingUsers: unresolvedEmails.length,
        unresolvedEmails,
      };
    });

exports.createSupportTicket = onCall(
    {enforceAppCheck: false}, async (request) => {
      const uid = requireAuth(request);
      await ensureProfile(uid, request.auth.token);
      const type = String(request.data?.type || "feedback");
      const subject = String(request.data?.subject || "").trim();
      const message = String(request.data?.message || "").trim();
      if (!["feedback", "bug"].includes(type) || subject.length < 3 ||
          subject.length > 120 || message.length < 10 || message.length > 5000) {
        throw new HttpsError("invalid-argument", "Revise o assunto e a descrição.");
      }
      const ticketRef = db.collection("supportTickets").doc();
      const ticketNumber = ticketRef.id.slice(0, 8).toUpperCase();
      await ticketRef.set({
        ticketNumber,
        uid,
        email: request.auth.token.email || null,
        displayName: request.auth.token.name || null,
        type,
        subject,
        message,
        appVersion: String(request.data?.appVersion || ""),
        status: "open",
        adminResponse: null,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      // Compatível com a extensão oficial Trigger Email do Firebase.
      await db.collection("mail").add({
        to: [adminEmail],
        message: {
          subject: `[MyCarApp ${ticketNumber}] ${type === "bug" ? "Bug" : "Feedback"}: ${subject}`,
          text: `${message}\n\nUsuário: ${request.auth.token.email || uid}\nVersão: ${String(request.data?.appVersion || "não informada")}`,
        },
        ticketId: ticketRef.id,
        createdAt: FieldValue.serverTimestamp(),
      });
      return {id: ticketRef.id, ticketNumber};
    });

function ticketJson(document) {
  const data = document.data();
  return {
    id: document.id,
    ...data,
    createdAt: data.createdAt?.toDate?.().toISOString() || null,
    updatedAt: data.updatedAt?.toDate?.().toISOString() || null,
  };
}

exports.listSupportTickets = onCall(
    {enforceAppCheck: false}, async (request) => {
      const uid = requireAuth(request);
      const snapshot = isAdmin(request) ?
        await db.collection("supportTickets").limit(200).get() :
        await db.collection("supportTickets").where("uid", "==", uid).limit(100).get();
      const tickets = snapshot.docs.map(ticketJson)
          .sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)));
      return {tickets, isAdmin: isAdmin(request)};
    });

exports.updateSupportTicket = onCall(
    {enforceAppCheck: false}, async (request) => {
      requireAdmin(request);
      const id = String(request.data?.id || "");
      const status = String(request.data?.status || "open");
      const adminResponse = String(request.data?.adminResponse || "").trim();
      if (!id || !["open", "in_progress", "resolved"].includes(status) ||
          adminResponse.length > 5000) {
        throw new HttpsError("invalid-argument", "Atualização inválida.");
      }
      await db.collection("supportTickets").doc(id).update({
        status,
        adminResponse: adminResponse || null,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: request.auth.uid,
      });
      return {updated: true};
    });

exports.applyReferralCode = onCall({enforceAppCheck: false}, async (request) => {
  const uid = requireAuth(request);
  const code = String(request.data?.code || "").trim().toUpperCase();
  if (!/^[A-F0-9]{10}$/.test(code)) {
    throw new HttpsError("invalid-argument", "Código de indicação inválido.");
  }

  await ensureProfile(uid, request.auth.token);
  const userRef = db.collection("users").doc(uid);
  const codeRef = db.collection("referralCodes").doc(code);
  const referralRef = db.collection("referrals").doc(uid);

  await db.runTransaction(async (transaction) => {
    const [userSnapshot, codeSnapshot, referralSnapshot] = await Promise.all([
      transaction.get(userRef),
      transaction.get(codeRef),
      transaction.get(referralRef),
    ]);
    if (!codeSnapshot.exists) {
      throw new HttpsError("not-found", "Código de indicação não encontrado.");
    }
    const referrerUid = codeSnapshot.data().ownerUid;
    if (referrerUid === uid) {
      throw new HttpsError("failed-precondition", "Você não pode usar seu próprio código.");
    }
    if (referralSnapshot.exists || userSnapshot.data().referredBy) {
      throw new HttpsError("already-exists", "Uma indicação já foi aplicada nesta conta.");
    }
    transaction.create(referralRef, {
      referredUid: uid,
      referrerUid,
      code,
      status: "pending_payment",
      discountPercent: 30,
      discountMonths: 12,
      createdAt: FieldValue.serverTimestamp(),
    });
    transaction.set(userRef, {
      referredBy: referrerUid,
      referralOfferEligible: true,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  });

  return {applied: true};
});

exports.getPromotionEligibility = onCall(
    {enforceAppCheck: true}, async (request) => {
      const uid = requireAuth(request);
      await ensureProfile(uid, request.auth.token);
      const userSnapshot = await db.collection("users").doc(uid).get();
      const user = userSnapshot.data() || {};
      const availableOfferTags = [];

      // Oferta de saída (60% no 1º ano do anual): só durante os 10 minutos
      // concedidos por claimExitOffer e só para quem nunca pagou. Fica em
      // primeiro para ser a oferta preferida enquanto a janela estiver aberta.
      const exitOfferExpiresAt = user.exitOfferExpiresAt?.toDate?.();
      if (!user.firstPaidAt && exitOfferExpiresAt &&
          exitOfferExpiresAt.getTime() > Date.now()) {
        availableOfferTags.push(exitOfferTag);
      }

      if (user.testerEligible === true) {
        availableOfferTags.push("closed-test-yr-70", "closed-test-3m-70");
      }
      if (user.referralOfferEligible === true ||
          (user.referralRewardCredits || 0) > 0) {
        // 30% no primeiro ano do plano anual (oferta da Play Console).
        availableOfferTags.push("referral-yr-30");
      }
      // 7 dias grátis no plano anual; a própria Play só mostra essa oferta
      // para quem nunca teve a assinatura, então aqui ela fica disponível
      // para todos (a oferta de fundador foi desativada na Play).
      availableOfferTags.push("yearly-7daysfree");

      return {
        availableOfferTags,
        bestOfferTag: availableOfferTags[0] || null,
        // Oferta de fundador desativada; mantido em 0 só para não quebrar
        // versões antigas do app que ainda leem este campo.
        founderSpotsRemaining: 0,
      };
    });

// Oferta de saída do questionário ("Muito caro"): uma única vez por conta,
// por 10 minutos, só para contas com menos de 30 dias e que nunca pagaram.
const exitOfferTag = "exitlag";
const exitOfferWindowMs = 10 * 60 * 1000;
const exitOfferMaxAccountAgeMs = 30 * 24 * 60 * 60 * 1000;

exports.claimExitOffer = onCall(
    {enforceAppCheck: true}, async (request) => {
      const uid = requireAuth(request);
      await ensureProfile(uid, request.auth.token);
      const userRef = db.collection("users").doc(uid);

      // Data de criação da conta: a do perfil; se faltar, a do Firebase Auth.
      let authCreatedAt = null;
      try {
        const authUser = await getAuth().getUser(uid);
        authCreatedAt = new Date(authUser.metadata.creationTime);
      } catch (error) {
        console.warn("claimExitOffer: sem data de criação no Auth", error);
      }

      return db.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(userRef);
        const user = snapshot.data() || {};
        const createdAt = user.createdAt?.toDate?.() || authCreatedAt;
        const now = Date.now();
        if (user.firstPaidAt || user.exitOfferClaimedAt || !createdAt ||
            Number.isNaN(createdAt.getTime()) ||
            now - createdAt.getTime() > exitOfferMaxAccountAgeMs) {
          return {granted: false};
        }
        const expiresAt = new Date(now + exitOfferWindowMs);
        transaction.set(userRef, {
          exitOfferClaimedAt: FieldValue.serverTimestamp(),
          exitOfferExpiresAt: expiresAt,
          updatedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
        return {granted: true, expiresAt: expiresAt.toISOString()};
      });
    });

async function fetchGooglePlaySubscription(purchaseToken) {
  const auth = new GoogleAuth({
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const client = await auth.getClient();
  const encodedPackage = encodeURIComponent(packageName);
  const encodedToken = encodeURIComponent(purchaseToken);
  const response = await client.request({
    url: `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodedPackage}/purchases/subscriptionsv2/tokens/${encodedToken}`,
  });
  return response.data;
}

function subscriptionValues(subscription) {
  try {
    return deriveSubscriptionValues(subscription, subscriptionProductId);
  } catch (error) {
    if (error.code === "wrong-product") {
      throw new HttpsError(
          "failed-precondition",
          "A compra não pertence ao MyCarApp Premium.",
      );
    }
    throw error;
  }
}

async function persistSubscription(uid, purchaseToken, subscription) {
  const values = subscriptionValues(subscription);
  const userRef = db.collection("users").doc(uid);
  const entitlementRef = db.collection("entitlements").doc(uid);
  const referralRef = db.collection("referrals").doc(uid);
  const tokenHash = createHash("sha256").update(purchaseToken).digest("hex");
  const tokenRef = db.collection("purchaseTokens").doc(tokenHash);

  const externalAccountId =
    subscription.externalAccountIdentifiers?.obfuscatedExternalAccountId || null;
  if (externalAccountId && externalAccountId !== uid) {
    throw new HttpsError(
        "permission-denied",
        "A compra está vinculada a outra conta do MyCarApp.",
    );
  }

  const persistedValues = await db.runTransaction(async (transaction) => {
    const [userSnapshot, referralSnapshot, tokenSnapshot,
      entitlementSnapshot] =
      await Promise.all([
        transaction.get(userRef),
        transaction.get(referralRef),
        transaction.get(tokenRef),
        transaction.get(entitlementRef),
      ]);
    const user = userSnapshot.data() || {};
    const tokenOwner = tokenSnapshot.data()?.uid;
    if (tokenOwner && tokenOwner !== uid) {
      throw new HttpsError(
          "already-exists",
          "Esta compra já está vinculada a outra conta do MyCarApp.",
      );
    }

    const tokenData = {
      uid,
      productId: values.productId,
      basePlanId: values.basePlanId,
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (!tokenSnapshot.exists) tokenData.createdAt = FieldValue.serverTimestamp();
    transaction.set(tokenRef, tokenData, {merge: true});

    const current = entitlementSnapshot.data() || {};
    const currentExpiry = current.expiresAt?.toDate?.() ||
      current.expiryTime?.toDate?.() || null;
    const incomingIsOlder = current.purchaseTokenHash &&
      current.purchaseTokenHash !== tokenHash && currentExpiry &&
      values.expiryTime && currentExpiry.getTime() > values.expiryTime.getTime();
    if (!incomingIsOlder) {
      transaction.set(entitlementRef, {
        ...values,
        purchaseTokenHash: tokenHash,
        verifiedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
    }

    // firstPaidAt e crédito de indicação só na primeira cobrança real (fora
    // do período de teste grátis), nunca durante o freeTrial.
    if (values.active && !values.inFreeTrial && !user.firstPaidAt) {
      transaction.set(userRef, {
        firstPaidAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
    }

    if (values.active && !values.inFreeTrial && referralSnapshot.exists &&
        referralSnapshot.data().status === "pending_payment") {
      const referrerUid = referralSnapshot.data().referrerUid;
      transaction.set(referralRef, {
        status: "rewarded",
        paidAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      transaction.set(db.collection("users").doc(referrerUid), {
        referralRewardCredits: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
    }
    if (incomingIsOlder) {
      return {
        active: Boolean(current.active),
        state: current.state || "SUBSCRIPTION_STATE_UNSPECIFIED",
        status: current.status || "unknown",
        productId: current.productId || subscriptionProductId,
        basePlanId: current.basePlanId || null,
        offerId: current.offerId || null,
        inFreeTrial: Boolean(current.inFreeTrial),
        expiryTime: currentExpiry,
        expiresAt: currentExpiry,
        autoRenewing: Boolean(current.autoRenewing),
      };
    }
    return values;
  });
  return persistedValues;
}

exports.verifyAndroidSubscription = onCall(
    {enforceAppCheck: true, timeoutSeconds: 30}, async (request) => {
      const uid = requireAuth(request);
      const purchaseToken = String(request.data?.purchaseToken || "").trim();
      if (purchaseToken.length < 20) {
        throw new HttpsError("invalid-argument", "Token de compra inválido.");
      }
      try {
        const subscription = await fetchGooglePlaySubscription(purchaseToken);
        return await persistSubscription(uid, purchaseToken, subscription);
      } catch (error) {
        if (error instanceof HttpsError) throw error;
        console.error("Subscription verification failed", error);
        throw new HttpsError("internal", "Não foi possível validar a assinatura.");
      }
    });

exports.googlePlaySubscriptionNotification = onMessagePublished(
    {topic: "play-subscription-events", timeoutSeconds: 30}, async (event) => {
      const message = event.data.message;
      const payload = JSON.parse(Buffer.from(message.data, "base64").toString("utf8"));
      if (payload.packageName && payload.packageName !== packageName) {
        console.warn("Notification ignored for another package");
        return;
      }
      const purchaseToken = payload.subscriptionNotification?.purchaseToken;
      if (!purchaseToken) return;

      const tokenHash = createHash("sha256").update(purchaseToken).digest("hex");
      const tokenSnapshot = await db.collection("purchaseTokens").doc(tokenHash).get();
      if (!tokenSnapshot.exists) {
        console.warn("Notification received before purchase was linked", {tokenHash});
        throw new Error("Purchase token has not been linked yet; retry notification");
      }
      const uid = tokenSnapshot.data().uid;
      const subscription = await fetchGooglePlaySubscription(purchaseToken);
      await persistSubscription(uid, purchaseToken, subscription);
    });
