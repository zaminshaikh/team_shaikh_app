const admin = require('firebase-admin');
const path = require('path');

// Path to the service account key file
const serviceAccountPath = path.join(__dirname, 'team-shaikh-service-account.json');
const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

/**
 * For each document in a specified collection, sets the 'uid' property to an empty string if present.
 *
 * @param {string} collectionName - The name of the collection.
 */
async function removeUidFromCollection(collectionName) {
  console.log(`Starting UID removal for collection '${collectionName}'`);

  const collectionRef = db.collection(collectionName);

  try {
    const snapshot = await collectionRef.get();
    console.log(`Found ${snapshot.size} documents in '${collectionName}'`);

    const updatePromises = snapshot.docs.map(async (doc) => {
      const data = doc.data();
      if (data.uid !== undefined) {
        await doc.ref.update({ uid: '' });
        console.log(`Cleared 'uid' for document ID: ${doc.id}`);
      } else {
        console.log(`No 'uid' in document ID: ${doc.id}`);
      }
    });

    await Promise.all(updatePromises);
    console.log('Operation complete');
  } catch (error) {
    console.error('Error removing UID:', error);
    throw error;
  }
}

// Example usage
const collectionName = 'playground'; // Replace with the target collection name
removeUidFromCollection(collectionName)
  .then(() => {
    console.log('UID removal completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('UID removal failed:', error);
    process.exit(1);
  });