import * as functions from "firebase-functions/v1";
import config from "../../config.json";
import {QueryDocumentSnapshot, Timestamp} from "firebase-admin/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();
const messaging = admin.messaging();
const db = admin.firestore();

/**
 * Defines the structure for notification objects.
 * 
 * @param activityId - Unique identifier for the associated activity.
 * @param recipient - Identifier for the recipient of the notification.
 * @param title - Title of the notification.
 * @param body - Body text of the notification.
 * @param message - Complete message of the notification.
 * @param isRead - Boolean indicating if the notification has been read.
 * @param type - Type of notification.
 * @param time - Timestamp of when the notification was created or should be sent.
 */
interface Notification {
    activityId: string;
    recipient: string;
    title: string;
    body: string;
    message: string;
    isRead: boolean;
    type: string;
    time: Date | Timestamp;
}

/**
 * Defines the structure for activity objects.
 * 
 * @param amount - Numeric value associated with the activity (e.g., transaction amount).
 * @param fund - Name or identifier of the fund involved in the activity.
 * @param recipient - Identifier for the recipient of the activity.
 * @param time - Timestamp of when the activity occurred.
 * @param formattedTime - Optional formatted string of the time.
 * @param type - Type of activity (e.g., withdrawal, deposit).
 * @param isDividend - Optional boolean to indicate if the activity involves dividends.
 * @param sendNotif - Optional boolean to indicate whether a notification should be sent for this activity.
 */
interface Activity {
    amount: number;
    fund: string;
    recipient: string;
    time: Date | Timestamp;
    formattedTime?: string;
    type: string;
    isDividend?: boolean;
    sendNotif?: boolean;
}

export interface AssetDetails {
    amount: number;
    firstDepositDate: Date | null;
    displayTitle: string;
    index: number;
}



// Define both activity paths
const activityPath = `/{userCollection}/{userId}/${config.ACTIVITIES_SUBCOLLECTION}/{activityId}`;
export const handleActivity = functions.firestore.document(activityPath).onCreate(handleNewActivity);

/**
 * Generates a custom message based on the type of activity.
 * 
 * This function constructs a user-friendly message that describes the activity in detail, 
 * which is used for notifications and logging purposes.
 *
 * @param activity - The activity data containing type, fund, amount, and recipient.
 * @return The constructed message as a string.
 */
function getActivityMessage(activity: Activity): string {
    let message: string;
    switch (activity.type) {
        case 'withdrawal':
            message = `New Withdrawal: ${activity.fund} Fund finished processing the withdrawal of $${activity.amount} from ${activity.recipient}'s account. View the Activity section for more details.`;
            break;
        case 'profit':
            message = `New Profit: ${activity.fund} has posted the latest returns for ${activity.recipient}. View the Activity section for more details.`;
            break;
        case 'deposit':
            message = `New Deposit: ${activity.fund} has finished processing the deposit of $${activity.amount} into ${activity.recipient}'s account. View the Activity section for more details.`;
            break;
        case 'manual-entry':
            message = `New Manual Entry: ${activity.fund} Fund has made a manual entry of $${activity.amount} into your account. View the Activity section for more details.`;
            break;
        default:
            message = 'New Activity: A new activity has been created. View the Activity section for more details.';
    }
    return message;
}

/**
 * Creates a notification document in Firestore based on given activity details.
 * 
 * This function populates a notification object with details provided from an activity,
 * then stores it in Firestore under the specified user's notifications collection.
 *
 * @param activity - The activity object containing details for the notification.
 * @param cid - The Firestore document ID of the user to whom the notification will be sent.
 * @param activityId - The unique ID of the activity, used for tracking.
 * @return A promise that resolves with notification details including title, body, and user reference.
 */
async function createNotif(activity: Activity, cid: string, activityId: string, usersCollectionID: string): Promise<{ title: string; body: string; userRef: FirebaseFirestore.DocumentReference; }> {
    const userRef = admin.firestore().doc(`${usersCollectionID}/${cid}`);
    const notificationsCollectionRef = userRef.collection(config.NOTIFICATIONS_SUBCOLLECTION);
    const message = getActivityMessage(activity);
    const [title, body] = message.split(': ', 2);

    const notification = {
        activityId: activityId,
        recipient: activity.recipient,
        title: title,
        body: body,
        message: message,
        isRead: false,
        type: 'activity',
        time: admin.firestore.FieldValue.serverTimestamp(),
    } as Notification;

    await notificationsCollectionRef.add(notification);
    return {title, body, userRef};
}

/**
 * Sends a notification via Firebase Cloud Messaging (FCM) to a user's device.
 * 
 * This function retrieves FCM tokens from a user's document and sends a notification
 * with a title and body. It handles multiple tokens by sending to all associated devices.
 *
 * @param title - The title of the notification to be sent.
 * @param body - The body content of the notification.
 * @param userRef - A reference to the Firestore document of the user.
 * @return A promise that resolves with the results of the send operations for each FCM token.
 * @throws Error if no FCM tokens are found, indicating the user may not have any registered devices.
 */
