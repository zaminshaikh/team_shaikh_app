import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:team_shaikh_app/database/models/activity_model.dart';
import 'package:team_shaikh_app/database/models/graph_point_model.dart';
import 'package:team_shaikh_app/database/models/notification_model.dart';
import 'package:team_shaikh_app/database/models/assets_model.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import '../utilities.dart';
import 'package:rxdart/rxdart.dart';

class NewDB {
  String? cid;
  String? uid;
  static final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection(Config.get('FIRESTORE_ACTIVE_USERS_COLLECTION'));
  CollectionReference? assetsSubCollection;
  CollectionReference? activitiesSubCollection;
  CollectionReference? notificationsSubCollection;
  CollectionReference? graphPointsSubCollection;
  List<dynamic>? connectedUsersCIDs;

  /// A new instance of [NewDB] with the given [cid] and [uid].
  ///
  /// The [cid] (Client ID) is a unique identifier for the user, and the [uid] (User ID) is the unique identifier for the user's auth account.
  /// The instance is used to link a new user to the database, update user information, and retrieve user data from the database.
  ///
  /// `DBNew.linkNewUser(email)` links a new user to the database using the [cid] and updates the [email]
  ///
  /// `DBNew.users` returns a stream of the 'users' collection in the database
  ///
  /// `DBNew.docExists(cid)` returns a [Future] that completes with a boolean value indicating whether a document exists for the given [cid]`
  ///
  /// `DBNew.docLinked(cid)` returns a [Future] that completes with a boolean value indicating whether a user is linked to the database for the given [cid]
  ///
  /// For more information on the methods, see the individual method documentation.
  NewDB(this.uid);
  NewDB.connectedUser(this.cid) {
    setSubCollections(this);
  }
  NewDB.withCID(this.uid, this.cid);

  // Asynchronous factory constructor
  static Future<NewDB?> fetchCID(
      BuildContext context, String uid) async {
    NewDB service = NewDB(uid);

    // Access Firestore and get the document
    QuerySnapshot querySnapshot =
        await usersCollection.where('uid', isEqualTo: uid).get();

    if (querySnapshot.size > 0) {
      log('database.dart: UID $uid found in Firestore.');
      // Document found, access the 'cid' field
      service.cid = querySnapshot.docs.first.id;
      service.connectedUsersCIDs = querySnapshot.docs.first['connectedUsers'];
      setSubCollections(service);

    } else {
      log('database.dart: Document with UID $uid not found in Firestore.');
      return null;
    }

    return service;
  }

  static void setSubCollections(NewDB service) {
    service.assetsSubCollection = usersCollection
      .doc(service.cid)
      .collection(Config.get('ASSETS_SUBCOLLECTION'));
    service.graphPointsSubCollection = service.assetsSubCollection
      ?.doc(Config.get('ASSETS_GENERAL_DOC_ID'))
      .collection(Config.get('GRAPHPOINTS_SUBCOLLECTION'));
    service.activitiesSubCollection = usersCollection
      .doc(service.cid)
      .collection(Config.get('ACTIVITIES_SUBCOLLECTION'));
    service.notificationsSubCollection = usersCollection
      .doc(service.cid)
      .collection(Config.get('NOTIFICATIONS_SUBCOLLECTION'));
  }
  



  // Stream that listens to changes in the user's client data and subcollections
  Stream<Client?> getClientStream({String? cid, bool isConnectedUser = false}) {
    print('CLIENT STREAM CALLED');
    if (this.cid == null && cid == null) {
      throw Exception('CID is not initialized.');
    }
    try {
      
      // Stream for the main client document
      Stream<DocumentSnapshot> clientDocumentStream =
          usersCollection.doc(cid).snapshots();

      Stream<List<Client?>> connectedUsersStream;
      if (!isConnectedUser && connectedUsersCIDs != null && connectedUsersCIDs != []) {
         connectedUsersStream = Rx.combineLatestList(
            connectedUsersCIDs!
                .map((cid) {
                  NewDB db = NewDB.connectedUser(cid);
                  return db.getClientStream(cid: db.cid, isConnectedUser: true)
                    .asBroadcastStream();
                })
                .toList()).asBroadcastStream();
      } else {
        connectedUsersStream = const Stream.empty();
      }

      // Stream for the activities subcollection
      Stream<List<Activity>> activitiesStream = activitiesSubCollection!
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Activity.fromMap(doc.data() as Map<String, dynamic>))
              .toList());

