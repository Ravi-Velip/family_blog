import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'common.dart';

class FamilyManagement {

  createNewFamily(String familyName) async {
    try {
      SharedPreferences _prefs = await SharedPreferences.getInstance();
      String _userId = _prefs.get('userId');

      // Checking if family already exists
      QuerySnapshot _family = await Firestore.instance.collection('families')
          .where('familyName', isEqualTo: familyName).where('memberIds', arrayContains: _userId).getDocuments();
      if(_family.documents.length > 0){
        return Common().getFinalResult(false, 'Family already exists.');
      }

      // Adding new family to 'families' collection
      return await Firestore.instance.collection('/families').add({
        'familyName': familyName,
        'numberOfPosts': 0,
        'memberIds': [_userId],
        'createdOn': Timestamp.now(),
        'owner': _userId,
      }).then((value) async {

        // Adding user to 'members' sub-collection
        CollectionReference _memCollectionRef = Firestore.instance.collection('families')
            .document(value.documentID).collection('members');
        await _memCollectionRef.add({
          'userId': _userId,
          'name': _prefs.get('name'),
          'role': 'Owner',
          'avatar': _prefs.get('avatar'),
        });
        return Common().getFinalResult(true, 'Created a new family - $familyName');
      });
    }
    catch (e) {
      return Common().getFinalResult(false, e.toString());
    }
  }

  addNewMemberToFamily(String emailId, String familyId, String familyName, String role) async {
    try {
      var _userDocument = await Firestore.instance.collection('users').where('emailId', isEqualTo: emailId).getDocuments();
      if (_userDocument.documents.length == 0) throw 'User not found';
      String _userId = _userDocument.documents[0].documentID;
      DocumentReference _familyDocumentRef = Firestore.instance.collection('families').document(familyId);
      DocumentReference _memberDocumentRef = Firestore.instance.collection('families').document(familyId).collection('members').document();

      return await Firestore.instance.runTransaction((transaction) async {
        DocumentSnapshot _familyDocSnapshot = await transaction.get(_familyDocumentRef);
        DocumentSnapshot _memberDocSnapshot = await transaction.get(_memberDocumentRef);
        List _memberIds = List.from(_familyDocSnapshot.data['memberIds']);
        _memberIds.add(_userId);

        await transaction.update(_familyDocSnapshot.reference, <String, dynamic>{
          'memberIds': _memberIds,
        });

        await transaction.set(_memberDocSnapshot.reference, <String, dynamic>{
          'userId': _userId,
          'name': _userDocument.documents[0].data['name'],
          'role': role,
          'avatar': _userDocument.documents[0].data['avatar'],
        });
      }).then((value) async {
        return await Common().getFinalResult(true, 'Successfully added $emailId to family.');
      });
    } catch (e) {
      print(e);
      return await Common().getFinalResult(false, e.toString());
    }
  }

  updateMemberRoles(String familyId, String memberId) async {
    try{
      DocumentReference _memberDocumentRef = Firestore.instance.collection('families').document(familyId)
          .collection('members').document(memberId);
      return Firestore.instance.runTransaction((transaction) async {
        DocumentSnapshot _membersDocSnapshot = await transaction.get(_memberDocumentRef);
        await transaction.update(_membersDocSnapshot.reference, <String, dynamic>{
          'role': _membersDocSnapshot.data['role'] == 'Member' ? 'Admin' : 'Member',
        });
      }).then((value) async {
        return await Common().getFinalResult(true, 'Member role has been changed.');
      });
    } catch(e){
      return await Common().getFinalResult(false, e.toString());
    }
  }

  removeMemberFromFamily(String familyId, String memberId, String name, String userId) async {
    try{
      DocumentReference _familyDocumentRef = Firestore.instance.collection('families').document(familyId);

      return await Firestore.instance.runTransaction((transaction) async {
        DocumentSnapshot _familyDocSnapshot = await transaction.get(_familyDocumentRef);
        List _memberIds = List.from(_familyDocSnapshot.data['memberIds']);
        _memberIds.remove(userId);

        await transaction.update(_familyDocSnapshot.reference, <String, dynamic>{
          'memberIds': _memberIds,
        });
      }).then((value) async {
        return await Firestore.instance.collection('families')
            .document(familyId).collection('members').document(memberId).delete().then((value) async {
          return await Common().getFinalResult(true, '$name has been removed from the family.');
        });
      });
    }catch(e) {
      return await Common().getFinalResult(false, e.toString());
    }
  }

  deleteFamily(String familyId, String familyName) async {
    try{
      DocumentReference _familyDocumentRef = Firestore.instance.collection('families').document(familyId);
      QuerySnapshot _memberSnapShot = await Firestore.instance.collection('families').document(familyId).collection('members').getDocuments();

      return await _familyDocumentRef.delete().then((value) async {
        _memberSnapShot.documents.forEach((doc) async {
          await doc.reference.delete();
        });
        return await Common().getFinalResult(true, '$familyName has been deleted successfully.');
      });
    } catch(e) {
      return await Common().getFinalResult(false, e.toString());
    }
  }

}
