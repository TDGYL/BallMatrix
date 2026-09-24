import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:captcha_plugin_flutter/captcha_plugin_flutter.dart';
import '../bm_base_page.dart';
import '../common/bm_webview_page.dart';
import '../../theme/bm_colors.dart';
import '../../network/bm_network_manager.dart';
import '../../utils/bm_auth_manager.dart';
import '../../models/bm_user_model.dart';

/// BMLoginPage - login/registerpage
/// feature: email → peopleverify → sendsendcaptcha → Enter verification code+agreement → login
/// differentiated design (compare hanklive purple background):
/// 1. dark green BallMatrix theme (pitch900 / pitch850 / bright) - purplesystemdifferentiation
/// 2. backgroundchangeitems + footballcourtcenter circlebackground（notyescolordirectionchange）
/// 3. left sidebright green 3px vertical items → bright greenleft side differentiation
/// 4. buttonmakeuse Capsule pill 50px height（and topicList post buttonone of style）
/// API reuse hanklive samepath:
/// POST /api/livespeed/auth/send-verify (channel="email")
/// POST /api/livespeed/auth/login
/// GET /api/livespeed/member
/// architecture: one class per file, extends BMBasePage
class BMLoginPage extends BMBasePage {
 const BMLoginPage({super.key});

 @override
 State<BMLoginPage> createState() => _BMLoginPageState();
}

class _BMLoginPageState extends BMBasePageState<BMLoginPage> {
 /// emailinputcontroller (TextEditingController type)
 final TextEditingController _emailCtrl = TextEditingController();

 /// captchainputcontroller (TextEditingController type)
 final TextEditingController _codeCtrl = TextEditingController();

 /// whetheralreadyagreement (bool type, false=not yet, notallowlogin)
 bool _isAgree = false;

 /// whethercenterlogin (bool type, duplicate)
 bool _isLoading = false;

 /// whethercentersendsendcaptcha (bool type, duplicatetap)
 bool _isSending = false;

 /// countwhensecondcount (int type, 0=countwhenendcanheavysend)
 int _countdown = 0;

 /// countwhentimer (Timer? type, pagedisposewhen cancel)
 Timer? _countdownTimer;

 /// SDK 8s timeoutfallbacktimer (Timer? type, nativeSDKnot yetplacegoodnonecallbackcard)
 Timer? _captchaTimer;

 /// SDK whetheralreadycallbacksuccess/failure (bool type, duplicatesend _sendVerifyCode)
 bool _captchaDone = false;

 /// captcha SDK instance (CaptchaPluginFlutter type)
 final CaptchaPluginFlutter _captcha = CaptchaPluginFlutter();

 /// captcha businessId / captchaId (String type, user of fixedvalue)
 static const String _captchaVerifyCode = '69d5b2ee3fec46658e01c0b45fc381af';

 /// emailformatvalidatecenterthen (bool Function(String) type)
 static bool _isEmail(String s) =>
 RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(s);

 @override
 void dispose() {
 _emailCtrl.dispose();
 _codeCtrl.dispose();
 _countdownTimer?.cancel();
 _captchaTimer?.cancel();
 _captcha.destroyCaptcha();
 super.dispose();
 }

