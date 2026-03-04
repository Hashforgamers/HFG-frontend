const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

async function sendTemplateNotification(topic, templateId, data) {

  const templateDoc = await admin.firestore()
      .collection("notification_templates")
      .doc(templateId)
      .get();

  const template = templateDoc.data();

  let title = template.title;
  let body = template.body;

  Object.keys(data).forEach(key => {
    title = title.replace(`{${key}}`, data[key]);
    body = body.replace(`{${key}}`, data[key]);
  });

  const payload = {
    notification: {
      title: title,
      body: body
    }
  };

  await admin.messaging().sendToTopic(topic, payload);
}

exports.bookingSocialProof = functions.firestore
  .document("bookings/{bookingId}")
  .onCreate(async (snap, context) => {

    const booking = snap.data();

    const cafeName = booking.cafe_name;

    await sendTemplateNotification(
      "mira_road_users",
      "social_proof",
      {
        players_online: 6,
        cafe_name: cafeName
      }
    );

});
