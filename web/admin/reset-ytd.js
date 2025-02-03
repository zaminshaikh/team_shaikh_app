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
 * Resets 'totalYTD' to 0 and removes 'totalYtd' from the 'general' document in the 'assets' subcollection for all users.
 *
 * @param {string} usersCollectionID - The name of the users collection.
 */
async function resetAllUsersYTD(usersCollectionID) {
  console.log(`Starting YTD reset for all users in collection '${usersCollectionID}'`);

  const usersRef = db.collection(usersCollectionID);

  try {
    const usersSnapshot = await usersRef.get();
    console.log(`Found ${usersSnapshot.size} users in collection '${usersCollectionID}'`);

    // Process all users sequentially
    for (const userDoc of usersSnapshot.docs) {
      const cid = userDoc.id;
      console.log(`Resetting YTD for user CID: ${cid}`);

      try {
        const userGeneralAssetRef = db
          .collection(usersCollectionID)
          .doc(cid)
          .collection('assets')
          .doc('general');

        await userGeneralAssetRef.update({
          totalYTD: 0,
          totalYtd: admin.firestore.FieldValue.delete(),
        });

        console.log(`Reset 'totalYTD' and removed 'totalYtd' for user CID: ${cid}`);
      } catch (error) {
        console.error(`Error resetting YTD for user CID: ${cid}:`, error);
      }
    }

    console.log(`Successfully reset YTD for all users in collection '${usersCollectionID}'`);
  } catch (error) {
    console.error(`Error resetting YTD for collection '${usersCollectionID}':`, error);
    throw error;
  }
}

// Example usage
const usersCollectionID = 'users'; // Replace with your actual users collection name
resetAllUsersYTD(usersCollectionID)
  .then(() => {
    console.log('YTD reset completed successfully');
    process.exit(0); // Exit successfully
  })
  .catch(error => {
    console.error('YTD reset failed:', error);
    process.exit(1); // Exit with failure
  });