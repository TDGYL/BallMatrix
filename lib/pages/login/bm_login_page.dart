import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:captcha_plugin_flutter/captcha_plugin_flutter.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../network/bm_network_manager.dart';
import '../../utils/bm_auth_manager.dart';
import '../../models/bm_user_model.dart';

/// BMLoginPage - 登录/注册页
/// 功能流程: 邮箱 → 易盾人机验证 → 发送验证码 → 输入验证码+勾选协议 → 登录
/// 差异化设计 (对比 hanklive 紫色 背景):
/// 1. 深绿 BallMatrix 主题 (pitch900 / pitch850 / bright) - 紫色系差异化
/// 2. 背景渐变条纹 + 足球场中圈虚化背景（不是彩色径向渐变圆）
/// 3. 左侧亮绿 3px 竖条 → 亮绿左侧圆弧 差异化
/// 4. 提交按钮使用 Capsule 胶囊 50px 高度（和 topicList 发布按钮一致的样式）
/// API 复用 hanklive 相同路径:
///   POST /api/livespeed/auth/send-verify  (channel="email")
///   POST /api/livespeed/auth/login
///   GET  /api/livespeed/member
/// 架构: 单类单文件, 继承 BMBasePage
class BMLoginPage extends BMBasePage {
  const BMLoginPage({super.key});

  @override
  State<BMLoginPage> createState() => _BMLoginPageState();
}

class _BMLoginPageState extends BMBasePageState<BMLoginPage> {
  /// 邮箱输入控制器 (TextEditingController 类型)
  final TextEditingController _emailCtrl = TextEditingController();

  /// 验证码输入控制器 (TextEditingController 类型)
  final TextEditingController _codeCtrl = TextEditingController();

  /// 是否已勾选协议 (bool 类型, false=未勾选, 不允许登录)
  bool _isAgree = false;

  /// 是否正在登录提交 (bool 类型, 防止重复提交)
  bool _isLoading = false;

  /// 是否正在发送验证码 (bool 类型, 防止重复点击)
  bool _isSending = false;

  /// 倒计时秒数 (int 类型, 0=倒计时结束可重发)
  int _countdown = 0;

  /// 倒计时定时器 (Timer? 类型, 页面销毁时 cancel)
  Timer? _countdownTimer;

  /// 易盾SDK 8s 超时兜底定时器 (Timer? 类型, 防止原生SDK未配置好导致无回调卡死)
  Timer? _captchaTimer;

  /// 易盾SDK 是否已回调成功/失败 (bool 类型, 防止重复触发 _sendVerifyCode)
  bool _captchaDone = false;

  /// 易盾验证码 SDK 实例 (CaptchaPluginFlutter 类型)
  final CaptchaPluginFlutter _captcha = CaptchaPluginFlutter();

  /// 易盾验证码 businessId / captchaId (String 类型, 用户提供的固定值)
  static const String _captchaVerifyCode = '69d5b2ee3fec46658e01c0b45fc381af';

  /// 邮箱格式校验正则 (bool Function(String) 类型)
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

