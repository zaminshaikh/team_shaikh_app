const admin = require('firebase-admin');
const path = require('path');

// Path to the service account key file
const serviceAccountPath = path.join(__dirname, 'team-shaikh-service-account.json');
const serviceAccount = require(serviceAccountPath);

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

/**
 * Updates activities by adding the 'profit' property based on specified conditions.
 *
 * @param {string} usersCollectionID - The name of the users collection.
 */
async function convertIncomeToProfitInActivities(usersCollectionID) {
  console.log(`Starting 'profit' update for all activities in collection '${usersCollectionID}'`);

  const usersRef = db.collection(usersCollectionID);

  try {
    const usersSnapshot = await usersRef.get();
    console.log(`Found ${usersSnapshot.size} users in collection '${usersCollectionID}'`);

    const userPromises = usersSnapshot.docs.map(async (userDoc) => {
      const cid = userDoc.id;
      console.log(`Processing user CID: ${cid}`);

      const activitiesRef = usersRef.doc(cid).collection('activities');

      try {
        const activitiesSnapshot = await activitiesRef.get();
        console.log(`Retrieved ${activitiesSnapshot.size} activities for user CID: ${cid}`);

        const updatePromises = activitiesSnapshot.docs.map(async (activityDoc) => {
            const activity = activityDoc.data();

            if (activity.type == 'income') {
                await activityDoc.ref.update({ type: 'profit' });
                console.log(`Updated 'type' to 'profit' for activity ID: ${activityDoc.id} of user CID: ${cid}`);
            }
        });

        await Promise.all(updatePromises);
      } catch (activityError) {
        console.error(`Error processing activities for user CID: ${cid}:`, activityError);
      }
    });

    await Promise.all(userPromises);
    console.log(`Successfully updated 'type' for all activities in collection '${usersCollectionID}'`);
  } catch (error) {
    console.error(`Error updating 'type' for collection '${usersCollectionID}':`, error);
    throw error;
  }
}

// Example usage
const usersCollectionID = 'users'; // Replace with your actual users collection name
convertIncomeToProfitInActivities(usersCollectionID)
  .then(() => {
    console.log("'profit' update completed successfully");
    process.exit(0); // Exit successfully
  })
  .catch(error => {
    console.error("'profit' update failed:", error);
    process.exit(1); // Exit with failure
  });