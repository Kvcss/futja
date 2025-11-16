// functions/index.js
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, Timestamp} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

exports.notifyUpcomingMatches = onSchedule(
  {
    schedule: "every 5 minutes",
    timeZone: "America/Sao_Paulo",
  },
  async (event) => {
    const db = getFirestore();
    const now = Timestamp.now();
    const oneHourLater = Timestamp.fromMillis(
      now.toMillis() + 60 * 60 * 1000,
    );

    console.log(
      "[notifyUpcomingMatches] Rodando em:",
      now.toDate().toISOString(),
      "até",
      oneHourLater.toDate().toISOString(),
    );

    let snapshot;
    try {
      snapshot = await db
        .collection("matches")
        .where("cancelled", "==", false)
        .where("dateTime", ">=", now)
        .where("dateTime", "<=", oneHourLater)
        .get();
    } catch (err) {
      console.error(
        "[notifyUpcomingMatches] Erro na query de partidas:",
        err,
      );
      return;
    }

    console.log(
      "[notifyUpcomingMatches] Partidas encontradas na janela:",
      snapshot.size,
    );

    const messages = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      const matchId = doc.id;
      const title = data.title || "Partida de futebol";
      const city = data.city || "";
      const date = data.dateTime.toDate();
      const hour = date.toLocaleTimeString(
        "pt-BR",
        {
          hour: "2-digit",
          minute: "2-digit",
        },
      );
      const participants = data.participants || [];

      console.log(
        "[notifyUpcomingMatches] Partida",
        matchId,
        "-",
        `"${title}"`,
        "em",
        city,
        "horário",
        hour,
        "participantes:",
        participants.length,
      );

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
      console.log(
        "[notifyUpcomingMatches] Nenhum participante para notificar",
        "nessa janela.",
      );
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
        console.warn(
          "[notifyUpcomingMatches] Usuário não encontrado:",
          item.userId,
        );
        continue;
      }

      const userData = userDoc.data() || {};
      const tokens = userData.fcmTokens || [];

      console.log(
        "[notifyUpcomingMatches] User",
        item.userId,
        "possui",
        tokens.length,
        "tokens.",
      );

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
      console.log(
        "[notifyUpcomingMatches] Nenhum token válido encontrado para",
        "enviar notificações.",
      );
      return;
    }

    console.log(
      "[notifyUpcomingMatches] Enviando total de payloads:",
      payloads.length,
    );

    const chunkSize = 500;

    for (let i = 0; i < payloads.length; i += chunkSize) {
      const chunk = payloads.slice(i, i + chunkSize);
      try {
        const res = await messaging.sendAll(chunk);
        console.log(
          "[notifyUpcomingMatches] Lote enviado:",
          `success=${res.successCount}, failure=${res.failureCount}`,
        );
        if (res.failureCount > 0) {
          res.responses.forEach((r, idx) => {
            if (!r.success) {
              console.error(
                "[notifyUpcomingMatches] Erro ao enviar para token:",
                chunk[idx].token,
                r.error,
              );
            }
          });
        }
      } catch (err) {
        console.error(
          "[notifyUpcomingMatches] Erro ao enviar lote de notificações:",
          err,
        );
      }
    }
  },
);