      // Stream for the assets subcollection (assuming a single document in assets)
      Stream<Assets> assetsStream = assetsSubCollection!.snapshots().map((snapshot) {

        Map<String, Fund> funds = {};
        Map<String, dynamic> general = {};

        for (var doc in snapshot.docs) {
          if (doc.id == 'general') {
            general = doc.data() as Map<String, dynamic>;
          } else {
            funds[doc.id] = Fund.fromMap(doc.data() as Map<String, dynamic>);
          }
        }

        return Assets.fromMap(funds, general);
      });

      // Stream for the notifications subcollection
      Stream<List<CNotification>> notificationsStream =
          notificationsSubCollection!.snapshots().map((snapshot) => snapshot
              .docs
              .map((doc) =>
                  CNotification.fromMap(doc.data() as Map<String, dynamic>))
              .toList());

      
      // // Stream for the graphPoints subcollection
      Stream<List<GraphPoint>> graphPointsStream = graphPointsSubCollection!
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map(
                  (doc) => GraphPoint.fromMap(doc.data() as Map<String, dynamic>))
              .toList());


        return Rx.combineLatest6(
          clientDocumentStream, 
          activitiesStream, 
          assetsStream, 
          notificationsStream, 
          graphPointsStream,
          connectedUsersStream,
          (DocumentSnapshot clientDoc, 
          List<Activity> activities, 
          Assets assets, 
          List<CNotification> notifications, 
          List<GraphPoint> graphPoints, 
          List<Client?> connectedUsers) => 
            Client.fromMap(
              clientDoc.data() as Map<String, dynamic>, 
              cid: cid, 
              activities: activities, 
              assets: assets, 
              notifications: notifications, 
              graphPoints: graphPoints,
              connectedUsers: connectedUsers.whereType<Client>().toList() // Filter out null values
            )
      );


      // Combine all streams to emit a new Client object whenever any part changes
      // return Rx.combineLatest5(
      //   clientDocumentStream,
      //   activitiesStream,
      //   notificationsStream,
      //   graphPointsStream,
      //   assetsStream,
      //   (DocumentSnapshot clientDoc,
      //       List<Activity> activities,
      //       List<Notification> notifications,
      //       List<GraphPoint> graphPoints,
      //       Assets assets) {
      //     if (clientDoc.exists) {
      //       Map<String, dynamic> clientData =
      //           clientDoc.data() as Map<String, dynamic>;

      //       return Client(
      //         cid: cid ?? clientDoc.id,
      //         uid: clientData['uid'],
      //         firstName: clientData['name']['first'],
      //         lastName: clientData['name']['last'],
      //         companyName: clientData['name']['company'],
      //         address: clientData['address'],
      //         dob: (clientData['dob'] as Timestamp?)?.toDate(),
      //         phoneNumber: clientData['phoneNumber'],
      //         appEmail: clientData['appEmail'] ?? '',
      //         initEmail: clientData['initEmail'] ?? '',
      //         firstDepositDate:
      //             (clientData['firstDepositDate'] as Timestamp?)?.toDate(),
      //         beneficiaries: List<String>.from(clientData['beneficiaries'] ?? ''),
      //         connectedUsers: clientData['connectedUsers'] != null
      //             ? List<Client>.from(
      //                 clientData['connectedUsers'].map((cid) => getClient(cid)))
      //             : null,
      //         totalAssets: 0.0, // TODO: Implement total assets fetch
      //         ytd: 0.0, // TODO: Implement YTD fetch
      //         totalYTD: 0.0, // TODO: Implement YTD fetch
      //         activities: activities,
      //         notifications: notifications,
      //         graphPoints: graphPoints,
      //         assets: assets,
      //       );
      //     } else {
      //       return null;
      //     }
      //   },
      // );
    } catch (e) {
      log('database.dart: Error in getClientStream: $e');
      return Stream.value(null);
    }
  }
}

  // Stream<Client?> getClientStream() {
  //   if (cid == null) {
  //     throw Exception('CID is not initialized.');
  //   }

  //   // Stream for the main client document
  //   Stream<DocumentSnapshot> clientDocumentStream =
  //       usersCollection.doc(cid).snapshots();

  //   // Map the DocumentSnapshot to a Client object
  //   return clientDocumentStream.map((snapshot) {
  //     if (snapshot.exists && snapshot.data() != null) {
  //       return Client.empty();
  //     } else {
  //       return Client.empty();
  //     }
  //   });
  // }

