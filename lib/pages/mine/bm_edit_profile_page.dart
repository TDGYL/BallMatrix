import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../utils/bm_auth_manager.dart';
import '../../models/bm_user_model.dart';

/// BMEditProfilePage - 编辑用户信息页
/// 功能: 修改头像(点击替换+昵称+个性签名，保存后回写 BMAuthManager.currentUser 内存+SharedPreferences
/// 差异化: 深绿主题，顶部胶囊保存按钮(与话题页一致，输入框 pitch850 深绿底，昵称48px高度，签名 6 行高
/// 架构: 单类单文件，继承 BMBasePage
class BMEditProfilePage extends BMBasePage {
  const BMEditProfilePage({super.key});

  @override
  State<BMEditProfilePage> createState() => _BMEditProfilePageState();
}

class _BMEditProfilePageState extends BMBasePageState<BMEditProfilePage> {
  /// 昵称输入控制器 (TextEditingController 类型)
  late final TextEditingController _nickCtrl;

  /// 个性签名输入控制器 (TextEditingController 类型)
  late final TextEditingController _signCtrl;

  /// 本地头像URL临时值 (String? 类型, 用户点击后修改时赋值)
  String? _avatarTemp;

  /// 是否保存中 (bool 类型, 防止重复点击)
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final BMUserModel? u = BMAuthManager().currentUser;
    _nickCtrl = TextEditingController(text: u?.nickname ?? '');
    _signCtrl = TextEditingController(text: u?.signature ?? '');
    _avatarTemp = u?.avatar;
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    _signCtrl.dispose();
    super.dispose();
  }

  /// 模拟保存：更新 BMAuthManager 内存 + SharedPreferences JSON
  /// TODO: 接入真实 BMNetworkManager 修改资料接口
  Future<void> _handleSave() async {
    if (_saving) return;
    final nick = _nickCtrl.text.trim();
    if (nick.isEmpty) {
      _snack('昵称不能为空');
      return;
    }
    setState(() => _saving = true);
    try {
      // TODO: 真实接口：PATCH /api/livespeed/member 更新资料
      await Future.delayed(const Duration(milliseconds: 600));
      final old = BMAuthManager().currentUser ?? BMUserModel();
      final updated = BMUserModel.fromJson({
        ...old.toJson(),
        'nickname': nick,
        'signature': _signCtrl.text.trim(),
        if (_avatarTemp != null && _avatarTemp!.isNotEmpty) 'avatar': _avatarTemp,
      });
      await BMAuthManager().saveUserInfo(updated);
      if (!mounted) return;
      _snack('保存成功');
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) _snack('保存失败, 请重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// SnackBar 统一提示
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: BMColors.pitch850,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return Scaffold(
      backgroundColor: BMColors.pitch900,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildAvatar(),
                    const SizedBox(height: 24),
                    _buildNickField(),
                    const SizedBox(height: 12),
                    _buildSignField(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 顶部导航栏：左侧返回 + 中间标题 + 右侧胶囊保存按钮
  Widget _buildAppBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: BMColors.pitch900,
        border: Border(bottom: BorderSide(color: BMColors.pitch700.withValues(alpha: 0.3))),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: BMColors.pitch850,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.chevron_left, color: Colors.white, size: 18),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.center,
            child: Text(
              '编辑资料',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _saving ? null : _handleSave,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _saving ? BMColors.pitch800 : BMColors.bright.withValues(alpha: 0.12),
                  border: Border.all(
                    color: _saving ? BMColors.pitch700.withValues(alpha: 0.5) : BMColors.bright.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _saving
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        '保存',
                        style: TextStyle(color: BMColors.bright, fontSize: 12, fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 头像修改：点击触发 mock 换头像 (实际未接相册/相机)
  Widget _buildAvatar() {
    return GestureDetector(
      onTap: () {
        // TODO: 接入 image_picker 选相册，此处模拟：时间戳URL占位
        setState(() {
          _avatarTemp = 'https://api.dicebear.com/7.x/notionists/png?seed=${DateTime.now().millisecondsSinceEpoch}';
        });
        _snack('已更换头像 (Mock)');
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: BMColors.bright, width: 2.5),
              color: BMColors.pitch800,
            ),
            child: _avatarTemp != null && _avatarTemp!.isNotEmpty
                ? Image.network(
                    _avatarTemp!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40, color: BMColors.bright),
                  )
                : const Icon(Icons.person, size: 40, color: BMColors.bright),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击更换头像',
            style: TextStyle(color: BMColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// 昵称输入框
  Widget _buildNickField() {
    return _fieldBox(
      label: '昵称',
      child: TextField(
        controller: _nickCtrl,
        maxLength: 16,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          counterText: '',
          hintText: '请输入昵称',
          hintStyle: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  /// 个性签名输入框
  Widget _buildSignField() {
    return _fieldBox(
      label: '个性签名',
      child: TextField(
        controller: _signCtrl,
        maxLines: 4,
        maxLength: 80,
        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          counterStyle: TextStyle(color: Color(0xFF6B7280), fontSize: 10),
          hintText: '介绍一下你自己吧 (最多80字)',
          hintStyle: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  /// 通用输入框容器
  Widget _fieldBox({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: BMColors.textSecondary),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: BMColors.pitch850,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
          ),
          child: child,
        ),
      ],
    );
  }
}
