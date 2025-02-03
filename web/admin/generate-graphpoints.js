const admin = require("firebase-admin");
const path = require("path");

// Path to the service account key file
const serviceAccountPath = path.join(__dirname, 'team-shaikh-service-account.json');
const serviceAccount = require(serviceAccountPath);

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

/**
 * Generates graphpoints for all users in the specified collection.
 * Utilizes Promise.all to process multiple users in parallel for enhanced performance.
 *
 * @param {string} usersCollectionID - The name of the users collection.
 */
async function generateGraphpoints(usersCollectionID) {
  console.log(`Starting graphpoints generation for collection '${usersCollectionID}'`);

  const usersRef = db.collection(usersCollectionID);
  
  try {
    const usersSnapshot = await usersRef.orderBy('name').get();
    console.log(`Found ${usersSnapshot.size} users in collection '${usersCollectionID}'`);

    // Process all users in parallel
    const userPromises = usersSnapshot.docs.map(async (userDoc) => {
      const cid = userDoc.id;
      console.log(`Processing user CID: ${cid}`);

      const userRef = usersRef.doc(cid);
      const activitiesRef = userRef.collection('activities');
      const graphpointsRef = userRef.collection('graphpoints');

      // Retrieve user data
      const userData = userDoc.data();
      const fullName = `${userData.name.first} ${userData.name.last}`;

      // Clear existing graphpoints
      try {
        const existingGraphpoints = await graphpointsRef.get();
        if (!existingGraphpoints.empty) {
          const deletePromises = existingGraphpoints.docs.map(doc => {
            console.log(`Deleting graphpoint ID: ${doc.id} for user CID: ${cid}`);
            return doc.ref.delete();
          });
          await Promise.all(deletePromises);
          console.log(`Cleared existing graphpoints for user CID: ${cid}`);
        } else {
          console.log(`No existing graphpoints found for user CID: ${cid}`);
        }
      } catch (deleteError) {
        console.error(`Error clearing graphpoints for user CID: ${cid}:`, deleteError);
        throw deleteError;
      }

      // Retrieve activities sorted by time
      let activitiesSnapshot;
      try {
        activitiesSnapshot = await activitiesRef.orderBy('time').get();
        console.log(`Retrieved ${activitiesSnapshot.size} activities for user CID: ${cid}`);
      } catch (activitiesError) {
        console.error(`Error retrieving activities for user CID: ${cid}:`, activitiesError);
        throw activitiesError;
      }

      let cumulativeBalance = 0;
      const accountBalances = {};
      let fundsMap = {};

      // Process activities sequentially to maintain balance integrity
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

      console.log(`Completed graphpoints generation for user CID: ${cid}`);
    });

    // Wait for all users to be processed
    await Promise.all(userPromises);
    console.log(`Successfully generated graphpoints for all users in collection '${usersCollectionID}'`);

    // Generate overall graphpoints
    await generateOverallGraphpoints();
  } catch (error) {
    console.error(`Error generating graphpoints for collection '${usersCollectionID}':`, error);
    throw error;
  }
}

/**
 * Generates overall graphpoints for total assets under management using collectionGroup.
 *
 * @param {string} usersCollectionID - The name of the users collection.
 */
async function generateOverallGraphpoints(usersCollectionID) {
  console.log(`Starting overall graphpoints generation using collectionGroup`);

  try {
    const activitiesQuery = db.collectionGroup('activities').orderBy('time');
    const activitiesSnapshot = await activitiesQuery.get();
    console.log(`Retrieved ${activitiesSnapshot.size} activities using collectionGroup`);

    const overallGraphpointsRef = db.collection('graphpoints');
    const existingGraphpoints = await overallGraphpointsRef.get();
    if (!existingGraphpoints.empty) {
        const deletePromises = existingGraphpoints.docs.map(doc => {
          console.log(`Deleting graphpoint ID: ${doc.id} in overall graphpoints`);
          return doc.ref.delete();
        });
        await Promise.all(deletePromises);
        console.log(`Cleared existing graphpoints`);
    } else {
        console.log(`No existing graphpoints found`);
    }

    let fundsMap = {};
    let cumulativeBalance = 0;

    const activityPromises = activitiesSnapshot.docs.map(async (activityDoc) => {
        
        const activity = activityDoc.data();

        if (
            activity.type === 'deposit' ||
            activity.type === 'withdrawal' ||
            activity.isDividend
          )
        {
            const cashflow = activity.amount * (activity.type === 'withdrawal' ? -1 : 1);
            const time = activity.time;
            const fund = activity.fund || 'Unspecified';

            if (!fundsMap[fund]) {
                fundsMap[fund] = 0;
            }
            fundsMap[fund] += cashflow;
            cumulativeBalance += cashflow;

            // Prepare graphpoints
            const cumulativeGraphpoint = {
                fund: 'Cumulative',
                amount: cumulativeBalance,
                cashflow: cashflow,
                time: time,
                usersCollection: usersCollectionID,
            };

            const fundGraphpoint = {
                fund: activity.fund,
                amount: fundsMap[fund],
                cashflow: cashflow,
                time: time,
                usersCollection: usersCollectionID,
            };
            // Add graphpoints
            try {
                await overallGraphpointsRef.add(cumulativeGraphpoint);
                console.log(`Added cumulative graphpoint at time: ${time.toDate()}`);
        
                await overallGraphpointsRef.add(fundGraphpoint);
                console.log(`Added graphpoint for fund '${fund}' at time: ${time.toDate()}`);
              } catch (addError) {
                console.error(`Error adding overall graphpoints:`, addError);
                throw addError;
              }
        }
    });

    await Promise.all(activityPromises);
    console.log(`Successfully generated overall graphpoints using collectionGroup`);
  } catch (error) {
    console.error(`Error generating overall graphpoints:`, error);
    throw error;
  }
}

// Example usage
const usersCollectionID = 'playground'; // Replace with your actual users collection name
generateOverallGraphpoints(usersCollectionID)
  .then(() => {
    console.log('Graphpoints generation completed successfully');
    process.exit(0); // Exit successfully
  })
  .catch(error => {
    console.error('Graphpoints generation failed:', error);
    process.exit(1); // Exit with failure
  });