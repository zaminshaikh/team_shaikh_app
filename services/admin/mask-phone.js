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
 * Masks a phone number to the format (XXX) XXX-XXXX.
 *
 * @param {string} phoneNumber - The original phone number string.
 * @returns {string} The masked phone number.
 */
function maskPhoneNumber(phoneNumber) {
    // Remove all non-digit characters
    let digits = phoneNumber.replace(/\D/g, '');
    
    // Remove leading '1' if number has 11 digits
    if (digits.length === 11 && digits.startsWith('1')) {
        digits = digits.slice(1);
    }

    // Pad with zeros if less than 10 digits
    if (digits.length < 10) {
        digits = digits.padStart(10, '0');
    }

    // Truncate to 10 digits if longer
    if (digits.length > 10) {
        digits = digits.slice(-10);
    }

    // Format the phone number
    const masked = `(${digits.slice(0, 3)}) ${digits.slice(3, 6)}-${digits.slice(6, 10)}`;
    return masked;
}

/**
 * Updates the phoneNumber field for all documents in the specified collection.
 *
 * @param {string} collectionName - The name of the collection, e.g., 'playground'.
 */
async function maskPhoneNumbersInCollection(collectionName) {
    console.log(`Starting phone number masking for collection '${collectionName}'`);

    const collectionRef = db.collection(collectionName);

    try {
        const snapshot = await collectionRef.get();
        console.log(`Found ${snapshot.size} documents in collection '${collectionName}'`);

        for (const doc of snapshot.docs) {
            const data = doc.data();
            const originalPhone = data.phoneNumber;

            if (!originalPhone) {
                console.warn(`Document ${doc.id} does not have a phoneNumber field.`);
                continue;
            }

            const maskedPhone = maskPhoneNumber(originalPhone);

            await doc.ref.update({ phoneNumber: maskedPhone });
            console.log(`Masked phone number for document ${doc.id}: ${maskedPhone}`);
        }

        console.log(`Successfully masked phone numbers for collection '${collectionName}'`);
    } catch (error) {
        console.error(`Error masking phone numbers for collection '${collectionName}':`, error);
        throw error;
    }
}

// Example usage
const collectionName = 'playground'; // Replace with your actual collection name
maskPhoneNumbersInCollection(collectionName)
    .then(() => {
        console.log('Phone number masking completed successfully');
        process.exit(0);
    })
    .catch((error) => {
        console.error('Phone number masking failed:', error);
        process.exit(1);
    });
