import * as functions from "firebase-functions/v2/firestore";
import * as https from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

export const sendTestNotification = https.onRequest(async (req, res) => {
  const token = req.body?.token || req.query?.token;
  if (!token || typeof token !== "string") {
    res.status(400).send({ error: "Missing required string 'token' parameter" });
    return;
  }

  const shortened = token.length > 12 ? `${token.substring(0, 6)}...${token.substring(token.length - 6)}` : token;
  console.log("====================================");
  console.log("TEST NOTIFICATION REQUESTED");
  console.log(`token: ${shortened}`);
  console.log("====================================");

  const message: admin.messaging.Message = {
    token: token,
    notification: {
      title: "RAKSHA TEST",
      body: "FCM is working correctly.",
    },
    data: {
      type: "test_notification",
      timestamp: new Date().toISOString(),
    },
    android: {
      priority: "high",
      notification: {
        channelId: "RAKSHA_EMERGENCY",
        priority: "high",
        sound: "default",
      },
    },
  };

  try {
    const messageId = await admin.messaging().send(message);
    console.log("TEST FCM SEND SUCCESS");
    console.log(`messageId: ${messageId}`);
    res.status(200).send({ success: true, messageId: messageId });
  } catch (error) {
    console.error("TEST FCM SEND FAILED COMPLETE ERROR:", error);
    res.status(500).send({ success: false, error: String(error) });
  }
});

export const onEmergencyCreated = functions.onDocumentCreated(
  "emergencies/{emergencyId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const emergencyData = snapshot.data();
    const emergencyId = event.params.emergencyId;
    const userId = emergencyData.userId as string | undefined;

    console.log("====================================");
    console.log("FUNCTION TRIGGERED");
    console.log(`emergencyId = ${emergencyId}`);
    console.log(`userId = ${userId}`);
    console.log("====================================");

    if (!userId) {
      console.log("No userId present in emergency document");
      return;
    }

    const latitude = emergencyData.latitude;
    const longitude = emergencyData.longitude;
    const triggerType = emergencyData.triggerType || "manual_sos";

    // 1. Fetch victim profile details
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const userData = userDoc.exists ? (userDoc.data() || {}) : {};

    const fName = userData.firstName || "";
    const lName = userData.lastName || "";
    const fullName = (fName + " " + lName).trim();
    const victimName = fullName.length > 0 ? fullName : (userData.displayName || userData.name || "A RAKSHA Contact");

    // 2. Collect guardian UIDs from emergency_contacts array and connections subcollection
    const guardianUids = new Set<string>();

    const emergencyContacts: string[] = userData.emergency_contacts || [];
    emergencyContacts.forEach((uid) => {
      if (uid) guardianUids.add(uid);
    });

    const userConnsSnap = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("connections")
      .get();

    userConnsSnap.docs.forEach((doc) => {
      const connUid = doc.id || doc.data().userId;
      if (connUid) guardianUids.add(connUid);
    });

    guardianUids.delete(userId);

    const guardianList = Array.from(guardianUids);
    console.log(`Guardian UIDs: [${guardianList.join(", ")}]`);

    if (guardianList.length === 0) {
      console.log(`No guardians found for user ${userId}`);
      return;
    }

    // 3. Fetch FCM tokens from users/{uid}/fcm_tokens/{token} (single source of truth)
    const tokens = new Set<string>();

    for (const guardianUid of guardianList) {
      const subSnap = await admin
        .firestore()
        .collection("users")
        .doc(guardianUid)
        .collection("fcm_tokens")
        .get();

      subSnap.docs.forEach((tDoc) => {
        const tokenVal = tDoc.data().token || tDoc.id;
        if (tokenVal) tokens.add(tokenVal);
      });

      console.log(`Guardian ${guardianUid}: ${subSnap.size} token(s)`);
    }

    const tokenList = Array.from(tokens);
    console.log(`Total unique FCM tokens: ${tokenList.length}`);

    if (tokenList.length === 0) {
      console.log(`No FCM tokens registered for guardians of user ${userId}`);
      return;
    }

    const dataPayload: Record<string, string> = {
      type: "emergency",
      emergencyId: emergencyId,
      userId: userId,
      triggeredByUserId: userId,
      status: emergencyData.status || "active",
      triggerType: String(triggerType),
    };

    const isFallback = emergencyData.isFallback === true || emergencyData.isFallback === "true";
    dataPayload.isFallback = isFallback ? "true" : "false";

    if (latitude != null) dataPayload.latitude = String(latitude);
    if (longitude != null) dataPayload.longitude = String(longitude);

    console.log(`[CLOUD FUNCTION] Sending FCM with ${isFallback ? "FALLBACK" : "LIVE"} coordinates: (${latitude}, ${longitude})`);


    const message: admin.messaging.MulticastMessage = {
      tokens: tokenList,
      notification: {
        title: "🚨 RAKSHA EMERGENCY",
        body: `${victimName} has triggered an SOS`,
      },
      data: dataPayload,
      android: {
        priority: "high",
        notification: {
          channelId: "RAKSHA_EMERGENCY",
          priority: "high",
          sound: "default",
        },
      },
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`FCM SEND SUCCESS: ${response.successCount} sent, ${response.failureCount} failed.`);
      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.error(`FCM token ${idx} error:`, resp.error);
          }
        });
      }
    } catch (err) {
      console.error("FCM SEND ERROR COMPLETE STACK:", err);
    }
  }
);
