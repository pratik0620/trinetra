import * as functions from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

export const onEmergencyCreated = functions.onDocumentCreated(
  "emergencies/{emergencyId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const emergencyData = snapshot.data();
    const emergencyId = event.params.emergencyId;
    const userId = emergencyData.userId;
    const triggerType = emergencyData.triggerType || "manual_sos";

    if (!userId) return;

    // 1. Get victim name
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const victimName = userDoc.exists ? userDoc.data()?.name || "Priya" : "A RAKSHA contact";

    // 2. Find accepted connections authorized to receive SOS
    const connectionsRef = admin.firestore().collection("connections");
    
    const reqQuery = await connectionsRef
      .where("requesterId", "==", userId)
      .where("status", "==", "accepted")
      .where("canReceiveSOS", "==", true)
      .get();

    const recQuery = await connectionsRef
      .where("receiverId", "==", userId)
      .where("status", "==", "accepted")
      .where("canReceiveSOS", "==", true)
      .get();

    const guardianUids = new Set<string>();

    reqQuery.docs.forEach((doc) => {
      guardianUids.add(doc.data().receiverId);
    });

    recQuery.docs.forEach((doc) => {
      guardianUids.add(doc.data().requesterId);
    });

    if (guardianUids.size === 0) {
      console.log(`No authorized guardians found for user ${userId}`);
      return;
    }

    // 3. Fetch FCM tokens for guardians
    const tokens: string[] = [];

    for (const guardianUid of guardianUids) {
      const tokensSnap = await admin
        .firestore()
        .collection("users")
        .doc(guardianUid)
        .collection("fcm_tokens")
        .get();

      tokensSnap.docs.forEach((tDoc) => {
        const tokenVal = tDoc.data().token;
        if (tokenVal) tokens.push(tokenVal);
      });
    }

    if (tokens.length === 0) {
      console.log(`No FCM tokens found for guardians of user ${userId}`);
      return;
    }

    // 4. Send FCM Multicast
    const message: admin.messaging.MulticastMessage = {
      tokens: tokens,
      notification: {
        title: "RAKSHA EMERGENCY",
        body: `${victimName} needs help`,
      },
      data: {
        emergencyId: emergencyId,
        senderId: userId,
        triggerType: triggerType,
        notificationType: "emergency",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "emergency_channel",
          priority: "high",
          sound: "default",
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`Emergency notification sent to ${response.successCount} devices.`);
  }
);
