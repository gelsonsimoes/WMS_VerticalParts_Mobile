import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../services/supabase_service.dart';
import '../models/auth_model.dart';

class AuthProvider extends ChangeNotifier {
  OperadorPerfil? _perfil;
  bool _carregando = false;
  String? _erro;
  StreamSubscription<sb.AuthState>? _authSub;

  OperadorPerfil? get perfil     => _perfil;
  bool           get carregando  => _carregando;
  String?        get erro        => _erro;
  bool           get autenticado => SupabaseService.sessaoAtual != null && _perfil != null;
  OperadorPerfil? get user       => _perfil;
  String?        get token       => SupabaseService.sessaoAtual?.accessToken;

  AuthProvider() { _inicializar(); }

  Future<void> _inicializar() async {
    final s = SupabaseService.sessaoAtual;
    if (s != null) await _carregarPerfil(s.user.id);
    
    _authSub = SupabaseService.client.auth.onAuthStateChange.listen((data) async {
      if (data.event == sb.AuthChangeEvent.signedIn && data.session != null) {
        await _carregarPerfil(data.session!.user.id);
      } else if (data.event == sb.AuthChangeEvent.signedOut) {
        _perfil = null; 
        notifyListeners();
      }
    });
  }

  Future<void> _carregarPerfil(String uid) async {
    try {
      final d = await SupabaseService.getPerfil(uid);
      if (d != null) { 
        _perfil = OperadorPerfil.fromJson(d); 
        notifyListeners(); 
      } else {
        // Se logou com sucesso mas o perfil não existe, forçamos logout
        await logout();
      }
    } catch (e) {
      _erro = "Erro ao carregar perfil: $e";
      notifyListeners();
    }
  }

  Future<bool> login(String employeeId, String senha) async {
    _carregando = true; _erro = null; notifyListeners();
    try {
      final r = await SupabaseService.login(employeeId, senha);
      if (r.user != null) {
        await _carregarPerfil(r.user!.id);
        _carregando = false; notifyListeners(); return true;
      }
      _erro = 'ID ou senha incorretos.';
    } on sb.AuthException catch (e) {
      _erro = e.message.contains('Invalid') ? 'ID ou senha incorretos.' : 'Erro de conexao.';
    } catch (_) { _erro = 'Sem conexao com o servidor.'; }
    _carregando = false; notifyListeners(); return false;
  }

  Future<void> logout() async { 
    await SupabaseService.logout(); 
    _perfil = null; 
    notifyListeners(); 
  }

  Future<void> tryAutoLogin() async {
    final s = SupabaseService.sessaoAtual;
    if (s != null && _perfil == null) await _carregarPerfil(s.user.id);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