async function sendNotif(title: string, body: string, userRef: FirebaseFirestore.DocumentReference): Promise<string[]> {
    const userDoc = await userRef.get();
    const userData = userDoc.data();
    if (userData && userData.tokens && Array.isArray(userData.tokens)) {
        const sendPromises = userData.tokens.map((token: string) => {
            const fcmMessage = {
                token: token,
                notification: {
                    title: title,
                    body: body,
                },
            };
            return messaging.send(fcmMessage);
        });
        return Promise.all(sendPromises);
    } else {
        throw new Error('FCM tokens not found');
    }
}

/**
 * Cloud Firestore Trigger for creating and sending notifications upon new activity creation.
 * 
 * This function listens to a specific path in Firestore for any new documents (activities).
 * If a new activity requires a notification, it processes the activity, creates a notification,
 * and sends it to the relevant user's devices.
 *
 * @param snapshot - The snapshot of the new activity document.
 * @param context - The context of the event, including path parameters.
 * @return A promise resolved with the result of the notification send operation, or null if no notification is sent.
 */
async function handleNewActivity(snapshot: functions.firestore.DocumentSnapshot, context: functions.EventContext): Promise<string[] | null> {
    const activity = snapshot.data() as Activity;
    const { userId, activityId, userCollection} = context.params;

    await updateYTD(userId, userCollection); // Update YTD for the user and connected users

    if (activity.sendNotif !== true || userCollection === 'backup' || userCollection === 'playground' || userCollection === 'playground2') {
        return null; // Exit if no notification is required
    }

    try {
        const {title, body, userRef} = await createNotif(activity, userId, activityId, userCollection);
        const result = sendNotif(title, body, userRef);
        return result;
    } catch (error) {
        console.error('Error handling activity:', error);
        throw new functions.https.HttpsError('unknown', 'Failed to handle activity', error);
    }
}

/**
 * Helper function to update YTD and totalYTD for a user and connected users.
 */
async function updateYTD(cid: string, usersCollectionID: string): Promise<void> {
    try {
        // Calculate YTD and totalYTD for the user
        const ytd = await calculateYTDForUser(cid, usersCollectionID);
        const totalYTD = await calculateTotalYTDForUser(cid, usersCollectionID);

        // Update the user's general document within assets subcollection with ytd and totalYTD
        const userGeneralAssetRef = admin.firestore()
            .collection(usersCollectionID)
            .doc(cid)
            .collection(config.ASSETS_SUBCOLLECTION)
            .doc(config.ASSETS_GENERAL_DOC_ID);
        await userGeneralAssetRef.update({ ytd, totalYTD });

        // Find all users where 'connectedUsers' array contains cid
        const usersCollectionRef = admin.firestore().collection(usersCollectionID);
        const parentUsersSnapshot = await usersCollectionRef
            .where('connectedUsers', 'array-contains', cid)
            .get();

        const updatePromises = parentUsersSnapshot.docs.map(async (doc) => {
            const parentUserCID = doc.id;

            // Recalculate totalYTD for connected user
            const parentUserTotalYTD = await calculateTotalYTDForUser(parentUserCID, usersCollectionID);

            // Update connected user's general within assets subcollection with totalYTD
            const parentUserGeneralAssetRef = admin.firestore()
                .collection(usersCollectionID)
                .doc(parentUserCID)
                .collection(config.ASSETS_SUBCOLLECTION)
                .doc(config.ASSETS_GENERAL_DOC_ID);
            await parentUserGeneralAssetRef.update({ totalYTD: parentUserTotalYTD });
        });

        await Promise.all(updatePromises);
    } catch (error) {
        console.error("Error updating YTD:", error);
        throw new functions.https.HttpsError(
            'unknown',
            'Failed to update YTD due to an unexpected error.',
            { errorDetails: (error as Error).message },
        );
    }
}

/**
 * Callable function to link a new user's document in Firestore with their authentication UID.
 * 
 * This function updates a user's document to include their UID and email once they register.
 * It ensures data consistency and enables notification functionality.
 *
 * @param data - Contains the email, user document ID (cid), and UID from the client.
 * @param context - Provides authentication and runtime context.
 * @return Logs success messages or errors, with no explicit return value.
 */
export const linkNewUser = functions.https.onCall(async (data, context): Promise<void> => {
    // Ensure authenticated context
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }
  
    const { email, cid, uid, usersCollectionID } = data;

    if (!email) {
      throw new functions.https.HttpsError('invalid-argument', 'The function must be called with a valid "email".');
    } else if (!cid) {
        throw new functions.https.HttpsError('invalid-argument', 'The function must be called with a valid "cid".');
    } else if (!uid) { 
        throw new functions.https.HttpsError('invalid-argument', 'The function must be called with a valid "uid".');
    } else if (!usersCollectionID) {
        throw new functions.https.HttpsError('invalid-argument', 'The function must be called with a valid "usersCollectionID".');
    }
  
    const usersCollection = admin.firestore().collection(usersCollectionID);
    const userRef = usersCollection.doc(cid);
    const userSnapshot = await userRef.get();
  
    if (!userSnapshot.exists) {
      throw new functions.https.HttpsError('not-found', `Document does not exist for cid: ${cid}`);
    }
  
    const existingData = userSnapshot.data() as admin.firestore.DocumentData;
  
    // Check if user already exists
    if (existingData.uid && existingData.uid !== '') {
      throw new functions.https.HttpsError('already-exists', `User already exists for cid: ${cid}`);
    }
  
    // Prepare updated data
    const updatedData = {
      ...existingData,
      uid: uid,
      email: email,
      appEmail: email,
    };
  
    // Update the user document
    await userRef.set(updatedData);
  
    console.log(`User ${uid} has been linked with document ${cid} in Firestore`);
  
    const connectedUsers: string[] = existingData.connectedUsers || [];
  
    // Update connected users
    await addUidToConnectedUsers(connectedUsers, uid, usersCollection);
});

