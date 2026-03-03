import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_model.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Future<void> login(AuthResponse response) async {
    _user = response.usuario;
    _token = response.token;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    await prefs.setString('user_data', json.encode(_user!.toJson()));

    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');

    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('auth_token')) return;

    _token = prefs.getString('auth_token');
    final userData = prefs.getString('user_data');
    if (userData != null) {
      _user = User.fromJson(json.decode(userData));
    }
    
    notifyListeners();
  }
}