 /// tap「Get code」: emailvalidate → immediatelybuttonloading → SDKpeopleverify → onSuccesscallbacktrueactualvalidate → passtrueactualvalidatetoPOST /api/livespeed/auth/send-verify
 /// keyconstraint: ⭐️ onlyhas _captcha.showCaptcha of onSuccess callbackreturnstrueactual validate will send-verify API;
 /// timeout/onError/SDKexception/userhomeclosedialog 4 kindfallbackscenario**notsendtrueactualsendsend**, onlytoastuser(trueactualSMSsendsendtimes)
 void _handleGetCode() {
 if (_countdown > 0 || _isSending) return;
 final email = _emailCtrl.text.trim();
 if (!_isEmail(email)) {
 _snack('inputvalid of email');
 return;
 }

 // ⭐️ callSDKfirstimmediatelyenterloading，buttonimmediatelychangeformconvert，usernotwillgetcard
 setState(() => _isSending = true);
 _captchaDone = false;
 _captchaTimer?.cancel();

 // card：6s timeout(todialogfootenoughdisplaytime) → notsendtrueactualcaptcha，onlytoastuserretry
 _captchaTimer = Timer(const Duration(seconds: 6), () {
 if (_captchaDone || !mounted) return;
 _captchaDone = true;
 debugPrint('🛡️ BMLogin captcha TIMEOUT 6s -> NO REAL SEND');
      _snack('peopleverifyloadingtimeout, checknetworklaterretry');
 if (mounted) setState(() => _isSending = false);
 });

 // peopleverify SDK
 try {
 _captcha.init({
 'captcha_id': _captchaVerifyCode,
        'use_default_fallback': true,
        'failed_max_retry_count': 2,
        'timeout': 10000,
        'is_touch_outside_disappear': false,
        'is_close_button_bottom': true,
      });
      _captcha.showCaptcha(
        onLoaded: () {
          debugPrint('🛡️ BMLogin captcha loaded');
        },
        onSuccess: (dynamic data) async {
          if (_captchaDone) return;
          _captchaTimer?.cancel();
          _captchaDone = true;
          debugPrint('🛡️ BMLogin captcha success: $data');
 // ✅ uniquetrueactualsendsendpath：from captcha_plugin_flutter callback of Map takeoutput validate string
 final validate = (data is Map && data['validate'] is String)
              ? data['validate'] as String
              : '';
          if (validate.isEmpty) {
            _snack('peopleverifyfailure, please retry');
 if (mounted) setState(() => _isSending = false);
 return;
 }
 // willtrueactual validate passto /api/livespeed/auth/send-verify APIsendEmail Verification Code
 await _sendVerifyCode(validate);
 },
 onError: (dynamic data) {
 if (_captchaDone) return;
 _captchaTimer?.cancel();
 _captchaDone = true;
 debugPrint('🛡️ BMLogin captcha error: $data');
 // ❌ notsendtrueactualcaptcha
 _snack('peopleverifyfailure, please retry');
          if (mounted) setState(() => _isSending = false);
        },
        onClose: (dynamic data) {
          debugPrint('🛡️ BMLogin captcha close: $data');
 _captchaTimer?.cancel();
 // userhomeclosedialogandnosuccessbranch → restorebuttoncanpoint(notsendtrueactualcaptcha)
 if (!_captchaDone && mounted) {
 setState(() => _isSending = false);
 }
 },
);
 } catch (e) {
 // SDK exception (filenot yetregister/Dnot yetform) → notsendtrueactualcaptcha, onlytoast
 if (_captchaDone) return;
 _captchaTimer?.cancel();
 _captchaDone = true;
 debugPrint('🛡️ BMLogin captcha EXCEPTION: $e');
      _snack('peopleverify SDK exception, please retry');
 if (mounted) setState(() => _isSending = false);
 }
 }

 /// requestsendsendfilecaptchaAPI (and hanklive 1:1 same URL/argument, channel=email)
 /// ⭐️ [validate] - **mustyes captcha_plugin_flutter of onSuccess callbackreturns of trueactual validate**
 /// API: POST /api/livespeed/auth/send-verify
 /// body: {validate, account, channel:'email', scene:'sms-login'}
 /// successlaterlaunch 60s countwhen
 Future<void> _sendVerifyCode(String validate) async {
 setState(() => _isSending = true);
 try {
 final response = await BMNetworkManager().postRequest(
 '/api/livespeed/auth/send-verify',
        data: {
          'validate': validate,
          'account': _emailCtrl.text.trim(),
          'channel': 'email',
          'scene': 'sms-login',
        },
      );
      if (response.isSuccess) {
        _snack(response.message ?? 'captchaalreadysendsend, receiveemail');
        _startCountdown();
      } else {
        _snack(response.message ?? 'captchasendsendfailure, please retry');
      }
    } catch (e) {
      _snack('networkerror, please retry');
 } finally {
 if (mounted) setState(() => _isSending = false);
 }
 }