/**
 * Helper function to update the access list for connected users.
 * 
 * This function iterates over each connected user for a newly linked user and updates their
 * access control lists to include the new user's UID. This is crucial for sharing data access among related users.
 *
 * @param connectedUsers - Array of document IDs for users who are connected to the new user.
 * @param uid - UID of the newly linked user to be added to others' access control lists.
 * @param usersCollection - Reference to the Firestore collection containing user documents.
 * @return A promise resolved once all updates are completed.
 */
const addUidToConnectedUsers = async (connectedUsers: string[], uid: string, usersCollection: admin.firestore.CollectionReference): Promise<void> => {
    const updatePromises = connectedUsers.map(async (connectedUser) => {
        const connectedUserRef = usersCollection.doc(connectedUser);
        const connectedUserSnapshot = await connectedUserRef.get();

        if (connectedUserSnapshot.exists) {
            const connectedUserData = connectedUserSnapshot.data() as admin.firestore.DocumentData;
            const uidGrantedAccess: string[] = connectedUserData.uidGrantedAccess || [];

            if (!uidGrantedAccess.includes(uid)) {
                uidGrantedAccess.push(uid);
                await connectedUserRef.update({ uidGrantedAccess });
                console.log(`User ${uid} has been added to uidGrantedAccess of connected user ${connectedUser}`);
            }
        } else {
            console.log(`Connected user document ${connectedUser} does not exist`);
        }
    });

    await Promise.all(updatePromises);
};


/**
 * Checks if a document exists in the users collection in Firestore based on a given document ID.
 * 
 * This function is callable, meaning it's designed to be invoked directly from a client application.
 * It requires the client to provide a 'cid' (Client ID) which represents the document ID whose existence is to be verified.
 *
 * @param {Object} data - The data payload passed from the client, which should include the 'cid'.
 * @param {Object} context - The context of the function call, providing authentication and environment details.
 * @returns {Promise<Object>} - A promise that resolves to an object indicating whether the document exists.
 *                              The object has a single property 'exists' which is a boolean.
 * @throws {functions.https.HttpsError} - Throws an 'invalid-argument' error if the 'cid' is not provided or is invalid.
 *                                        Throws an 'unknown' error if there's an unexpected issue during the execution.
 */
exports.checkDocumentExists = functions.https.onCall(async (data, context): Promise<object> => {
    // Extract 'cid' from the data payload; it is expected to be the Firestore document ID.
    const cid = data.cid;
    const usersCollectionID = data.usersCollectionID;

    // Check if 'cid' is provided, if not, throw an 'invalid-argument' error.
    if (!cid) {
      throw new functions.https.HttpsError('invalid-argument', 'The function must be called with one argument "cid".');
    }

    if (!usersCollectionID) {
        throw new functions.https.HttpsError('invalid-argument', 'The function must be called with one argument "usersCollectionID".');
    }
  
    try {
      // Attempt to fetch the document by ID from the users collection.
      const docSnapshot = await admin.firestore().collection(usersCollectionID).doc(cid).get();
        
      // Return the existence status of the document as a boolean.
      return { exists: docSnapshot.exists };
    } catch (error) {
      // Log the error and throw a generic 'unknown' error for any unexpected issues.
      console.error('Error checking document existence:', error);
      throw new functions.https.HttpsError('unknown', 'Failed to check document existence', error);
    }
});

/**
 * Checks if a document in the users collection is linked to a user.
 * 
 * This function expects a document ID ('cid') and checks if the corresponding document
 * in the Firestore users collection has a non-empty 'uid' field, indicating a link to a user.
 *
 * @param {Object} data - The data payload from the client, expected to contain the 'cid'.
 * @param {Object} context - The context of the function call, providing environment and authentication details.
 * @returns {Promise<Object>} - A promise that resolves to an object with a boolean property 'isLinked'.
 * @throws {functions.https.HttpsError} - Throws an 'invalid-argument' error if the 'cid' is not provided.
 * @throws {functions.https.HttpsError} - Throws an 'unknown' error for any unexpected issues during execution.
 */
