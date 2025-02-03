import { collection, getFirestore, getDocs, getDoc, doc, Firestore, CollectionReference, DocumentData, addDoc, setDoc, deleteDoc, collectionGroup, DocumentSnapshot, where, query, writeBatch} from 'firebase/firestore'
import { app } from '../App.tsx'
import 'firebase/firestore'
import config from '../../config.json'
import 'firebase/firestore'
import { Timestamp } from 'firebase/firestore';
import { getFunctions, httpsCallable } from "firebase/functions";
import { formatDate } from 'src/utils/utilities.ts'

const functions = getFunctions();

export interface AssetDetails {
    amount: number;
    firstDepositDate: Date | null;
    displayTitle: string;
    index: number;
}

/**
 * Client interface representing a client in the Firestore database.
 *  
 * .cid - The document ID of the client (the Client ID)
 * 
 * .uid - The client's UID, or the empty string if they have not signed up
 */
export interface Client {
    cid: string;
    uid: string;
    firstName: string;
    lastName: string;
    companyName: string;
    address: string;
    province: string
    state: string
    street: string
    city: string
    zip: string
    country: string
    dob: Date | null;
    phoneNumber: string;
    appEmail: string;
    initEmail: string;
    firstDepositDate: Date | null;
    beneficiaries: string[];
    connectedUsers: string[];
    totalAssets: number;
    ytd: number;
    totalYTD: number;
    _selected?: boolean;
    lastLoggedIn?: string | null | undefined;
    notes?: string | undefined;
    activities?: Activity[];
    graphPoints?: GraphPoint[];
    assets: {
        [fundKey: string]: {
            [assetType: string]: AssetDetails;
        };
    };
}

export interface Activity {
    id?: string;
    notes?: string | number | string[] | undefined
    // selected?: boolean;
    parentDocId?: string;
    amount: number;
    fund: string;
    recipient: string;
    time: Date;
    formattedTime?: string;
    type: string;
    isDividend?: boolean;
    sendNotif?: boolean;
    amortizationCreated?: boolean;
    isAmortization?: boolean
    principalPaid?: number | undefined
    profitPaid?: number | undefined
    parentName: string;
}

export interface ScheduledActivity {
    id: string;
    cid: string;
    activity: Activity;
    clientState: Client;
    status: string;
    scheduledTime: Date;
    usersCollectionID: string;
}

export interface Notification {
    activityId: string;
    recipient: string;
    title: string;
    body: string;
    message: string;
    isRead: boolean;
    type: string;
    time: Date | Timestamp;
}

export interface GraphPoint {
    time: Date | Timestamp | null;
    amount: number | null;
}

export interface StatementData {
    statementTitle: string;
    downloadURL: string;
    clientId: string;
    // Add other necessary fields here
}
  

export const emptyClient: Client = {
    firstName: '',
    lastName: '',
    companyName: '',
    address: '',
    province: '',
    state: '',
    street: '',
    city: '',
    zip: '',
    country: 'US',
    dob: null,
    phoneNumber: '',
    firstDepositDate: null,
    beneficiaries: [],
    connectedUsers: [],
    cid: '',
    uid: '',
    appEmail: '',
    initEmail: '',
    totalAssets: 0,
    ytd: 0,
    totalYTD: 0,
    assets: {
        agq: {
            personal: {
                amount: 0,
                firstDepositDate: null,
                displayTitle: 'Personal',
                index: 0,
            },
        },
        ak1: {
            personal: {
                amount: 0,
                firstDepositDate: null,
                displayTitle: 'Personal',
                index: 0,
            },
        },
    },
};

export const roundToNearestHour = (date: Date): Date => {
    const minutes = date.getMinutes();
    const roundedDate = new Date(date);

    if (minutes >= 30) {
        roundedDate.setHours(date.getHours() + 1);
    }
    
    roundedDate.setMinutes(0, 0, 0); // Reset minutes, seconds, and milliseconds to 0

    return roundedDate;
};

export const emptyActivity: Activity = {
    amount: 0,
    fund: 'AGQ',
    recipient: '',
    time: roundToNearestHour(new Date()),
    type: 'profit',
    isDividend: false,
    sendNotif: true,
    isAmortization: false,
    notes: undefined,
    parentName: '',
};

