const admin = require('firebase-admin');
const path = require('path');
const pLimit = require('p-limit');

// Path to the service account key file
const serviceAccountPath = path.join(__dirname, 'team-shaikh-service-account.json');
const serviceAccount = require(serviceAccountPath);

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const limit = pLimit(100);

/**
 * Clones a Firestore collection, including all documents and their subcollections.
 * Utilizes Promise.all for parallel processing to enhance performance.
 *
 * @param {string} oldCollectionName - The name of the collection to clone.
 * @param {string} newCollectionName - The name of the new collection.
 */
async function cloneCollection(oldCollectionName, newCollectionName) {
  console.log(`Starting cloning from '${oldCollectionName}' to '${newCollectionName}'`);

  const oldCollectionRef = db.collection(oldCollectionName);
  const newCollectionRef = db.collection(newCollectionName);

  try {
    const documents = await oldCollectionRef.get();
    console.log(`Found ${documents.size} documents in '${oldCollectionName}'`);

    // Create an array of cloneDocument promises
    const clonePromises = documents.docs.map((doc) =>
      limit(async () => {
        console.log(`Cloning document ID: ${doc.id}`);
        return cloneDocument(doc.ref, newCollectionRef.doc(doc.id), newCollectionName);
      })
    );

    // Wait for all documents to be cloned in parallel
    await Promise.all(clonePromises);

    console.log(`Successfully cloned collection '${oldCollectionName}' to '${newCollectionName}'`);
  } catch (error) {
    console.error(`Error cloning collection '${oldCollectionName}' to '${newCollectionName}':`, error);
    throw error;
  }
}

/**
 * Recursively clones a Firestore document, including all its subcollections.
 * Utilizes Promise.all for parallel processing of subcollections and their documents.
 *
 * @param {FirebaseFirestore.DocumentReference} srcDocRef - Reference to the source document.
 * @param {FirebaseFirestore.DocumentReference} destDocRef - Reference to the destination document.
 * @param {string} newCollectionName - The name of the new collection.
 */
async function cloneDocument(srcDocRef, destDocRef, newCollectionName) {
  try {
    // Fetch the document data
    const docSnapshot = await srcDocRef.get();
    if (!docSnapshot.exists) {
      console.warn(`Source document '${srcDocRef.path}' does not exist. Skipping.`);
      return;
    }

    let data = docSnapshot.data();

    const pathSegments = srcDocRef.path.split('/');
    if (pathSegments.includes('activities')) {
      data.parentCollection = newCollectionName;
      console.log(`Updated 'parentCollection' for document ID: ${srcDocRef.id}`);
    }

    // Set the data to the destination document
    await destDocRef.set(data);
    console.log(`Copied data for document ID: ${srcDocRef.id}`);

    // Retrieve all subcollections of the source document
    const subcollections = await srcDocRef.listCollections();

    if (subcollections.length === 0) {
      console.log(`No subcollections found for document ID: ${srcDocRef.id}`);
      return;
    }

    // Create an array of subcollection cloning promises
    const subcollectionPromises = subcollections.map(async (subcollection) => {
      const subcollectionName = subcollection.id;
      console.log(`Cloning subcollection '${subcollectionName}' for document ID: ${srcDocRef.id}`);

      const srcSubcollectionRef = srcDocRef.collection(subcollectionName);
      const destSubcollectionRef = destDocRef.collection(subcollectionName);

      const subDocs = await srcSubcollectionRef.get();
      console.log(`Found ${subDocs.size} documents in subcollection '${subcollectionName}'`);

      // Create an array of cloneDocument promises for subdocuments
      const subDocPromises = subDocs.docs.map((subDoc) => {
        console.log(`Cloning subdocument ID: ${subDoc.id} in subcollection '${subcollectionName}'`);
        return cloneDocument(subDoc.ref, destSubcollectionRef.doc(subDoc.id), newCollectionName);
      });

      // Wait for all subdocuments to be cloned in parallel
      await Promise.all(subDocPromises);
    });

    // Wait for all subcollections to be cloned in parallel
    await Promise.all(subcollectionPromises);
  } catch (error) {
    console.error(`Error cloning document '${srcDocRef.path}':`, error);
    throw error;
  }
}

// Example usage
const oldCollectionName = 'users';   // Replace with the source collection name
const newCollectionName = 'playground';  // Replace with the destination collection name

cloneCollection(oldCollectionName, newCollectionName)
  .then(() => {
    console.log('Collection cloned successfully');
    process.exit(0); // Exit the process successfully
  })
  .catch((error) => {
    console.error('Error cloning collection:', error);
    process.exit(1); // Exit the process with an error code
  });