exports.checkDocumentLinked = functions.https.onCall(async (data, context) => {
    try {
      let cid = data.cid;
      const usersCollectionID = data.usersCollectionID;
      console.log('Received data:', data);
  
      // Validate input: ensure 'cid' is provided
      if (cid === undefined || cid === null) {
        console.error('No cid provided.');
        throw new functions.https.HttpsError(
          'invalid-argument',
          'The function must be called with one argument "cid".'
        );
      }

      if (usersCollectionID === undefined || usersCollectionID === null) {
        console.error('No usersCollectionID provided.');
        throw new functions.https.HttpsError(
          'invalid-argument',
          'The function must be called with one argument "usersCollectionID".'
        );
      }
  
      // Convert cid to string and trim whitespace
      cid = String(cid).trim();
      console.log('Processed cid:', cid);
  
      if (cid.length === 0) {
        console.error('Empty cid after trimming.');
        throw new functions.https.HttpsError(
          'invalid-argument',
          'The "cid" cannot be an empty string.'
        );
      }
  
      // Fetch the document from the users collection using the provided 'cid'
      const docSnapshot = await admin
        .firestore()
        .collection(usersCollectionID)
        .doc(cid)
        .get();
  
      console.log('Fetched document snapshot:', docSnapshot.exists);
  
      // Check if the document exists and the 'uid' field is non-empty
      const docData = docSnapshot.data();
      console.log('Document data:', docData);
  
      const uid = docData?.uid;
      console.log('User ID:', uid);
  
      const isLinked = !!(
        docSnapshot.exists &&
        uid &&
        uid !== '' &&
        uid !== null
      );
  
      console.log(`isLinked: ${isLinked}, type: ${typeof isLinked}`);
  
      // Return the link status as a boolean
      return { isLinked };
    } catch (error) {
      console.error('Error checking document link status:', error);
      throw new functions.https.HttpsError(
        'unknown',
        'Failed to check document link status',
        error
      );
    }
  });


/**
 * Helper function to calculate YTD for a single user.
 */
async function calculateYTDForUser(userCid: string, usersCollectionID: string): Promise<number> {
    const currentYear = new Date().getFullYear();
    const startOfYear = new Date(currentYear, 0, 1);
    const endOfYear = new Date(currentYear + 1, 0, 1);

    const activitiesRef = admin.firestore().collection(`/${usersCollectionID}/${userCid}/${config.ACTIVITIES_SUBCOLLECTION}`);
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
async function calculateTotalYTDForUser(cid: string, usersCollectionID: string): Promise<number> {
    const processedUsers: Set<string> = new Set();
    const userQueue: string[] = [cid];
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
            const userDoc = await admin.firestore().collection(`${usersCollectionID}`).doc(currentUserCid).get();
            const userData = userDoc.data();

            // Add connected users to the queue if they exist
            if (userData && userData.connectedUsers) {
                const connectedUsers = userData.connectedUsers as string[];
                userQueue.push(...connectedUsers);
            }
        }
    }

    return totalYTD;
}


exports.calculateYTD = functions.https.onCall(async (data, context): Promise<object> => {
    const cid = data.cid;
    const usersCollectionID = data.usersCollectionID;
    if (!cid) {
        throw new functions.https.HttpsError('invalid-argument', 'The function must be called with a valid "cid".');
    }
    if (!usersCollectionID) {
        throw new functions.https.HttpsError('invalid-argument', 'The function must be called with a valid "usersCollectionID".');
    }
    try {
        const currentYear = new Date().getFullYear();
        const startOfYear = new Date(currentYear, 0, 1);
        const endOfYear = new Date(currentYear + 1, 0, 1);

        const activitiesRef = admin.firestore().collection(`/${usersCollectionID}/${cid}/${config.ACTIVITIES_SUBCOLLECTION}`);
        const snapshot = await activitiesRef
            .where("fund", "==", "AGQ")
            .where("type", "in", ["profit", "income"])
            .where("time", ">=", startOfYear)
            .where("time", "<=", endOfYear)
            .get();

        let ytd = 0;
        snapshot.forEach((doc) => {
            const activity = doc.data();
            ytd += activity.amount;
        });

        return { ytd: ytd };
    } catch (error) {
        console.error("Error calculating YTD:", error);
        throw new functions.https.HttpsError('unknown', 'Failed to calculate YTD due to an unexpected error.', {
            errorDetails: (error as Error).message,
        });
    }
});

exports.calculateTotalYTD = functions.https.onCall(async (data, context): Promise<object> => {
    const cid = data.cid;
    const usersCollectionID = data.usersCollectionID;
    if (!cid) {
        throw new functions.https.HttpsError('invalid-argument', 'The function must be called with a valid "cid".');
    }

    if (!usersCollectionID) {
        throw new functions.https.HttpsError('invalid-argument', 'The function must be called with a valid "usersCollectionID".');
    }

    try {
        // Queue to track users that need to be processed
        const userQueue: string[] = [cid];
        let totalYTD = 0;
        const processedUsers: Set<string> = new Set();

        // Iteratively process the queue of users
        while (userQueue.length > 0) {
            const currentUserCid = userQueue.shift();
            
            // Avoid processing the same user more than once
            if (currentUserCid && !processedUsers.has(currentUserCid)) {
                processedUsers.add(currentUserCid);

                // Calculate YTD for the current user
                totalYTD += await calculateYTDForUser(currentUserCid, usersCollectionID);

                // Get the user document to retrieve connectedUsers
                const userDoc = await admin.firestore().collection(`${usersCollectionID}`).doc(currentUserCid).get();
                const userData = userDoc.data();

                // Add connected users to the queue if they exist
                if (userData && userData.connectedUsers) {
                    const connectedUsers = userData.connectedUsers as string[];
                    userQueue.push(...connectedUsers);
                }
            }
        }

        return { ytdTotal: totalYTD };
    } catch (error) {
        console.error("Error calculating YTD:", error);
        throw new functions.https.HttpsError('unknown', 'Failed to calculate YTD due to an unexpected error.', {
            errorDetails: (error as Error).message,
        });
    }
});

