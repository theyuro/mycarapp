/**
 * Vincula manualmente uma compra da Google Play que ficou presa em
 * unlinkedPurchases — ou seja, confirmada pela Play (ver
 * googlePlaySubscriptionNotification em functions/index.js) mas sem nenhum
 * uid associado, normalmente porque verifyAndroidSubscription falhou antes
 * de o app conseguir chamá-la (ex.: erro de App Check, queda de rede etc.).
 *
 * Como rodar (localmente, com credencial de administrador):
 *   1. Gere uma chave de conta de serviço do projeto Firebase (Console do
 *      Firebase > Configurações do projeto > Contas de serviço > Gerar nova
 *      chave privada) e salve o .json em um local seguro (fora do git).
 *   2. Essa conta de serviço precisa de acesso de leitura à API do Google
 *      Play Developer para o app (Play Console > Usuários e permissões >
 *      vincule a conta de serviço com permissão de "Ver dados financeiros").
 *   3. Sem --tokenHash, lista as compras pendentes em unlinkedPurchases:
 *        GOOGLE_APPLICATION_CREDENTIALS=/caminho/chave.json \
 *          node scripts/link_unlinked_purchase.js
 *   4. Com --uid e --tokenHash (copiados da listagem acima), vincula e
 *      remove o documento de unlinkedPurchases:
 *        GOOGLE_APPLICATION_CREDENTIALS=/caminho/chave.json \
 *          node scripts/link_unlinked_purchase.js --uid=f00nm1B9xpZMsalBrG8I43ier3X2 --tokenHash=<hash>
 *   Rode sempre a partir da pasta functions/ (o script usa ../index.js).
 */
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {internal} = require("../index.js");

const db = getFirestore();

function parseArgs(argv) {
  const args = {};
  for (const raw of argv.slice(2)) {
    const match = /^--([^=]+)=(.*)$/.exec(raw);
    if (match) args[match[1]] = match[2];
  }
  return args;
}

async function logAdminAction(uid, tokenHash, result) {
  await db.collection("adminActions").add({
    action: "link_unlinked_purchase",
    uid: uid || null,
    tokenHash: tokenHash || null,
    result,
    createdAt: FieldValue.serverTimestamp(),
  });
}

async function listUnlinked() {
  const snapshot = await db.collection("unlinkedPurchases").limit(50).get();
  if (snapshot.empty) {
    console.log("Nenhuma compra pendente em unlinkedPurchases.");
    return;
  }
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const receivedAt = data.receivedAt?.toDate?.()?.toISOString() || "?";
    console.log(
        `${doc.id}  productId=${data.productId} basePlanId=${data.basePlanId} ` +
      `state=${data.state} receivedAt=${receivedAt}`,
    );
  }
  console.log(
      "\nPara vincular, rode de novo com --uid=<uid do MyCarApp> " +
    "--tokenHash=<um dos ids acima>.",
  );
}

async function linkPurchase(uid, tokenHash) {
  const unlinkedRef = db.collection("unlinkedPurchases").doc(tokenHash);
  const snapshot = await unlinkedRef.get();
  if (!snapshot.exists) {
    throw new Error(`unlinkedPurchases/${tokenHash} não encontrado.`);
  }
  const {purchaseToken} = snapshot.data();
  const subscription = await internal.fetchGooglePlaySubscription(purchaseToken);
  // persistSubscription já confirma (acknowledge) a compra se necessário e
  // apaga unlinkedPurchases/{tokenHash} ao vincular — não precisa repetir
  // aqui.
  return internal.persistSubscription(uid, purchaseToken, subscription);
}

async function main() {
  const {uid, tokenHash} = parseArgs(process.argv);
  if (!tokenHash) {
    await listUnlinked();
    return;
  }
  if (!uid) {
    console.error("Informe --uid=<uid> junto com --tokenHash=<hash>.");
    process.exitCode = 1;
    return;
  }
  try {
    const result = await linkPurchase(uid, tokenHash);
    await logAdminAction(uid, tokenHash, "success");
    console.log(
        `OK: ${tokenHash} vinculado a ${uid}. Estado da assinatura: ` +
      `${result.state} (ativa: ${result.active}).`,
    );
  } catch (error) {
    // Nunca o erro bruto (pode ser o Gaxios da Play, com a URL com o
    // purchaseToken); só a versão sanitizada, tanto no log quanto no
    // registro de auditoria.
    const sanitized = internal.sanitizeError(error);
    await logAdminAction(uid, tokenHash, `error: ${sanitized.message}`);
    console.error("Falha ao vincular a compra:", {tokenHash, ...sanitized});
    process.exitCode = 1;
  }
}

main();
