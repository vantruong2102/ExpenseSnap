import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PersonalProfile {
  const PersonalProfile({
    required this.fullName,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.photoUrl,
  });

  final String fullName;
  final String phoneNumber;
  final String? dateOfBirth;
  final String? photoUrl;
}

class PersonalProfileService {
  PersonalProfileService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Bạn cần đăng nhập để sửa hồ sơ.');
    return user;
  }

  DocumentReference<Map<String, dynamic>> _profileDocument(String uid) =>
      _firestore.collection('users').doc(uid);

  Future<PersonalProfile> load() async {
    final user = _requireUser();
    final snapshot = await _profileDocument(user.uid).get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    return PersonalProfile(
      fullName: (data['full_name'] as String?) ?? user.displayName ?? '',
      phoneNumber: (data['phone_number'] as String?) ?? '',
      dateOfBirth: data['date_of_birth'] as String?,
      photoUrl: (data['photo_url'] as String?) ?? user.photoURL,
    );
  }

  Future<String> uploadAvatar(Uint8List bytes, {String? contentType}) async {
    final user = _requireUser();
    final reference = _storage.ref('users/${user.uid}/profile/avatar');
    await reference.putData(
      bytes,
      SettableMetadata(contentType: contentType ?? 'image/jpeg'),
    );
    return reference.getDownloadURL();
  }

  Future<void> save({
    required String fullName,
    required String phoneNumber,
    required String? dateOfBirth,
    required String? photoUrl,
  }) async {
    final user = _requireUser();
    final document = _profileDocument(user.uid);

    if (photoUrl == null) {
      try {
        await _storage.ref('users/${user.uid}/profile/avatar').delete();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') rethrow;
      }
    }

    await document.set(
      {
        'full_name': fullName.trim(),
        'phone_number': phoneNumber.trim(),
        'date_of_birth': dateOfBirth,
        'photo_url': photoUrl,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await user.updateDisplayName(fullName.trim());
    await user.updatePhotoURL(photoUrl);
    await user.reload();
  }
}
