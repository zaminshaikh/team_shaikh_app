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
 * Updates activities by adding the 'isDividend' property based on specified conditions.
 *
 * @param {string} usersCollectionID - The name of the users collection.
 */
async function updateActivitiesIsDividend(usersCollectionID) {
  console.log(`Starting 'isDividend' update for all activities in collection '${usersCollectionID}'`);

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

            const shouldBeDividend =
                (activity.type === 'profit' ||
                activity.type === 'income') &&
                ((activity.recipient.includes('IRA') && activity.recipient !== 'Personal IRA') ||
                activity.recipient.includes('CPD') ||
                activity.recipient.includes('Record Keeping'));

            if (shouldBeDividend) {
                await activityDoc.ref.update({ isDividend: true });
                console.log(`Updated 'isDividend' to true for activity ID: ${activityDoc.id} of user CID: ${cid}`);
            } else {
                await activityDoc.ref.update({ isDividend: false });
                console.log(`Updated 'isDividend' to false for activity ID: ${activityDoc.id} of user CID: ${cid}`);
            }
        });

        await Promise.all(updatePromises);
        console.log(`Completed 'isDividend' updates for user CID: ${cid}`);
      } catch (activityError) {
        console.error(`Error processing activities for user CID: ${cid}:`, activityError);
      }
    });

    await Promise.all(userPromises);
    console.log(`Successfully updated 'isDividend' for all activities in collection '${usersCollectionID}'`);
  } catch (error) {
    console.error(`Error updating 'isDividend' for collection '${usersCollectionID}':`, error);
    throw error;
  }
}

// Example usage
const usersCollectionID = 'users'; // Replace with your actual users collection name
updateActivitiesIsDividend(usersCollectionID)
  .then(() => {
    console.log("'isDividend' update completed successfully");
    process.exit(0); // Exit successfully
  })
  .catch(error => {
    console.error("'isDividend' update failed:", error);
    process.exit(1); // Exit with failure
  });