const {onSchedule} = require("firebase-functions/v2/scheduler");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, Timestamp} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

exports.notifyUpcomingMatches = onSchedule(
  "every 5 minutes",
  async () => {
    const db = getFirestore();
    const now = Timestamp.now();
    const oneHourLater = Timestamp.fromMillis(
      now.toMillis() + 60 * 60 * 1000,
    );

    const snapshot = await db
      .collection("matches")
      .where("cancelled", "==", false)
      .where("dateTime", ">=", now)
      .where("dateTime", "<=", oneHourLater)
      .get();

    const messages = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      const matchId = doc.id;
      const title = data.title || "Partida de futebol";
      const city = data.city || "";
      const date = data.dateTime.toDate();
      const hour = date.toLocaleTimeString("pt-BR", {
        hour: "2-digit",
        minute: "2-digit",
      });
      const participants = data.participants || [];

      participants.forEach((userId) => {
        messages.push({
          matchId,
          userId,
          title,
          city,
          hour,
        });
      });
    });

    if (messages.length === 0) {
      return;
    }

    const messaging = getMessaging();
    const payloads = [];

    for (const item of messages) {
      const userDoc = await db
        .collection("users")
        .doc(item.userId)
        .get();

      if (!userDoc.exists) {
        continue;
      }

      const userData = userDoc.data() || {};
      const tokens = userData.fcmTokens || [];

      tokens.forEach((token) => {
        let bodyText;
        if (item.city) {
          bodyText = `${item.title} em ${item.city} às ${item.hour}`;
        } else {
          bodyText = `${item.title} às ${item.hour}`;
        }

        payloads.push({
          token,
          notification: {
            title: "Lembrete de partida",
            body: bodyText,
          },
          data: {
            matchId: item.matchId,
          },
        });
      });
    }

    if (payloads.length === 0) {
      return;
    }

    const chunkSize = 500;

    for (let i = 0; i < payloads.length; i += chunkSize) {
      const chunk = payloads.slice(i, i + chunkSize);
      await messaging.sendAll(chunk);
    }
  },
);