/**
 * Formats a number as a currency string.
 *
 * This function takes a number as input and returns a string that represents
 * the number formatted as a currency in US dollars. The formatting is done
 * using the built-in `Intl.NumberFormat` object with 'en-US' locale and 'USD'
 * as the currency.
 *
 * @param amount - The number to be formatted as currency.
 * @returns The formatted currency string.
 *
 * @example
 * ```typescript
 * const amount = 1234.56;
 * const formattedAmount = formatCurrency(amount);
 * ```
 */
export const formatCurrency = (amount: number): string => {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount);
}


export class DatabaseService {

    private db: Firestore = getFirestore(app);
    private clientsCollection: CollectionReference<DocumentData, DocumentData>;
    private cidArray: string[];

    constructor() {
        this.clientsCollection = collection(this.db, config.FIRESTORE_ACTIVE_USERS_COLLECTION);
        this.cidArray = [];
        this.initCIDArray();
    }

    /**
     * Asynchronously initializes the `cidArray` property with all the Client IDs from the 'testClients' collection in Firestore.
     *
     * This function performs the following steps:
     * 1. It fetches all documents from the 'testClients' collection in Firestore.
     * 2. It iterates over each document in the query snapshot and adds the document ID to the `cidArray`.
     * 3. It logs the `cidArray` to the console.
     */
    async initCIDArray() {
        const querySnapshot = await getDocs(this.clientsCollection);
        for (const doc of querySnapshot.docs) {
            this.cidArray.push(doc.id);
        }
    }

    /**
     * Hashes the input string to generate a unique ID, handling collisions by checking against existing IDs.
     *
     * @param input - The string to hash.
     * @returns A unique 8-digit ID.
     */
    async hash(input: string): Promise<string> {

        function fnv1aHash(input: string): number {
            let hash = 2166136261; // FNV offset basis
            for (let i = 0; i < input.length; i++) {
                hash ^= input.charCodeAt(i);
                hash += (hash << 1) + (hash << 4) + (hash << 7) + (hash << 8) + (hash << 24);
            }
            return hash >>> 0; // Convert to unsigned 32-bit integer
        }

        const generateUniqueID = (baseID: string): string => {
            let uniqueID = baseID;
            let counter = 1;

            // Check for collisions and modify the ID if necessary
            while (this.cidArray.includes(uniqueID)) {
                uniqueID = (parseInt(baseID, 10) + counter).toString().padStart(8, '0');
                counter++;
            }
            return uniqueID;
        };

        const hash = fnv1aHash(input);
        const baseID = (hash % 100000000).toString().padStart(8, '0');
        const id = generateUniqueID(baseID);
        this.cidArray.push(id); // Add the new unique ID to the array
        return id;
    }

    /**
     * Fetches all clients from the 'testClients' collection in Firestore.
     * For each client, it also fetches their total assets from the 'assets' subcollection.
     * 
     * @returns An array of client objects, each with the following properties:
     * - cid: The document ID of the client (the Client ID).
     * - firstname: The client's first name.
     * - lastname: The client's last name.
     * - company: The client's company.
     * - email: The client's email, or a default message if not set.
     * - uid: The client's UID, or the empty string if they have not signed up
     * - connectedUsers: The client's connected clients.
     * - totalAssets: The client's total assets.
     * - formattedAssets: The client's total assets, formatted as a currency string.
     */
    getClients = async () => {
        // Fetch all documents from the clients collection
        const querySnapshot = await getDocs(this.clientsCollection);

        // Initialize an empty array to hold the client objects
        const clients: Client[] = [];

        // Use Promise.all to fetch all clients concurrently
        const clientPromises = querySnapshot.docs.map(async (clientSnapshot) => {
            // Get a reference to the 'assets' subcollection for this client
            const assetsSubcollection = collection(this.clientsCollection, clientSnapshot.id, config.ASSETS_SUBCOLLECTION);

            // References to each doc in assets subcollection
            const generalAssetsDoc = doc(assetsSubcollection, config.ASSETS_GENERAL_DOC_ID);
            const agqAssetsDoc = doc(assetsSubcollection, config.ASSETS_AGQ_DOC_ID);
            const ak1AssetsDoc = doc(assetsSubcollection, config.ASSETS_AK1_DOC_ID);

            // Fetch all the assets documents concurrently
            const [generalAssetsSnapshot, agqAssetsSnapshot, ak1AssetsSnapshot] = await Promise.all([
                getDoc(generalAssetsDoc),
                getDoc(agqAssetsDoc),
                getDoc(ak1AssetsDoc),
            ]);

            // Process the snapshots to create the client object
            return this.getClientFromSnapshot(clientSnapshot, generalAssetsSnapshot, agqAssetsSnapshot, ak1AssetsSnapshot);
        });

        // Wait for all client processing promises to resolve
        const processedClients = await Promise.all(clientPromises);

        // Filter out any null values in case some clients couldn't be created
        clients.push(...processedClients.filter(client => client !== null));

        // Return the array of client objects
        return clients;
    };

