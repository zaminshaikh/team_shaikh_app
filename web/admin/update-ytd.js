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
 * Helper function to calculate YTD for a single user.
 */
async function calculateYTDForUser(userCid, usersCollectionID) {
  const currentYear = new Date().getFullYear();
  const startOfYear = new Date(currentYear, 0, 1);
  const endOfYear = new Date(currentYear + 1, 0, 1);

  const activitiesRef = db.collection(`/${usersCollectionID}/${userCid}/activities`);
  const snapshot = await activitiesRef
    .where("fund", "==", "AGQ")
    .where("type", "in", ["profit", "income"])
    .where("time", ">=", startOfYear)
    .where("time", "<=", endOfYear)
    .get();

  let ytdTotal = 0;
  snapshot.forEach((doc) => {
    const activity = doc.data();
    ytdTotal += activity.amount;
  });

  return ytdTotal;
}

/**
 * Helper function to calculate total YTD for a user including connected users.
 */
async function calculateTotalYTDForUser(cid, usersCollectionID) {
  const processedUsers = new Set();
  const userQueue = [cid];
  let totalYTD = 0;

  while (userQueue.length > 0) {
    const currentUserCid = userQueue.shift();

    // Avoid processing the same user more than once
    if (currentUserCid && !processedUsers.has(currentUserCid)) {
      processedUsers.add(currentUserCid);

      // Calculate YTD for the current user
      const ytd = await calculateYTDForUser(currentUserCid, usersCollectionID);
      totalYTD += ytd;

      // Get the user document to retrieve connectedUsers
      const userDoc = await db.collection(usersCollectionID).doc(currentUserCid).get();
      const userData = userDoc.data();

      // Add connected users to the queue if they exist
      if (userData && userData.connectedUsers) {
        userQueue.push(...userData.connectedUsers);
      }
    }
  }

  return totalYTD;
}

/**
 * Updates YTD and totalYTD for all users in the specified collection.
 *
 * @param {string} usersCollectionID - The name of the users collection.
 */
async function updateAllUsersYTD(usersCollectionID) {
  console.log(`Starting YTD update for all users in collection '${usersCollectionID}'`);

  const usersRef = db.collection(usersCollectionID);

  try {
    const usersSnapshot = await usersRef.get();
    console.log(`Found ${usersSnapshot.size} users in collection '${usersCollectionID}'`);

    // Process all users sequentially
    for (const userDoc of usersSnapshot.docs) {
      const cid = userDoc.id;
      console.log(`Processing YTD update for user CID: ${cid}`);

      try {
        // Calculate YTD and totalYTD for the user
        const ytd = await calculateYTDForUser(cid, usersCollectionID);
        const totalYTD = await calculateTotalYTDForUser(cid, usersCollectionID);

        // Update the user's general document within assets subcollection with ytd and totalYTD
        const userGeneralAssetRef = db
          .collection(usersCollectionID)
          .doc(cid)
          .collection('assets')
          .doc('general');
        await userGeneralAssetRef.update({ ytd, totalYTD });

        console.log(`Updated YTD and totalYTD for user CID: ${cid}`);
      } catch (error) {
        console.error(`Error updating YTD for user CID: ${cid}:`, error);
      }
    }

    console.log(`Successfully updated YTD for all users in collection '${usersCollectionID}'`);
  } catch (error) {
    console.error(`Error updating YTD for collection '${usersCollectionID}':`, error);
    throw error;
  }
}

// Example usage
const usersCollectionID = 'users'; // Replace with your actual users collection name
updateAllUsersYTD(usersCollectionID)
  .then(() => {
    console.log('YTD update completed successfully');
    process.exit(0); // Exit successfully
  })
  .catch(error => {
    console.error('YTD update failed:', error);
    process.exit(1); // Exit with failure
  });