 /// launch 60s countwhen
 void _startCountdown() {
 setState(() => _countdown = 60);
 _countdownTimer?.cancel();
 _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
 if (!mounted) {
 t.cancel();
 return;
 }
 setState(() {
 if (_countdown > 0) {
 _countdown--;
 } else {
 t.cancel();
 }
 });
 });
 }

 /// tap「login/register」: validate → loginAPI → saveTokentoSharedPreferences + inject request header → /memberuser → saveUserInfo → Navigator.pop(true) notificationouterpartrefresh
 /// API 1: POST /api/livespeed/auth/login {channel:'email', account, code} → refresh_token
 /// API 2: GET /api/livespeed/member → use token takeuserinfo
 /// persist 1: BMAuthManager.saveToken → memory + SharedPreferences + BMNetworkManager setAuthToken requestheader
 /// persist 2: BMAuthManager.saveUserInfo → memory + SharedPreferences JSON
 /// notificationouterpart: Navigator.pop(true) returns true, outerpartcan then((v)=>v==true?refreshuserheader:null)
 Future<void> _handleLogin() async {
 final email = _emailCtrl.text.trim();
 if (!_isEmail(email)) {
 _snack('inputvalid of email');
      return;
    }
    if (_codeCtrl.text.trim().isEmpty) {
      _snack('Enter verification code');
      return;
    }
    if (!_isAgree) {
      _snack('Please check and agree to the User Agreement & Privacy Policy first');
 return;
 }
 setState(() => _isLoading = true);
 try {
 // Step 1: loginAPIget token (and hanklive 1:1)
 final loginResponse = await BMNetworkManager().postRequest(
 '/api/livespeed/auth/login',
        data: {
          'channel': 'email',
          'account': email,
          'code': _codeCtrl.text.trim(),
        },
      );
      if (!loginResponse.isSuccess || loginResponse.data == null) {
        if (mounted) _snack(loginResponse.message ?? 'Login failed');
        return;
      }
      final dynamic data = loginResponse.data;
      final refreshToken = (data is Map && data['refresh_token'] is String)
          ? data['refresh_token'] as String
          : null;
      if (refreshToken == null || refreshToken.isEmpty) {
        if (mounted) _snack('Login failed: Token invalid');
 return;
 }

 // Step 2: save token to SharedPreferences + inject request header
 await BMAuthManager().saveToken(refreshToken);

 // Step 3: usenew token userinfo (and hanklive 1:1 GET /api/livespeed/member)
 final userResponse = await BMNetworkManager().getRequest('/api/livespeed/member');
      if (!userResponse.isSuccess || userResponse.data == null) {
        if (mounted) _snack(userResponse.message ?? 'Failed to get user info');
        return;
      }
      final dynamic userRaw = userResponse.data;
      if (userRaw is! Map<String, dynamic>) {
        if (mounted) _snack('User info parse error');
 return;
 }

 // Step 4: saveuserinfoto SharedPreferences
 final user = BMUserModel.fromJson(userRaw);
 await BMAuthManager().saveUserInfo(user);

 // Step 5: loginsuccess SnackBar + pop returns true notificationouterpartrefresh
 if (!mounted) return;
 _snack('loginsuccess, back ${user.nickname ?? 'ball'} 👋');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _snack('Login failed, please retry');
 } finally {
 if (mounted) setState(() => _isLoading = false);
 }
 }

 /// SnackBar unified toast
 void _snack(String msg) {
 if (!mounted) return;
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Text(
 msg,
 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
),
 backgroundColor: BMColors.pitch850,
 behavior: SnackBarBehavior.floating,
 duration: const Duration(seconds: 2),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
),
);
 }

 // ================================================================
 // UI BUILD
 // ================================================================
 @override
 Widget buildBody(BuildContext context) {
 return GestureDetector(
 onTap: () => FocusScope.of(context).unfocus(),
 child: Scaffold(
 backgroundColor: BMColors.pitch900,
 body: Stack(
 children: [
 // background: footballcourtcenter circleitems + correctcornerdark green (and hanklive directionchangedifferentiation)
 Positioned.fill(
 child: DecoratedBox(
 decoration: BoxDecoration(
 gradient: LinearGradient(
 begin: Alignment.topCenter,
 end: Alignment.bottomCenter,
 colors: [
 const Color(0xFF0B2A22),
 BMColors.pitch900,
 const Color(0xFF0A2019),
 ],
),
),
 child: CustomPaint(painter: _BMFieldBgPainter()),
),
),
 SafeArea(
 child: Padding(
 padding: const EdgeInsets.symmetric(horizontal: 22),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 const SizedBox(height: 8),
 _buildTopBar(),
 const SizedBox(height: 24),
 _buildTitleSection(),
 const SizedBox(height: 28),
 _buildEmailField(),
 const SizedBox(height: 14),
 _buildCodeField(),
 const SizedBox(height: 16),
 _buildAgreement(),
 const SizedBox(height: 24),
 _buildLoginButton(),
 const Spacer(),
 _buildFooter(),
 const SizedBox(height: 20),
 ],
),
),
),
 ],
),
),
);
 }

 Widget _buildTopBar() {
 return Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 GestureDetector(
 onTap: () => Navigator.pop(context),
 child: Container(
 width: 36,
 height: 36,
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(10),
 border: Border.all(
 color: BMColors.pitch700.withValues(alpha: 0.5),
),
),
 child: const Icon(
 Icons.chevron_left,
 color: Colors.white,
 size: 18,
),
),
),
 // brandpill (differentiation: andtopicpagepost buttonsamestyle, bright green 12%fill+stroke)
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
 decoration: BoxDecoration(
 color: BMColors.bright.withValues(alpha: 0.12),
 border: Border.all(
 color: BMColors.bright.withValues(alpha: 0.5),
 width: 1.2,
),
 borderRadius: BorderRadius.circular(20),
),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: const [
 Icon(
 Icons.sports_soccer_outlined,
 size: 11,
 color: BMColors.bright,
),
 SizedBox(width: 4),
 Text(
 'BALLMATRIX',
 style: TextStyle(
 color: BMColors.bright,
 fontSize: 10,
 fontWeight: FontWeight.w900,
 letterSpacing: 1.0,
),
),
 ],
),
),
 ],
);
 }

 Widget _buildTitleSection() {
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 // left side: bright greenpillvertical items (and hanklive 3px vertical itemsdifferentiation)
 Container(
 width: 4,
 height: 26,
 decoration: BoxDecoration(
 color: BMColors.bright,
 borderRadius: BorderRadius.circular(4),
 boxShadow: [
 BoxShadow(
 color: BMColors.bright.withValues(alpha: 0.4),
 blurRadius: 10,
),
 ],
),
),
 const SizedBox(width: 12),
 const Text(
 'Welcome Back',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'emailverifylogin, addinput 60 10k+ fansanalysis',
 style: TextStyle(
 color: BMColors.textSecondary,
 fontSize: 12,
 height: 1.4,
),
),
 ],
);
 }

 /// buildsingleitemsinput fieldcontainer (styleleave, pitch850 + pitch700 stroke)
 Widget _fieldContainer({required Widget child}) {
 return Container(
 height: 50,
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(14),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
),
 child: child,
);
 }

 Widget _buildEmailField() {
 return _fieldContainer(
 child: Row(
 children: [
 const SizedBox(width: 14),
 const Icon(Icons.email_outlined, color: BMColors.bright, size: 16),
 const SizedBox(width: 8),
 Expanded(
 child: TextField(
 controller: _emailCtrl,
 keyboardType: TextInputType.emailAddress,
 autocorrect: false,
 style: const TextStyle(
 color: Colors.white,
 fontSize: 14,
 letterSpacing: 0,
),
 decoration: const InputDecoration(
 border: InputBorder.none,
 isDense: true,
 hintText: 'inputemail',
                hintStyle: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildCodeField() {
    return Row(
      children: [
        Expanded(
          child: _fieldContainer(
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(
                  Icons.shield_outlined,
                  color: BMColors.bright,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 3,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      isDense: true,
                      hintText: 'Email Verification Code',
 hintStyle: TextStyle(
 color: Color(0xFF6B7280),
 fontSize: 13,
 letterSpacing: 0,
),
 contentPadding: EdgeInsets.symmetric(vertical: 10),
),
),
),
 const SizedBox(width: 10),
 ],
),
),
),
 const SizedBox(width: 10),
 // Get codebutton (capsule pill, bright green/depth)
 GestureDetector(
 onTap: (_countdown > 0 || _isSending) ? null: _handleGetCode,
 child: Container(
 height: 50,
 constraints: const BoxConstraints(minWidth: 108),
 padding: const EdgeInsets.symmetric(horizontal: 14),
 alignment: Alignment.center,
 decoration: BoxDecoration(
 color: _countdown > 0 || _isSending
 ? BMColors.pitch800
: BMColors.bright.withValues(alpha: 0.92),
 borderRadius: BorderRadius.circular(25),
 border: Border.all(
 color: _countdown > 0 || _isSending
 ? BMColors.pitch700.withValues(alpha: 0.6)
: BMColors.bright.withValues(alpha: 0.6),
 width: 1.0,
),
),
 child: _isSending
 ? const SizedBox(
 width: 14,
 height: 14,
 child: CircularProgressIndicator(
 color: Colors.white,
 strokeWidth: 2,
),
)
: Text(
 _countdown > 0 ? '${_countdown}s heavysend' : 'Get code',
 style: TextStyle(
 color: _countdown > 0 || _isSending
 ? const Color(0xFF9CA3AF)
: BMColors.pitch950,
 fontSize: 12,
 fontWeight: FontWeight.w800,
),
),
),
),
 ],
);
 }

 /// navigateagreement Web page (andprofileinsettingspageone)
 /// [htmlFileName] - local HTML textfilename (String type, 'user-agreement.html' / 'privacy-agreement.html')
  void _openAgreement(String htmlFileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BMWebViewPage(htmlFileName: htmlFileName),
      ),
    );
  }

  Widget _buildAgreement() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isAgree = !_isAgree),
          child: Container(
            width: 15,
            height: 15,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: _isAgree ? BMColors.bright : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _isAgree ? BMColors.bright : const Color(0xFF6B7280),
                width: 1.2,
              ),
            ),
            child: _isAgree
                ? const Icon(Icons.check, color: BMColors.pitch950, size: 11)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'myalreadyreadandsame ',
              style: TextStyle(
                color: BMColors.textSecondary,
                fontSize: 11,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: '《User Agreement》',
                  style: const TextStyle(
                    color: BMColors.bright,
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _openAgreement('user-agreement.html'),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: '《Privacy Policy》',
                  style: const TextStyle(
                    color: BMColors.bright,
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _openAgreement('privacy-agreement.html'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLogin,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: _isLoading ? BMColors.pitch800 : BMColors.bright,
          border: Border.all(
            color: _isLoading
                ? BMColors.pitch700.withValues(alpha: 0.5)
                : BMColors.bright.withValues(alpha: 0.6),
            width: 1.0,
          ),
          boxShadow: _isLoading
              ? null
              : [
                  BoxShadow(
                    color: BMColors.bright.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                )
              : const Text(
                  'Login now',
                  style: TextStyle(
                    color: BMColors.pitch950,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        '© 2026 BallMatrix · footbasketballheightdataanalysisD',
 style: TextStyle(color: BMColors.textTertiary, fontSize: 10),
),
);
 }
}

// =====================================================================
// background: footballcourtcenter circle + forbiddenzoneitems (differentiation, hanklive yesdirectionchange)
// =====================================================================
class _BMFieldBgPainter extends CustomPainter {
 @override
 void paint(Canvas c, Size s) {
 final line = Paint()
..color = BMColors.bright.withValues(alpha: 0.055)
..style = PaintingStyle.stroke
..strokeWidth = 1.6;
 final cx = s.width / 2;
 final cy = s.height * 0.32;
 // center circle
 c.drawCircle(Offset(cx, cy), 92, line);
 // halfway line
 c.drawLine(Offset(0, cy), Offset(s.width, cy), line);
 // inopenballpoint
 c.drawCircle(
 Offset(cx, cy),
 2.5,
 Paint()..color = BMColors.bright.withValues(alpha: 0.08),
);
 // bottomrightforbiddenzone
 final pb = Paint()..color = BMColors.bright.withValues(alpha: 0.028);
 final bottomCx = s.width * 0.74;
 final bottomCy = s.height * 0.82;
 c.drawRRect(
 RRect.fromRectAndRadius(
 Rect.fromCenter(
 center: Offset(bottomCx, bottomCy),
 width: 160,
 height: 96,
),
 const Radius.circular(10),
),
 pb,
);
 }

 @override
 bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
