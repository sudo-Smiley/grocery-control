import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grocery_control/models/grocery_item.dart';
import 'package:grocery_control/models/group.dart';
import 'package:grocery_control/utils/constants.dart';

class Database {
  final FirebaseFirestore firestore;

  Database({this.firestore});

  Stream<List<GroupModel>> streamGroups({String uid}) {
    try {
      return firestore
          .collection("users")
          .doc(uid)
          .collection("groups")
          .snapshots()
          .map((query) {
        final List<GroupModel> retVal = <GroupModel>[];
        for (final DocumentSnapshot doc in query.docs) {
          retVal.add(GroupModel.fromDocumentSnapshot(documentSnapshot: doc));
        }
        return retVal;
      });
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<GroupModel>> streamGroupsRefs({String uid}) {
    try {
      var futures = firestore.collection("users").doc(uid).get().then((doc) {
        final List<Future<GroupModel>> retVal = <Future<GroupModel>>[];
        final List<DocumentReference> groupRefs = doc.data()["group_ref_array"];
        for (DocumentReference documentRef in groupRefs) {
          retVal.add(documentRef.get().then((value) {
            return GroupModel.fromDocumentSnapshot(documentSnapshot: value);
          }));
        }
        return Future.wait(retVal);
      });
      return Stream.fromFuture(futures);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<GroupModel>> streamGroupsRefs2({String uid}) async {
    try {
      DocumentSnapshot userDoc =
          await firestore.collection("users").doc(uid).get();

      final List<GroupModel> retVal = <GroupModel>[];
      final List<DocumentReference> groupRefs =
          userDoc["group_ref_array"].cast<DocumentReference>();
      for (DocumentReference documentRef in groupRefs) {
        retVal.add(GroupModel.fromDocumentSnapshot(
            documentSnapshot: await documentRef.get()));
      }
      return retVal;
    } catch (e) {
      rethrow;
    }
  }

  Future<GroupModel> getLastGroup({String uid}) async {
    try {
      var doc = await firestore.collection("users").doc(uid).get();
      DocumentReference groupRef = doc["last_group"] as DocumentReference;
      return GroupModel.fromDocumentSnapshot(
          documentSnapshot: await groupRef.get());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setLastGroup({String uid, GroupModel group}) async {
    try {
      firestore.collection("users").doc(uid).update({
        "last_group": firestore.collection("groups").doc(group.groupId)
      });
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<GroceryItemModel>> streamItems(
      {String group, SortDirection sortDirection, bool filterChecked}) {
    try {
      var itemsCollection = firestore
          .collection("items")
          .doc(group)
          .collection("items")
          .where("Name", isNotEqualTo: null);
      if (sortDirection == null) {
        itemsCollection = itemsCollection.orderBy("Name",
            descending: sortDirection == SortDirection.Decsending);
      }
      if (filterChecked) {
        itemsCollection = itemsCollection.where("Checked", isNotEqualTo: true);
      }
      return itemsCollection.snapshots().map((query) {
        final List<GroceryItemModel> retVal = <GroceryItemModel>[];
        for (final DocumentSnapshot doc in query.docs) {
          retVal.add(GroceryItemModel.fromDocumentSnapshot(
              documentSnapshot: doc, group: group));
        }
        return retVal;
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateGroupName(
      {GroupModel group, String newName, String uid}) async {
    try {
      if (group.owner != uid) {
        return Future.value();
      }
      if (group.name == newName) {
        return Future.value();
      }

      DocumentReference groupDoc =
          firestore.collection("groups").doc(group.groupId);
      groupDoc.update({
        "name": newName,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addItem({String group, String name}) async {
    try {
      firestore.collection("items").doc(group).collection("items").add({
        "Name": name,
        "Checked": false,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateItem(
      {String group, String itemId, String name, bool checked}) async {
    try {
      firestore
          .collection("items")
          .doc(group)
          .collection("items")
          .doc(itemId)
          .update({
        "Checked": checked,
        "Name": name,
      });
    } catch (e) {
      rethrow;
    }
  }
}