  /// 点击「获取验证码」: 邮箱校验 → 立刻按钮loading → 易盾SDK人机验证 → onSuccess回调真实validate → 传真实validate给POST /api/livespeed/auth/send-verify
  /// 关键约束: ⭐️ 只有 _captcha.showCaptcha 的 onSuccess 回调返回真实 validate 才会调 send-verify 接口;
  ///           超时/onError/SDK异常/用户主动关弹窗 4 种兜底场景**不触发真实发送**, 只提示用户(避免浪费真实短信发送次数)
  void _handleGetCode() {
    if (_countdown > 0 || _isSending) return;
    final email = _emailCtrl.text.trim();
    if (!_isEmail(email)) {
      _snack('请输入有效的邮箱地址');
      return;
    }

    // ⭐️ 调用SDK前立刻进入loading，按钮立即变成转圈，用户不会觉得卡死
    setState(() => _isSending = true);
    _captchaDone = false;
    _captchaTimer?.cancel();

    // 卡死保护：6s 超时(给易盾弹窗足够显示时间) → 不发真实验证码，只提示用户重试
    _captchaTimer = Timer(const Duration(seconds: 6), () {
      if (_captchaDone || !mounted) return;
      _captchaDone = true;
      debugPrint('🛡️ BMLogin captcha TIMEOUT 6s -> NO REAL SEND');
      _snack('人机验证加载超时, 请检查网络后重试');
      if (mounted) setState(() => _isSending = false);
    });

    // 调起易盾人机验证 SDK
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
          // ✅ 唯一真实发送路径：从 captcha_plugin_flutter 回调的 Map 里取出 validate 字符串
          final validate = (data is Map && data['validate'] is String)
              ? data['validate'] as String
              : '';
          if (validate.isEmpty) {
            _snack('人机验证失败, 请重试');
            if (mounted) setState(() => _isSending = false);
            return;
          }
          // 将真实 validate 传给 /api/livespeed/auth/send-verify 接口发邮箱验证码
          await _sendVerifyCode(validate);
        },
        onError: (dynamic data) {
          if (_captchaDone) return;
          _captchaTimer?.cancel();
          _captchaDone = true;
          debugPrint('🛡️ BMLogin captcha error: $data');
          // ❌ 不发真实验证码
          _snack('人机验证失败, 请重试');
          if (mounted) setState(() => _isSending = false);
        },
        onClose: (dynamic data) {
          debugPrint('🛡️ BMLogin captcha close: $data');
          _captchaTimer?.cancel();
          // 用户主动关闭弹窗且没走成功分支 → 恢复按钮可点(不发真实验证码)
          if (!_captchaDone && mounted) {
            setState(() => _isSending = false);
          }
        },
      );
    } catch (e) {
      // SDK 抛异常 (插件未注册/平台未集成) → 不发真实验证码, 只提示
      if (_captchaDone) return;
      _captchaTimer?.cancel();
      _captchaDone = true;
      debugPrint('🛡️ BMLogin captcha EXCEPTION: $e');
      _snack('人机验证 SDK 异常, 请重试');
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// 请求发送邮件验证码接口 (和 hanklive 1:1 相同 URL/参数, channel=email)
  /// ⭐️ [validate] - **必须是 captcha_plugin_flutter 的 onSuccess 回调返回的真实 validate**
  /// API: POST /api/livespeed/auth/send-verify
  /// body: {validate, account, channel:'email', scene:'sms-login'}
  /// 成功后启动 60s 倒计时
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
        _snack(response.message ?? '验证码已发送, 请查收邮箱');
        _startCountdown();
      } else {
        _snack(response.message ?? '验证码发送失败, 请重试');
      }
    } catch (e) {
      _snack('网络错误, 请重试');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// 启动 60s 倒计时
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

  /// 点击「登录/注册」: 校验 → 登录API → saveToken到SharedPreferences + 注入请求头 → /member拉用户 → saveUserInfo → Navigator.pop(true) 通知外部刷新
  /// API 1: POST /api/livespeed/auth/login  {channel:'email', account, code} → refresh_token
  /// API 2: GET  /api/livespeed/member  → 用 token 拉取用户信息
  /// 持久化 1: BMAuthManager.saveToken → 内存 + SharedPreferences + BMNetworkManager setAuthToken 请求头
  /// 持久化 2: BMAuthManager.saveUserInfo → 内存 + SharedPreferences JSON
  /// 通知外部: Navigator.pop(true) 返回 true, 外部可 then((v)=>v==true?刷新用户头:null)
  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    if (!_isEmail(email)) {
      _snack('请输入有效的邮箱地址');
      return;
    }
    if (_codeCtrl.text.trim().isEmpty) {
      _snack('请输入验证码');
      return;
    }
    if (!_isAgree) {
      _snack('请先勾选并同意用户协议与隐私政策');
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Step 1: 登录接口拿 token (和 hanklive 1:1)
      final loginResponse = await BMNetworkManager().postRequest(
        '/api/livespeed/auth/login',
        data: {
          'channel': 'email',
          'account': email,
          'code': _codeCtrl.text.trim(),
        },
      );
      if (!loginResponse.isSuccess || loginResponse.data == null) {
        if (mounted) _snack(loginResponse.message ?? '登录失败');
        return;
      }
      final dynamic data = loginResponse.data;
      final refreshToken = (data is Map && data['refresh_token'] is String)
          ? data['refresh_token'] as String
          : null;
      if (refreshToken == null || refreshToken.isEmpty) {
        if (mounted) _snack('登录失败: Token 无效');
        return;
      }

      // Step 2: 保存 token 到 SharedPreferences + 注入请求头
      await BMAuthManager().saveToken(refreshToken);

      // Step 3: 用新 token 拉用户信息 (和 hanklive 1:1 GET /api/livespeed/member)
      final userResponse = await BMNetworkManager().getRequest('/api/livespeed/member');
      if (!userResponse.isSuccess || userResponse.data == null) {
        if (mounted) _snack(userResponse.message ?? '获取用户信息失败');
        return;
      }
      final dynamic userRaw = userResponse.data;
      if (userRaw is! Map<String, dynamic>) {
        if (mounted) _snack('用户信息格式异常');
        return;
      }

      // Step 4: 保存用户信息到 SharedPreferences
      final user = BMUserModel.fromJson(userRaw);
      await BMAuthManager().saveUserInfo(user);

      // Step 5: 登录成功 SnackBar + pop 返回 true 通知外部刷新
      if (!mounted) return;
      _snack('登录成功, 欢迎回来 ${user.nickname ?? '球友'} 👋');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _snack('登录失败, 请重试');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// SnackBar 统一提示
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
            // 背景: 足球场中圈虚化条纹 + 两对角深绿光晕 (和 hanklive 径向渐变圆差异化)
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
        // 品牌胶囊 (差异化: 和话题页发布按钮同样式, 亮绿 12%填充+描边)
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
            // 左侧装饰: 亮绿胶囊竖条 (和 hanklive 3px 竖条差异化)
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
          '邮箱验证登录, 加入 60 万+ 球迷分析师社群',
          style: TextStyle(
            color: BMColors.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// 构建单个输入框容器 (公共样式抽离, pitch850 + pitch700 描边)
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
                hintText: '请输入邮箱地址',
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
                      hintText: '邮箱验证码',
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
        // 获取验证码按钮 (capsule 胶囊, 亮绿/深灰)
        GestureDetector(
          onTap: (_countdown > 0 || _isSending) ? null : _handleGetCode,
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
                    _countdown > 0 ? '${_countdown}s 重发' : '获取验证码',
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
              text: '我已阅读并同意 ',
              style: TextStyle(
                color: BMColors.textSecondary,
                fontSize: 11,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: '《用户协议》',
                  style: const TextStyle(
                    color: BMColors.bright,
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => debugPrint('📄 用户协议'),
                ),
                const TextSpan(text: ' 与 '),
                TextSpan(
                  text: '《隐私政策》',
                  style: const TextStyle(
                    color: BMColors.bright,
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => debugPrint('📄 隐私政策'),
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
                  '立即登录',
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
        '© 2026 BallMatrix · 足篮球高阶数据分析平台',
        style: TextStyle(color: BMColors.textTertiary, fontSize: 10),
      ),
    );
  }
}

// =====================================================================
// 背景: 虚化足球场中圈 + 禁区条纹 (差异化, hanklive 是径向渐变圆)
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
    // 中圈
    c.drawCircle(Offset(cx, cy), 92, line);
    // 中线
    c.drawLine(Offset(0, cy), Offset(s.width, cy), line);
    // 中心开球点
    c.drawCircle(
      Offset(cx, cy),
      2.5,
      Paint()..color = BMColors.bright.withValues(alpha: 0.08),
    );
    // 底部右禁区
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
