// lib/model/GoogleAuthResult.dart
//
// Backend GoogleAuthResponse ka Flutter side representation.
// status == LOGIN_SUCCESS -> user already existing tha, seedha login ho gaya.
// status == SIGNUP_REQUIRED -> naya Google user hai, account type + category
// poochni hai (GoogleCompleteRegistrationScreen pe le jao).

import '../../model/UserModel.dart';

enum GoogleAuthStatus { loginSuccess, signupRequired }

class GoogleAuthResult {
  final GoogleAuthStatus status;

  // status == loginSuccess ho to ye set hoga
  final UserModel? user;

  // status == signupRequired ho to ye set honge
  final String? signupToken;
  final String? email;
  final String? name;

  GoogleAuthResult.loginSuccess(this.user)
      : status = GoogleAuthStatus.loginSuccess,
        signupToken = null,
        email = null,
        name = null;

  GoogleAuthResult.signupRequired({
    required this.signupToken,
    required this.email,
    required this.name,
  })  : status = GoogleAuthStatus.signupRequired,
        user = null;
}
