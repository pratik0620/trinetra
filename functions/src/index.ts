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
    const userId = emergencyData.userId;

    console.log("====================================");
    console.log("FUNCTION TRIGGERED");
    console.log(`emergencyId = ${emergencyId}`);
    console.log(`userId = ${userId}`);
    console.log("====================================");

    if (!userId) {
      console.log("No userId present in emergency document");
      return;
    }

    console.log(`Emergency user: ${userId}`);

    // 1. Fetch victim profile details
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const userData = userDoc.exists ? (userDoc.data() || {}) : {};

    const fName = userData.firstName || "";
    const lName = userData.lastName || "";
    const fullName = (fName + " " + lName).trim();
    const victimName = fullName.length > 0 ? fullName : (userData.displayName || userData.name || "A RAKSHA Contact");

    // 2. Read emergency_contacts array (Primary recipient source)
    const emergencyContacts: string[] = userData.emergency_contacts || [];
    const guardianUids = new Set<string>(emergencyContacts);

    // Also check connections subcollection for existing accepted connections
    const userConnsSnap = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("connections")
      .get();

    userConnsSnap.docs.forEach((doc) => {
      const connUid = doc.id || doc.data().userId;
      if (connUid) {
        guardianUids.add(connUid);
      }
    });

    // DO NOT NOTIFY THE SOS USER HERSELF
    guardianUids.delete(userId);

    const guardianList = Array.from(guardianUids);
    console.log(`Emergency contacts: [${guardianList.join(", ")}]`);

    if (guardianList.length === 0) {
      console.log(`No emergency contacts found for user ${userId}`);
      return;
    }

    // 3. Fetch FCM tokens for each emergency contact
    const tokens = new Set<string>();

    for (const guardianUid of guardianList) {
      const contactTokens: string[] = [];

      // Check user document fcmTokens array
      const gDoc = await admin.firestore().collection("users").doc(guardianUid).get();
      if (gDoc.exists) {
        const gData = gDoc.data() || {};
        if (Array.isArray(gData.fcmTokens)) {
          gData.fcmTokens.forEach((t: string) => {
            if (t) {
              tokens.add(t);
              contactTokens.push(t);
            }
          });
        }
      }

      // Check fcm_tokens subcollection
      const subSnap = await admin
        .firestore()
        .collection("users")
        .doc(guardianUid)
        .collection("fcm_tokens")
        .get();

      subSnap.docs.forEach((tDoc) => {
        const tokenVal = tDoc.data().token;
        if (tokenVal) {
          tokens.add(tokenVal);
          contactTokens.push(tokenVal);
        }
      });

      // Check devices subcollection
      const devSnap = await admin
        .firestore()
        .collection("users")
        .doc(guardianUid)
        .collection("devices")
        .get();

      devSnap.docs.forEach((dDoc) => {
        const tokenVal = dDoc.data().fcmToken;
        if (tokenVal) {
          tokens.add(tokenVal);
          contactTokens.push(tokenVal);
        }
      });

      console.log(`Contact UID: ${guardianUid} | Device tokens found: ${contactTokens.length}`);
    }

    const tokenList = Array.from(tokens);
    console.log(`Total unique FCM tokens found: ${tokenList.length}`);

    if (tokenList.length === 0) {
      console.log(`No FCM tokens registered for emergency contacts of user ${userId}`);
      return;
    }

    // 4. Send Multicast FCM notification
    const message: admin.messaging.MulticastMessage = {
      tokens: tokenList,
      notification: {
        title: "🚨 RAKSHA EMERGENCY",
        body: `${victimName} has triggered an SOS`,
      },
      data: {
        type: "emergency",
        emergencyId: emergencyId,
        triggeredByUserId: userId,
        status: "active",
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

    for (const t of tokenList) {
      const shortened = t.length > 12 ? `${t.substring(0, 6)}...${t.substring(t.length - 6)}` : t;
      console.log(`Sending emergency notification to token: ${shortened}`);
    }

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