/**
 * UnlinkUser Callable Function
 * 
 * @param {Object} data - The data payload containing 'uid' and 'cid'.
 * @param {string} data.uid - The UID of the user in Firebase Auth.
 * @param {string} data.cid - The document ID of the user in the 'testUsers' Firestore collection.
 * 
 * @returns {Object} - An object containing the success status and a message.
 * 
 * @throws {HttpsError} - Throws an error if input is invalid or operations fail.
 */
exports.unlinkUser = functions.https.onCall(async (data, context) => {
  // Destructure 'uid' and 'cid' from the incoming data
  const { uid, cid, usersCollectionID } = data;

  // Input validation: Ensure both 'uid' and 'cid' are provided
  if (!uid || !cid || !usersCollectionID) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with both "uid", "cid", and "usersCollectionID" arguments.'
    );
  }

  try {
    // Reference to the specific user document in 'testUsers' collection
    const userRef = admin.firestore().collection(usersCollectionID).doc(cid);

    // Fetch the user document to verify existence
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        `User document with cid ${cid} does not exist.`
      );
    }

    // Update the Firestore document: Set specified fields to empty strings and clear the 'tokens' array
    await userRef.update({
      appEmail: '',
      uid: '',
      tokens: [],
    });

    console.log(`Firestore: Cleared fields for user with cid ${cid}.`);

    // Delete the user from Firebase Authentication using the provided UID
    await admin.auth().deleteUser(uid);

    console.log(`Firebase Auth: Deleted user with uid ${uid}.`);

    // Return a success response
    return { success: true, message: `User with uid ${uid} and cid ${cid} has been unlinked.` };
  } catch (error) {
    // Log the error for debugging purposes
    console.error('Error unlinking user:', error);

    // Throw an HTTPS error to send back to the client
    throw new functions.https.HttpsError(
      'unknown',
      'An error occurred while unlinking the user.',
      (error as Error).message
    );
  }
});

exports.isUIDLinked = functions.https.onCall(async (data, context) => {
    try {
        const uid = data.uid;
        const usersCollectionID = data.usersCollectionID;
        if (!uid) {
            throw new functions.https.HttpsError('invalid-argument', 'The function must be called with a valid "uid".');
        }
        if (!usersCollectionID) {
            throw new functions.https.HttpsError('invalid-argument', 'The function must be called with a valid "usersCollectionID".');
        }

        const userSnapshot = await admin.firestore().collection(usersCollectionID).where('uid', '==', uid).get();
        const isLinked = !userSnapshot.empty;

        return { isLinked };
    } catch (error) {
        console.error('Error checking UID link status:', error);
        throw new functions.https.HttpsError('unknown', 'Failed to check UID link status', error);
    }
});


/**
 * Cloud Function to update 'uidGrantedAccess' when 'connectedUsers' changes.
 */
export const onConnectedUsersChange = functions.firestore
  .document('{userCollection}/{userId}')
  .onUpdate(async (change, context) => {
    const userCollection = context.params.userCollection;
    const userId = context.params.userId;

    const beforeData = change.before.data();
    const afterData = change.after.data();

    const beforeConnectedUsers = beforeData.connectedUsers || [];
    const afterConnectedUsers = afterData.connectedUsers || [];

    // Check if 'connectedUsers' has changed
    if (JSON.stringify(beforeConnectedUsers) === JSON.stringify(afterConnectedUsers)) {
      // No changes in 'connectedUsers'
      return null;
    }

    // Identify added and removed connected users
    const addedConnectedUsers = afterConnectedUsers.filter(
      (id: string) => !beforeConnectedUsers.includes(id)
    );
    const removedConnectedUsers = beforeConnectedUsers.filter(
      (id: string) => !afterConnectedUsers.includes(id)
    );

    const db = admin.firestore();
    const currentUserUid = afterData.uid;

    if (!currentUserUid) {
      console.log(`User ${userId} does not have a 'uid'. Skipping.`);
      return null;
    }

    const usersRef = db.collection(userCollection);

    // Handle added connected users
    const addPromises = addedConnectedUsers.map(async (connectedUserId: string) => {
      const connectedUserRef = usersRef.doc(connectedUserId);
      const connectedUserDoc = await connectedUserRef.get();

      if (!connectedUserDoc.exists) {
        console.log(`Connected user ${connectedUserId} does not exist. Skipping.`);
        return;
      }

      const connectedUserData = connectedUserDoc.data() as admin.firestore.DocumentData;
      let uidGrantedAccess: string[] = connectedUserData.uidGrantedAccess || [];

      // Ensure uidGrantedAccess is an array
      if (!Array.isArray(uidGrantedAccess)) {
        uidGrantedAccess = [];
      }

      if (!uidGrantedAccess.includes(currentUserUid)) {
        uidGrantedAccess.push(currentUserUid);
        await connectedUserRef.update({ uidGrantedAccess });
        console.log(`Added ${currentUserUid} to uidGrantedAccess of user ${connectedUserId}`);
      }
    });

    // Handle removed connected users
    const removePromises = removedConnectedUsers.map(async (connectedUserId: string) => {
      const connectedUserRef = usersRef.doc(connectedUserId);
      const connectedUserDoc = await connectedUserRef.get();

      if (!connectedUserDoc.exists) {
        console.log(`Connected user ${connectedUserId} does not exist. Skipping.`);
        return;
      }

      const connectedUserData = connectedUserDoc.data() as admin.firestore.DocumentData;
      let uidGrantedAccess: string[] = connectedUserData.uidGrantedAccess || [];

      // Ensure uidGrantedAccess is an array
      if (!Array.isArray(uidGrantedAccess)) {
        uidGrantedAccess = [];
      }

      if (uidGrantedAccess.includes(currentUserUid)) {
        uidGrantedAccess = uidGrantedAccess.filter((uid) => uid !== currentUserUid);
        await connectedUserRef.update({ uidGrantedAccess });
        console.log(`Removed ${currentUserUid} from uidGrantedAccess of user ${connectedUserId}`);
      }
    });

    // Wait for all promises to complete
    await Promise.all([...addPromises, ...removePromises]);

    console.log('uidGrantedAccess arrays have been updated successfully.');
    return null;
  });


