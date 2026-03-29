import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String _detectRoleFromEmail(String email) {
    final normalized = email.trim().toLowerCase();

    if (!normalized.endsWith('@munzur.edu.tr')) {
      return 'student';
    }

    final localPart = normalized.split('@').first;

    if (RegExp(r'^\d+$').hasMatch(localPart)) {
      return 'student';
    }

    return 'staff';
  }

  Future<void> register({
    required String fullName,
    required String studentNo,
    required String email,
    required String password,
    required String educationLevel,
    required String academicUnit,
    required String department,
    required String staffType,
    required String administrativeUnit,
    required String academicTitle,
    required String employmentType,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final role = _detectRoleFromEmail(normalizedEmail);

    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Kullanıcı oluşturulamadı.',
      );
    }

    final userData = <String, dynamic>{
      'fullName': fullName.trim(),
      'email': normalizedEmail,
      'role': role,
      'isActive': false,
      'isVerifiedByCode': false,
      'createdAt': FieldValue.serverTimestamp(),
      'studentNo': '',
      'educationLevel': '',
      'academicUnit': '',
      'department': '',
      'staffType': '',
      'administrativeUnit': '',
      'academicTitle': '',
      'employmentType': '',
    };

    if (role == 'student') {
      userData.addAll({
        'studentNo': studentNo.trim(),
        'educationLevel': educationLevel.trim(),
        'academicUnit': academicUnit.trim(),
        'department': department.trim(),
      });
    } else {
      userData.addAll({
        'staffType': staffType.trim(),
        'academicUnit':
        staffType.trim() == 'Akademik' ? academicUnit.trim() : '',
        'department':
        staffType.trim() == 'Akademik' ? department.trim() : '',
        'academicTitle':
        staffType.trim() == 'Akademik' ? academicTitle.trim() : '',
        'administrativeUnit':
        staffType.trim() == 'İdari' ? administrativeUnit.trim() : '',
        'employmentType':
        staffType.trim() == 'İdari' ? employmentType.trim() : '',
      });
    }

    await _firestore.collection('users').doc(user.uid).set(userData);

    await sendVerificationEmail();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim().toLowerCase(),
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Doğrulama e-postası gönderilemedi.',
      );
    }

    await user.sendEmailVerification();
  }

  Future<bool> refreshAndCheckEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();
    final refreshedUser = _auth.currentUser;

    return refreshedUser?.emailVerified ?? false;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getCurrentUserDoc() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Oturum açmış kullanıcı bulunamadı.',
      );
    }

    return _firestore.collection('users').doc(user.uid).get();
  }

  Future<void> activateIfVerified({bool forceVerifiedByCode = false}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await user.reload();
    final refreshedUser = _auth.currentUser;

    final emailVerified = refreshedUser?.emailVerified ?? false;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final data = userDoc.data() ?? {};

    final isVerifiedByCode =
        forceVerifiedByCode || (data['isVerifiedByCode'] == true);

    if (emailVerified || isVerifiedByCode) {
      await _firestore.collection('users').doc(user.uid).set({
        'isActive': true,
        'isVerifiedByCode': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<bool> isUserActive(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return false;
    return doc.data()?['isActive'] == true;
  }
}