    getClientFromSnapshot = (
        clientSnapshot: DocumentSnapshot,
        generalAssetsSnapshot: DocumentSnapshot,
        agqAssetsSnapshot: DocumentSnapshot,
        ak1AssetsSnapshot: DocumentSnapshot
    ): Client | null => {
        if (!clientSnapshot.exists()) {
            return null;
        }

        const data = clientSnapshot.data();
        const generalAssetsData = generalAssetsSnapshot.data();
        const agqAssetsData = agqAssetsSnapshot.data();
        const ak1AssetsData = ak1AssetsSnapshot.data();

        const parseAssetsData = (assetsData: any): { [assetType: string]: AssetDetails } => {
            const parsedAssets: { [assetType: string]: AssetDetails } = {};
            if (assetsData) {
                Object.keys(assetsData).forEach(assetType => {
                    if (assetType !== 'fund' && assetType !== 'total') {
                        const asset = assetsData[assetType];
                        parsedAssets[assetType] = {
                            amount: asset.amount ?? 0,
                            firstDepositDate: asset.firstDepositDate?.toDate?.() ?? null,
                            displayTitle: asset.displayTitle ?? '',
                            index: asset.index ?? 0, // Include index
                        };
                    }
                });
            }
            return parsedAssets;
        };

        const client: Client = {
            cid: clientSnapshot.id,
            uid: data?.uid ?? '',
            firstName: data?.name?.first ?? '',
            lastName: data?.name?.last ?? '',
            companyName: data?.name?.company ?? '',
            address: data?.address ?? '',
            province: data?.province ?? '',
            state: data?.state ?? '',
            street: data?.street ?? '',
            city: data?.city ?? '',
            zip: data?.zip ?? '',
            country: data?.country ?? '',
            dob: data?.dob?.toDate() ?? null,
            initEmail: data?.initEmail ?? data?.email ?? '',
            appEmail: data?.appEmail ?? data?.email ?? 'Client has not logged in yet',
            connectedUsers: data?.connectedUsers ?? [],
            totalAssets: generalAssetsData ? generalAssetsData.total : 0,
            ytd: generalAssetsData ? generalAssetsData.ytd : 0,
            totalYTD: generalAssetsData ? generalAssetsData.totalYTD : 0,
            phoneNumber: data?.phoneNumber ?? '',
            firstDepositDate: data?.firstDepositDate?.toDate() ?? null,
            beneficiaries: data?.beneficiaries ?? [],
            lastLoggedIn: data?.lastLoggedIn instanceof Timestamp
                ? formatDate(data?.lastLoggedIn?.toDate()) // If the lastLoggedIn field is a valid date, format it
                : ((data?.uid && data?.uid != '') // Else we'll check if the user has logged in before
                    ? 'Before 01/25' // If they have, it was before we added the feature to track last login
                    : 'N/A'), // If they haven't, we'll display N/A, because they have not linked their account
            _selected: false,
            notes: data?.notes ?? '',
            assets: {
                agq: parseAssetsData(agqAssetsData), // Dynamically parse AGQ assets
                ak1: parseAssetsData(ak1AssetsData), // Dynamically parse AK1 assets
            },
        };

        return client;
    };