/**
 * Cloud Function to update 'recipient' fields in activities when asset names change.
 */
export const onAssetUpdate = functions.firestore
  .document('/{userCollection}/{userId}/assets/{assetId}')
  .onUpdate(async (change, context) => {
    const { userCollection, userId, assetId } = context.params;
    console.log(`onAssetUpdate triggered for userCollection: ${userCollection}, userId: ${userId}`);

    const fund = assetId == 'agq' ? 'AGQ' : 'AK1'; // Adjust fund name based on assetId

    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Get asset entries excluding 'total' and 'fund'
    const beforeAssets = Object.entries(beforeData)
      .filter(([key]) => !['total', 'fund'].includes(key))
      .map(([key, value]) => ({ key, ...value }));
    const afterAssets = Object.entries(afterData)
      .filter(([key]) => !['total', 'fund'].includes(key))
      .map(([key, value]) => ({ key, ...value }));

    // Map assets by index (assuming index is unique and identifies the asset)
    const beforeAssetsByIndex = new Map(beforeAssets.map(asset => [asset.index, asset]));
    const afterAssetsByIndex = new Map(afterAssets.map(asset => [asset.index, asset]));

    // Identify assets where the displayTitle has changed
    const assetsToUpdate = [];

    for (const [index, beforeAsset] of beforeAssetsByIndex) {
      const afterAsset = afterAssetsByIndex.get(index);
      if (afterAsset && beforeAsset.displayTitle !== afterAsset.displayTitle) {
        assetsToUpdate.push({
          index,
          oldDisplayTitle: beforeAsset.displayTitle,
          newDisplayTitle: afterAsset.displayTitle,
        });
      }
    }

    console.log('assetsToUpdate:', assetsToUpdate);

    if (assetsToUpdate.length === 0) {
      console.log('No changes in displayTitles detected.');
      return null;
    }

    // Fetch the client's name
    const userDocRef = db.doc(`${userCollection}/${userId}`);
    const userDocSnap = await userDocRef.get();
    const clientData = userDocSnap.data();
    const clientName = clientData ? clientData.name.first + ' ' + clientData.name.last : null;
    
    if (!clientName) {
      console.error(`Client name not found for user ${userId}`);
      return null;
    }

    // Update activities based on displayTitle changes
    const activitiesRef = db.collection(`${userCollection}/${userId}/activities`);
    const batch = db.batch();

    for (const { oldDisplayTitle, newDisplayTitle } of assetsToUpdate) {
      let newRecipient = newDisplayTitle;
      let oldRecipient = oldDisplayTitle;

      // If the new display title is 'Personal', set the recipient to client's name
      if (newDisplayTitle === 'Personal') {
        newRecipient = clientName ?? newDisplayTitle;
      }

      if (oldDisplayTitle === 'Personal') {
        oldRecipient = clientName ?? oldDisplayTitle;
      }

      console.log(`Updating activities from "${oldDisplayTitle}" to "${newRecipient}"`);

      const snapshot = await activitiesRef
        .where('fund', '==', fund)
        .where('recipient', '==', oldRecipient)
        .get();

      console.log(`Found ${snapshot.size} activities to update for recipient: "${oldDisplayTitle}"`);

      snapshot.forEach((doc: QueryDocumentSnapshot) => {
        batch.update(doc.ref, { recipient: newRecipient });
      });
    }

    try {
      await batch.commit();
      console.log('Batch commit successful.');
    } catch (error) {
      console.error('Batch commit failed:', error);
    }

    console.log(`Updated recipient fields for user ${userId} in collection ${userCollection}.`);
    return null;
  });

/**
 * Cloud Function that triggers on creation, update, or deletion of an activity.
 */