//   Stream<Client?> getFakeClientStream() async* {
//     print('Fake client stream started');

//     // Simulate a delay as if fetching from a database
//     await Future.delayed(Duration(seconds: 5));

//     // Yield a fake Client object
//     yield Client(
//       cid: 'fakeCID',
//       uid: 'fakeUID',
//       firstName: 'John',
//       lastName: 'Doe',
//       companyName: 'Fake Company',
//       address: '123 Fake St.',
//       dob: DateTime(1990, 1, 1),
//       phoneNumber: '123-456-7890',
//       appEmail: 'johndoe@example.com',
//       initEmail: 'john.init@example.com',
//       firstDepositDate: DateTime(2020, 5, 15),
//       beneficiaries: ['Beneficiary 1', 'Beneficiary 2'],
//       connectedUsers: [],
//       totalAssets: 100000.0,
//       ytd: 5000.0,
//       totalYTD: 20000.0,
//       notifications: [],
//       activities: [],
//       graphPoints: [],
//       assets: Assets(
//         agq: AssetDetails(
//           personal: 1000.0,
//           company: 2000.0,
//           trad: 500.0,
//           roth: 300.0,
//           sep: 400.0,
//           nuviewTrad: 0.0,
//           nuviewRoth: 0.0,
//         ),
//         ak1: AssetDetails(
//           personal: 2000.0,
//           company: 3000.0,
//           trad: 700.0,
//           roth: 500.0,
//           sep: 600.0,
//           nuviewTrad: 0.0,
//           nuviewRoth: 0.0,
//         ),
//       ),
//     );

//     // Simulate another update after some time
//     await Future.delayed(Duration(seconds: 5));
//     yield Client(
//       cid: 'fakeCID',
//       uid: 'fakeUID',
//       firstName: 'Jane',
//       lastName: 'Doe',
//       companyName: 'Fake Company 2',
//       address: '456 Fake St.',
//       dob: DateTime(1992, 6, 21),
//       phoneNumber: '321-654-9870',
//       appEmail: 'janedoe@example.com',
//       initEmail: 'jane.init@example.com',
//       firstDepositDate: DateTime(2021, 2, 10),
//       beneficiaries: ['Beneficiary A', 'Beneficiary B'],
//       connectedUsers: [],
//       totalAssets: 150000.0,
//       ytd: 10000.0,
//       totalYTD: 30000.0,
//       notifications: [],
//       activities: [],
//       graphPoints: [],
//       assets: Assets(
//         agq: AssetDetails(
//           personal: 1500.0,
//           company: 2500.0,
//           trad: 800.0,
//           roth: 600.0,
//           sep: 500.0,
//           nuviewTrad: 0.0,
//           nuviewRoth: 0.0,
//         ),
//         ak1: AssetDetails(
//           personal: 3000.0,
//           company: 4000.0,
//           trad: 900.0,
//           roth: 700.0,
//           sep: 800.0,
//           nuviewTrad: 0.0,
//           nuviewRoth: 0.0,
//         ),
//       ),
//     );
//   }
// }