    getClient = async (cid: string) => {
        const clientRef = doc(this.db, config.FIRESTORE_ACTIVE_USERS_COLLECTION, cid);
        const clientSnapshot = await getDoc(clientRef);
        // Get a reference to the 'assets' subcollection for this client
        const assetsSubcollection = collection(this.clientsCollection, cid, config.ASSETS_SUBCOLLECTION)

        // References to each doc in assets subcollection, one for each fund and a general overview doc
        const generalAssetsDoc = doc(assetsSubcollection, config.ASSETS_GENERAL_DOC_ID)
        const agqAssetsDoc = doc(assetsSubcollection, config.ASSETS_AGQ_DOC_ID)
        const ak1AssetsDoc = doc(assetsSubcollection, config.ASSETS_AK1_DOC_ID)

        // Use the references to fetch the snapshots of the documents
        const generalAssetsSnapshot = await getDoc(generalAssetsDoc)
        const agqAssetsSnapshot = await getDoc(agqAssetsDoc)
        const ak1AssetsSnapshot = await getDoc(ak1AssetsDoc)

        return this.getClientFromSnapshot(clientSnapshot, generalAssetsSnapshot, agqAssetsSnapshot, ak1AssetsSnapshot);
    }

    /**
     * Asynchronously creates a new client in the Firestore database.
     *
     * @param newClient - The client object to be created. It should be of type `Client`.
     * 
     * The `Client` object should have the following properties:
     * - firstName: string
     * - lastName: string
     * - companyName: string
     * - email: string
     * - cid: string
     * - assets: object
     *   - agq: object
     *   - ak1: object
     *
     * This function performs the following steps:
     * 1. It creates a new `DocumentData` object from the `newClient` object, with a `name` property that is an object containing `first`, `last`, and `company` properties.
     * 2. It deletes the `firstName`, `lastName`, `companyName`, `email`, `cid`, and `assets` properties from the `newClientDocData` object.
     * 3. It generates a new document ID by hashing the client's first and last name.
     * 4. It creates a new document in the Firestore database with the new ID and the `newClientDocData` object.
     * 5. It creates `agqDoc` and `ak1Doc` objects from the `agq` and `ak1` properties of the `assets` property of the `newClient` object. Each object has a `fund` property and a `total` property, which is the sum of all the values in the object.
     * 6. It creates a `general` object with a `total` property that is the sum of the `total` properties of the `agqDoc` and `ak1Doc` objects.
     * 7. It creates a new collection in the Firestore database under the new client document.
     * 8. It creates new documents in the new collection with the `agqDoc`, `ak1Doc`, and `general` objects.
     * 9. It logs the `agqDoc` and `ak1Doc` objects to the console.
     *
     * @returns {Promise<void>} Returns a Promise that resolves when the client and associated documents have been created in the Firestore database.
     */
    createClient = async (newClient: Client) => {

        // Using the passed email, first name, and initial email to create a unique 8 digit CID using our hash function
        const newClientDocId = await this.hash(newClient.firstName + '-' + newClient.lastName + '-' + newClient.initEmail);

        newClient = {...newClient, cid: newClientDocId};
        // Since the CID is unique, this will create a unique client in the database
        await this.setClient(newClient);
    }

    /**
     * Asynchronously sets the client doc in the Firestore database for the given CID
     * 
     * @param client 
     * @param cid 
     * 
     */
    setClient = async (client: Client) => {
        // Create a new DocumentData object from the newClient object, with a name property that is an object containing first, last, and company properties.
        let newClientDocData: DocumentData = {
            ...client,
            name: {
                first: client.firstName.trimEnd(),
                last: client.lastName.trimEnd(),
                company: client.companyName.trimEnd(),
            },
        };

        // Delete these unused properties from the newClientDocData object
        ['firstName', 'lastName', 'companyName', 'email', 'cid', 'assets', 'activities', 'totalAssets', 'graphPoints', 'ytd', 'totalYTD'].forEach(key => {
                delete newClientDocData[key];
        });

        // Remove any fields with undefined values
        newClientDocData = Object.fromEntries(
            Object.entries(newClientDocData).filter(([_, value]) => value !== undefined)
        );

        // Create a reference with the CID.
        const clientRef = doc(this.db, config.FIRESTORE_ACTIVE_USERS_COLLECTION, client.cid);

        // Updates/Creates the document with the CID
        await setDoc(clientRef, newClientDocData, { merge: true });
        
        // Update/Create the assets subcollection for client
        await this.setAssets(client); 

        // Update/Create a activity subcollection for client
        const activityCollectionRef = collection(clientRef, config.ACTIVITIES_SUBCOLLECTION)

        const graphCollectionRef = collection(clientRef, config.ASSETS_SUBCOLLECTION, config.ASSETS_GENERAL_DOC_ID, config.GRAPHPOINTS_SUBCOLLECTION)

        // If no activities exist, we leave the collection undefined
        if (client.activities !== undefined) {
            
            // Add all the activities to the subcollection
            const promise = client.activities.map((activity) => {
                const activityWithParentId = {
                    ...activity,
                    parentCollection: config.FIRESTORE_ACTIVE_USERS_COLLECTION
                };
          
                // Filter out undefined properties
                const filteredActivity = Object.fromEntries(
                    Object.entries(activityWithParentId).filter(([_, v]) => v !== undefined)
                );
  
                addDoc(activityCollectionRef, filteredActivity);
            });
            // Use Promise.all to add all activities concurrently
            await Promise.all(promise);
        }
            
        if (client.graphPoints !== undefined) {
            // Add all the graph points to the subcollection
            const promise = client.graphPoints.map((graphPoint) => addDoc(graphCollectionRef, graphPoint));
            // Use Promise.all to add all graph points concurrently
            await Promise.all(promise);
        }
    }