export const onActivityWrite = functions.firestore
  .document(`/{userCollection}/{userId}/${config.ACTIVITIES_SUBCOLLECTION}/{activityId}`)
  .onWrite(async (change, context) => {
    const { userId, userCollection } = context.params;

    const startOfYear = new Date(new Date().getFullYear(), 0, 1);

    const getActivityDate = (activity: Activity): Date => {
      if (activity.time instanceof admin.firestore.Timestamp) {
        return activity.time.toDate();
      } else {
        return activity.time as Date;
      }
    };

    const doesAffectYTD = (activity: Activity): boolean => {
      const activityDate = getActivityDate(activity);
      return (
        activity.fund === 'AGQ' &&
        ['profit', 'income'].includes(activity.type) &&
        activityDate >= startOfYear
      );
    };

    let shouldUpdateYTD = false;

    if (!change.before.exists) {
      // **Activity created**
      const activity = change.after.data() as Activity;
      if (doesAffectYTD(activity)) {
        shouldUpdateYTD = true;
      }
    } else if (!change.after.exists) {
      // **Activity deleted**
      const activity = change.before.data() as Activity;
      if (doesAffectYTD(activity)) {
        shouldUpdateYTD = true;
      }
    } else {
      // **Activity updated**
      const beforeActivity = change.before.data() as Activity;
      const afterActivity = change.after.data() as Activity;
      const beforeAffectsYTD = doesAffectYTD(beforeActivity);
      const afterAffectsYTD = doesAffectYTD(afterActivity);
      if (beforeAffectsYTD || afterAffectsYTD) {
        shouldUpdateYTD = true;
      }
    }

    if (shouldUpdateYTD) {
      await updateYTD(userId, userCollection); // Update YTD for the user and connected users
    }

    // Generate graphpoints for this specific user
    await updateGraphpoints(userCollection, userId);

    return null;
  });

/**
 * Scheduled Cloud Function to reset ytd and totalYtd to 0 for all users on January 1st every year.
 */
export const scheduledYTDReset = functions.pubsub
  .schedule('0 0 1 1 *') // Runs at 00:00 on January 1st every year
  .timeZone('America/New_York') // Replace with your time zone, e.g., 'America/Los_Angeles'
  .onRun(async (context) => {
    const userCollection = config.FIRESTORE_ACTIVE_USERS_COLLECTION; // Replace with your user collection name if different

    try {
      // Get all users
      const usersSnapshot = await db.collection(userCollection).get();

      let batch = db.batch();
      let operationsCount = 0;
      const maxBatchSize = 500; // Firestore batch limit

      // Iterate over each user
      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;

        // Reference to the user's assets/general document
        const assetsGeneralRef = db
          .collection(userCollection)
          .doc(userId)
          .collection(config.ASSETS_SUBCOLLECTION)
          .doc(config.ASSETS_GENERAL_DOC_ID);

        // Update ytd and totalYtd to 0
        batch.update(assetsGeneralRef, {
          ytd: 0,
          totalYTD: 0,
        });

        operationsCount++;

        // Commit the batch every 500 operations
        if (operationsCount === maxBatchSize) {
          await batch.commit();
          batch = db.batch(); // Create a new batch instance
          operationsCount = 0;
        }
      }

      // Commit any remaining operations
      if (operationsCount > 0) {
        await batch.commit();
      }

      console.log('YTD totals successfully reset for all users.');
    } catch (error) {
      console.error('Error resetting YTD totals:', error);
      throw new Error('Failed to reset YTD totals.');
    }

    return null;
  });


/**
 * Scheduled Cloud Function to process scheduled activities.
 * Runs every minute and checks for activities where scheduledTime <= now and status is 'pending'.
 * Creates the actual activity and updates the scheduled activity's status to 'completed'.
 */
