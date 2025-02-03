const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');
const { Timestamp } = require('firebase-admin/firestore');

// Path to the service account key file
const serviceAccountPath = path.join(__dirname, 'team-shaikh-service-account.json');
const serviceAccount = require(serviceAccountPath);

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

(async function generateYTDReport2024() {
  const db = admin.firestore();
  const startOf2024 = new Date(2024, 0, 1);
  const endOf2024 = new Date(2024, 11, 31, 23, 59, 59);

  let csvLines = ["First Name,Last Name,Account,Total Profit 2024"];

  try {
    const usersSnapshot = await db.collection('users').get();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();
      const firstName = userData.name?.first || '';
      const lastName = userData.name?.last || '';

      // Query activities of type 'profit' in 2024
      const activitiesRef = db
        .collection('users')
        .doc(userId)
        .collection('activities');
      const querySnapshot = await activitiesRef
        .where('type', '==', 'profit')
        .where('time', '>=', Timestamp.fromDate(startOf2024))
        .where('time', '<=', Timestamp.fromDate(endOf2024))
        .get();

    const totalProfit2024ByAccount = new Proxy({}, {
        get: (target, key) => (key in target ? target[key] : 0),
        set: (target, key, value) => {
            target[key] = value;
            return true;
        }
    });
      querySnapshot.forEach((activityDoc) => {
        const activityData = activityDoc.data();
        totalProfit2024ByAccount[activityData.recipient] += activityData.amount || 0;
      });

      for (const [recipient, total] of Object.entries(totalProfit2024ByAccount)) {
        const updatedRecipient = (recipient === `${firstName} ${lastName}`) ? 'Personal' : recipient;
        csvLines.push(`${firstName},${lastName},${updatedRecipient},${total}`);
      }
    }

    // Sort csvLines by FirstName in alphabetical order
    const header = csvLines[0];
    const dataLines = csvLines.slice(1).sort((a, b) => {
      const firstNameA = a.split(',')[0].toLowerCase();
      const firstNameB = b.split(',')[0].toLowerCase();
      return firstNameA.localeCompare(firstNameB);
    });
    csvLines = [header, ...dataLines];

    // Write CSV to a file instead of logging to console
    fs.writeFile('ytd-report-2024.csv', csvLines.join("\n"), (err) => {
      if (err) {
        console.error('Error writing CSV file:', err);
        process.exit(1);
      } else {
        console.log('CSV file has been saved.');
        process.exit(0);
      }
    });
  } catch (error) {
    console.error('Error generating YTD report:', error);
    process.exit(1);
  }
})();