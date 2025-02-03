const admin = require('firebase-admin');
const path = require('path');
const countries = require('../src/utils/countries.json');
const states = require('../src/utils/states.json');
const provinces = require('../src/utils/provinces.json');

// Path to the service account key file
const serviceAccountPath = path.join(__dirname, 'team-shaikh-service-account.json');
const serviceAccount = require(serviceAccountPath);

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

/**
 * Parses an address string into its components.
 *
 * @param {string} address - The address string to parse.
 * @returns {Object|null} An object containing street, city, state/province, country, and zip or null if parsing fails.
 */
function parseAddress(address) {
    // Regex patterns for US and Canadian addresses
    const usRegex = /^([^,]+),\s*([^,]+),\s*([A-Z]{2})\s*(\d{5}(?:-\d{4})?)$/i;
    const caRegex = /^([^,]+),\s*([^,]+),\s*([A-Za-z]+)\s*([A-Z]\d[A-Z] \d[A-Z]\d)\s*(?:CANADA)?$/i;
    // Regex pattern for UK addresses
    const ukRegex = /^([^,]+),\s*([^,]+),\s*([A-Z]{1,2}\d{1,2}[A-Z]?\s*\d[A-Z]{2})\s*(UK)$/i;

    let match = address.match(usRegex);
    if (match) {
        const [, street, city, stateCode, zip] = match;
        return {
            street: street.trim(),
            city: city.trim(),
            state: stateCode.trim().toUpperCase(),
            country: 'US',
            zip: zip.trim(),
        };
    }

    match = address.match(caRegex);
    if (match) {
        const [, street, city, provinceName, zip] = match;
        const province = provinces.find(
            (prov) => prov.name.toLowerCase() === provinceName.toLowerCase()
        );
        if (!province) {
            console.warn(`Province name '${provinceName}' not found.`);
            return null;
        }
        return {
            street: street.trim(),
            city: city.trim(),
            province: province.code,
            country: 'CA',
            zip: zip.trim(),
        };
    }

    match = address.match(ukRegex);
    if (match) {
        const [, street, city, zip, country] = match;
        return {
            street: street.trim(),
            city: city.trim(),
            country: country.trim().toUpperCase(),
            zip: zip.trim(),
        };
    }

    console.warn(`Address format not recognized: ${address}`);
    return null;
}

/**
 * Updates address fields in documents of the specified collection based on the existing 'address' property.
 *
 * @param {string} collectionName - The name of the collection, e.g., 'playground'.
 */
async function updateAddresses(collectionName) {
    console.log(`Starting address update for collection '${collectionName}'`);

    const collectionRef = db.collection(collectionName);

    try {
        const snapshot = await collectionRef.get();
        console.log(`Found ${snapshot.size} documents in collection '${collectionName}'`);

        for (const doc of snapshot.docs) {
            const data = doc.data();
            const address = data.address;

            if (!address) {
                console.warn(`Document ${doc.id} does not have an address field.`);
                continue;
            }

            const parsed = parseAddress(address);

            if (!parsed) {
                console.warn(`Failed to parse address for document ${doc.id}: ${address}`);
                continue;
            }

            await doc.ref.update(parsed);
            console.log(`Updated address fields for document ${doc.id}`);
        }

        console.log(`Successfully updated addresses for collection '${collectionName}'`);
    } catch (error) {
        console.error(`Error updating addresses for collection '${collectionName}':`, error);
        throw error;
    }
}

// Example usage
const collectionName = 'playground'; // Replace with your actual collection name
updateAddresses(collectionName)
    .then(() => {
        console.log('Address update completed successfully');
        process.exit(0);
    })
    .catch((error) => {
        console.error('Address update failed:', error);
        process.exit(1);
    });