    // // Filters out 0 values from a given fund
    // filterAssets = (assets: { [assetType: string ]: AssetDetails }) => {
    //     return Object.fromEntries(
    //         Object.entries(assets).filter(([key, value]) => value.amount !== 0)
    //     );
    // }


    async setAssets(client: Client) {
        const clientRef = doc(this.db, config.FIRESTORE_ACTIVE_USERS_COLLECTION, client.cid);
        const assetCollectionRef = collection(clientRef, config.ASSETS_SUBCOLLECTION);

        // // Filter out assets with amount 0
        // const agqAssets = this.filterAssets(client.assets.agq);
        // const ak1Assets = this.filterAssets(client.assets.ak1);

        const agqAssets = client.assets.agq;
        const ak1Assets = client.assets.ak1;

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
            ytd: client.ytd ?? 0,
            totalYTD: client.totalYTD ?? 0,
            total: agqDoc.total + ak1Doc.total,
        };

        const agqRef = doc(assetCollectionRef, config.ASSETS_AGQ_DOC_ID);
        const ak1Ref = doc(assetCollectionRef, config.ASSETS_AK1_DOC_ID);
        const genRef = doc(assetCollectionRef, config.ASSETS_GENERAL_DOC_ID);

        await setDoc(agqRef, agqDoc);
        await setDoc(ak1Ref, ak1Doc);
        await setDoc(genRef, general);
    }

    /**
     * Asynchronously deletes a client from the Firestore database.
     *
     * @param cid - The Client ID of the client to be deleted.
     *
     * @returns {Promise<void>} Returns a Promise that resolves when the client has been deleted from the Firestore database.
     */
    deleteClient = async (cid: string | undefined) => {
        if (cid === undefined || cid === null ||cid === '' ) { console.log('no value'); return }
        const clientRef = doc(this.db, config.FIRESTORE_ACTIVE_USERS_COLLECTION, cid);
        await deleteDoc(clientRef);
    }

    async unlinkClient(client: Client): Promise<void> {
        const unlinkUser = httpsCallable<{ cid: string, uid: string, usersCollectionID: string}, { success: boolean }>(functions, 'unlinkUser');
        try {
            const result = await unlinkUser({ cid: client.cid, uid: client.uid, usersCollectionID: config.FIRESTORE_ACTIVE_USERS_COLLECTION });
            console.log('Unlink user success:', result.data.success);
            if (!result.data.success) {
                throw new Error('Failed to unlink user.');
            }
        } catch (error) {
            console.error('Error unlinking user:', error);
            throw new Error('Failed to unlink user.');
        }
    }

    /**
     * Updates the given client in the Firestore database.
     * 
     * @param updatedClient 
     *
     */
    updateClient = async (updatedClient: Client) => {
        await this.setClient(updatedClient);
    }

    getActivities = async () => {
        // Fetch all activities from all clients' 'activities' subcollections using collectionGroup
        const activitiesCollectionGroup = collectionGroup(this.db, config.ACTIVITIES_SUBCOLLECTION);
        const q = query(activitiesCollectionGroup, where('parentCollection', '==', config.FIRESTORE_ACTIVE_USERS_COLLECTION));
        const querySnapshot = await getDocs(q);

        // Map the query snapshot to an array of Activity with formatted time
        const activities: Activity[] = querySnapshot.docs.map((doc) => {
            const data = doc.data() as Activity;
            const parentPath = doc.ref.parent.path.split('/');
            const parentDocId = parentPath[parentPath.length - 2];

            // Format the time field
            let formattedTime = '';
            const time = data.time instanceof Timestamp ? data.time.toDate() : data.time;
            if (time instanceof Date) {
                formattedTime = formatDate(time);
            }

            return {
                ...data,
                id: doc.id,
                parentDocId,
                formattedTime,
            };
        });

        return activities;
    }

    getScheduledActivities = async () => {
        const scheduledActivitiesCollection = collection(this.db, config.SCHEDULED_ACTIVITIES_COLLECTION);
        // const querySnapshot = await getDocs(scheduledActivitiesCollection);
        const q = query(scheduledActivitiesCollection, where('usersCollectionID', '==', config.FIRESTORE_ACTIVE_USERS_COLLECTION));
        const querySnapshot = await getDocs(q)

        const scheduledActivities: ScheduledActivity[] = querySnapshot.docs.map((doc) => {
            const data = doc.data() as ScheduledActivity;

            // Format the time field
            let formattedTime = '';
            const time = data.activity.time instanceof Timestamp ? data.activity.time.toDate() : data.activity.time;
            if (time instanceof Date) {
                formattedTime = formatDate(time);
            }

            return {
                ...data,
                id: doc.id,
                activity: {
                    ...data.activity,
                    formattedTime,
                    parentDocId: data.cid,
                },
            };
        });

        return scheduledActivities;
    }

    createActivity = async (activity: Activity, cid: string) => {
        // Create a reference to the client document
        const clientRef = doc(this.db, config.FIRESTORE_ACTIVE_USERS_COLLECTION, cid);
        // Create a reference to the activities subcollection for the client
        const activityCollectionRef = collection(clientRef, config.ACTIVITIES_SUBCOLLECTION);
        
        // Add the parentCollectionId field to the activity
        const activityWithParentId = {
          ...activity,
          parentCollection: config.FIRESTORE_ACTIVE_USERS_COLLECTION,
        };
        
        // Filter out undefined properties
        const filteredActivity = Object.fromEntries(
          Object.entries(activityWithParentId).filter(([_, v]) => v !== undefined)
        );

        console.log('Filtered Activity:', filteredActivity);
        
        // Add the activity to the subcollection
        await addDoc(activityCollectionRef, filteredActivity);
    }

    setActivity = async (activity: Activity, {activityDocId}: {activityDocId?: string}, cid: string) => {
        // Create a reference to the client document
        const clientRef = doc(this.db, config.FIRESTORE_ACTIVE_USERS_COLLECTION, cid);
        // Create a reference to the activities subcollection for the client
        const activityCollectionRef = collection(clientRef, config.ACTIVITIES_SUBCOLLECTION);
        // Create a reference to the activity document
        const activityRef = doc(activityCollectionRef, activityDocId);
        // Set the activity document with new data
        await setDoc(activityRef, activity);
    }

    deleteActivity = async (activity: Activity) => {
        const cid = activity.parentDocId!;
        const activityDocID = activity.id!;
        // Create a reference to the client document
        try {
            const clientRef = doc(this.db, config.FIRESTORE_ACTIVE_USERS_COLLECTION, cid);
            const activityCollectionRef = collection(clientRef, config.ACTIVITIES_SUBCOLLECTION);
            const activityRef = doc(activityCollectionRef, activityDocID);
            await deleteDoc(activityRef);
        } catch (error) {
            console.error('Failed to delete activity, CID or activityDocID does not exist for the activity:', error);
            console.error('Activity:', activity);
        }
    }

    async deleteNotification(activity: Activity,) {
        const cid = activity.parentDocId!;
        const clientRef = doc(this.db, config.FIRESTORE_ACTIVE_USERS_COLLECTION, cid);
        const notificationsCollectionRef = collection(clientRef, config.NOTIFICATIONS_SUBCOLLECTION);
        const querySnapshot = await getDocs(query(notificationsCollectionRef, where('activityId', '==', activity.id)));
        
        if (!querySnapshot.empty) {
            const batch = writeBatch(this.db);
            querySnapshot.forEach((doc) => {
                batch.delete(doc.ref);
            });
            await batch.commit();
        } else {
            return;
        }
    }

    async getYTD(cid: string): Promise<number> {
        const calculateYTD = httpsCallable<{cid: string, usersCollectionID: string}, {ytd: number}>(functions, 'calculateYTD');
        try {
            const result = await calculateYTD({ cid: cid, usersCollectionID: config.FIRESTORE_ACTIVE_USERS_COLLECTION });
            console.log('YTD Total:', result.data.ytd);
            return result.data.ytd;
        } catch (error) {
            console.error('Error updating YTD:', error);
            throw new Error('Failed to update YTD.');
        }
    }

    async getTotalYTD(cid: string): Promise<number> {
        const calculateYTD = httpsCallable<{cid: string, usersCollectionID: string}, {ytdTotal: number}>(functions, 'calculateTotalYTD');
        try {
            const result = await calculateYTD({ cid: cid, usersCollectionID: config.FIRESTORE_ACTIVE_USERS_COLLECTION });
            console.log('YTD Total:', result.data.ytdTotal);
            return result.data.ytdTotal;
        } catch (error) {
            console.error('Error updating YTD:', error);
            throw new Error('Failed to update YTD.');
        }
    }

    async addStatement(statement: StatementData): Promise<void> {
    try {
        // Example using Firestore
        const db = getFirestore(); // Import and initialize Firestore as needed
        const statementsCollection = collection(db, 'statements');
        await addDoc(statementsCollection, statement);
    } catch (error) {
        console.error('Error adding statement:', error);
        throw error;
    }
    }

    /**
     * Schedules an activity by adding it to the 'scheduledActivities' collection.
     *
     * @param scheduledActivity - The activity data along with scheduling details.
     * @returns A promise that resolves when the scheduled activity is added.
     */
    async scheduleActivity(activity: Activity, clientState: Client): Promise<void> {
        delete activity.id;
        // Add the parentCollectionId field to the activity
        const activityWithParentId = {
            ...activity,
            parentCollection: config.FIRESTORE_ACTIVE_USERS_COLLECTION,
        };
        
        // Filter out undefined properties
        const filteredActivity = Object.fromEntries(
            Object.entries(activityWithParentId).filter(([_, v]) => v !== undefined)
        );

        const scheduledActivity = {
            cid: clientState.cid,
            scheduledTime: filteredActivity.time,
            activity: { ...filteredActivity, parentName: clientState.firstName + ' ' + clientState.lastName },
            clientState,
            usersCollectionID: config.FIRESTORE_ACTIVE_USERS_COLLECTION,
            status: 'pending',
        };

        console.log('filteredActivity', filteredActivity);
        // Add the scheduled activity to the 'scheduledActivities' collection
        await addDoc(collection(this.db, 'scheduledActivities'),scheduledActivity);
    }

    async updateScheduledActivity(updatedActivity: Activity, clientState: Client) {
        const docRef = doc(this.db, 'scheduledActivities', updatedActivity.id ?? '');
        delete updatedActivity.id;
        const activityWithParentId = { 
            ...updatedActivity,
            parentCollection: config.FIRESTORE_ACTIVE_USERS_COLLECTION,
        }
        const filteredActivity = Object.fromEntries(
            Object.entries(activityWithParentId).filter(([_, v]) => v !== undefined)
        );
        const updatedScheduledActivity = {
            cid: clientState.cid,
            scheduledTime: filteredActivity.time,
            activity: { ...filteredActivity, parentName: clientState.firstName + ' ' + clientState.lastName },
            clientState,
            usersCollectionID: config.FIRESTORE_ACTIVE_USERS_COLLECTION,
            status: 'pending',
        };
        await setDoc(docRef, updatedScheduledActivity, { merge: true });
    }
    
    async deleteScheduledActivity(id: string) {
        const docRef = doc(this.db, 'scheduledActivities', id);
        await deleteDoc(docRef);
    }
    
}