exports.processScheduledActivities = functions.pubsub.schedule('0 */12 * * *').onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const scheduledActivitiesRef = db.collection('scheduledActivities');
    const querySnapshot = await scheduledActivitiesRef
        .where('scheduledTime', '<=', now)
        .where('status', '==', 'pending')
        .get();
    
    console.log(`Found ${querySnapshot.size} scheduled activities to process.`);

    if (querySnapshot.empty) {
        console.log('No scheduled activities to process at this time.');
        return null;
    }

    const batch = db.batch();

    querySnapshot.forEach(doc => {
        const data = doc.data();
        const { cid, activity, clientState, usersCollectionID } = data;

        if (!cid || !activity) {
            console.error(`Scheduled activity ${doc.id} is missing 'cid' or 'activity' fields.`);
            return;
        }

        const clientRef = db.collection(usersCollectionID).doc(cid); // Adjust collection name if different
        const activitiesRef = clientRef.collection(config.ACTIVITIES_SUBCOLLECTION);
        const newActivityRef = activitiesRef.doc(); // Auto-generated ID

        batch.set(newActivityRef, {
            ...activity,
            parentCollection: usersCollectionID, // Adjust if different
            formattedTime: admin.firestore.FieldValue.serverTimestamp(), // Or format as needed
        });

        if (clientState) {
            const assetCollectionRef = clientRef.collection(config.ASSETS_SUBCOLLECTION);

            // // Filter out assets with amount 0
            // const agqAssets = this.filterAssets(client.assets.agq);
            // const ak1Assets = this.filterAssets(client.assets.ak1);

            const agqAssets = clientState.assets.agq;
            const ak1Assets = clientState.assets.ak1;

            const prepareAssetDoc = (assets: { [assetType: string]: AssetDetails }, fundName: string) => {
                let total = 0;
                const assetDoc: any = { fund: fundName };
                Object.keys(assets).forEach(assetType => {
                    const asset = assets[assetType];
                    assetDoc[assetType] = {
                        amount: asset.amount,
                        firstDepositDate: asset.firstDepositDate ? Timestamp.fromDate(asset.firstDepositDate) : null,
                        displayTitle: asset.displayTitle,
                        index: asset.index,
                    };
                    total += asset.amount;
                });
                assetDoc.total = total;
                return assetDoc;
            };

            const agqDoc = prepareAssetDoc(agqAssets, 'AGQ');
            const ak1Doc = prepareAssetDoc(ak1Assets, 'AK1');

            const general = {
                ytd: clientState.ytd ?? 0,
                totalYTD: clientState.totalYTD ?? 0,
                total: agqDoc.total + ak1Doc.total,
            };

            const agqRef = assetCollectionRef.doc(config.ASSETS_AGQ_DOC_ID);
            const ak1Ref = assetCollectionRef.doc(config.ASSETS_AK1_DOC_ID);
            const genRef = assetCollectionRef.doc(config.ASSETS_GENERAL_DOC_ID);

            batch.update(agqRef, agqDoc);
            batch.update(ak1Ref, ak1Doc);
            batch.update(genRef, general);
        }
        // Update the scheduled activity's status to 'completed'
        const scheduledActivityRef = scheduledActivitiesRef.doc(doc.id);
        batch.update(scheduledActivityRef, { status: 'completed' });
    });

    try {
        await batch.commit();
        console.log(`Processed ${querySnapshot.size} scheduled activities.`);
    } catch (error) {
        console.error('Error processing scheduled activities:', error);
    }

    return null;
});

async function updateGraphpoints(userCollection: string, userId: string): Promise<void> {
    const userRef = db.collection(userCollection).doc(userId);
    const activitiesRef = userRef.collection(config.ACTIVITIES_SUBCOLLECTION);
    const graphpointsRef = userRef.collection(config.GRAPHPOINTS_SUBCOLLECTION);

    // Clear existing graphpoints
    const existingGraphpoints = await graphpointsRef.get();
    const deletePromises = existingGraphpoints.docs.map(doc => doc.ref.delete());
    await Promise.all(deletePromises);

    // Retrieve client name
    const userDoc = await userRef.get();
    const cid = userDoc.id;
    const userData = userDoc.data() || {};
    const fullName = userData.name ? `${userData.name.first} ${userData.name.last}` : null;
    
    // Retrieve and sort activities by time
    const activitiesSnapshot = await activitiesRef.orderBy('time').get();

    let cumulativeBalance = 0;
    const accountBalances: Record<string, number> = {};
    let fundsMap: Record<string, {cumulativeBalance: number, accountBalances: Record<string, number>}> = {};

    // Process relevant activities to generate new graphpoints
    for (const activityDoc of activitiesSnapshot.docs) {
        const activity = activityDoc.data();

        if (
            activity.type === 'deposit' ||
            activity.type === 'withdrawal' ||
            activity.isDividend
        ) {
            const cashflow = activity.amount * (activity.type === 'withdrawal' ? -1 : 1);
            const time = activity.time;
            let account;
            if (activity.recipient === fullName) {
                account = 'Personal';
            } else {
                account = activity.recipient;
            }
            const fund = activity.fund || 'Unspecified';

            // Update cumulative balance
            cumulativeBalance += cashflow;

            // Update account-specific balance
            if (!accountBalances[account]) {
                accountBalances[account] = 0;
            }
            accountBalances[account] += cashflow;

            if (!fundsMap[fund]) {
            fundsMap[fund] = {
                cumulativeBalance: 0,
                accountBalances: {}
            };
            }
            fundsMap[fund].cumulativeBalance += cashflow;

            if (!fundsMap[fund].accountBalances[account]) {
                fundsMap[fund].accountBalances[account] = 0;
            }
            fundsMap[fund].accountBalances[account] += cashflow;

            // Prepare graphpoints
            const cumulativeGraphpoint = {
                account: 'Cumulative',
                amount: fundsMap[fund].cumulativeBalance,
                cashflow: cashflow,
                time: time,
                fund: fund,
            };

            const accountGraphpoint = {
                account: account,
                amount: fundsMap[fund].accountBalances[account],
                cashflow: cashflow,
                time: time,
                fund: fund,
            };

            // Add graphpoints
            try {
                await graphpointsRef.add(cumulativeGraphpoint);
                console.log(`Added cumulative graphpoint for user CID: ${cid} at time: ${time.toDate()}`);

                await graphpointsRef.add(accountGraphpoint);
                console.log(`Added graphpoint for account '${account}' for user CID: ${cid} at time: ${time.toDate()}`);
            } catch (addError) {
                console.error(`Error adding graphpoints for user CID: ${cid}:`, addError);
                throw addError;
            }
        }
    }
}