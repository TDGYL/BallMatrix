import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  /// 原有云端头像URL (String? 类型, 用于对比用户是否修改了头像)
  String? _originAvatarUrl;

  /// 新选中的本地头像文件路径 (String? 类型, 用户从本地相册选图后赋值 File(XFile).path)
  String? _localAvatarPath;

  /// 是否保存中 (bool 类型, 防止重复点击)
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final BMUserModel? u = BMAuthManager().currentUser;
    _nickCtrl = TextEditingController(text: u?.nickname ?? '');
    _signCtrl = TextEditingController(text: u?.signature ?? '');
    _originAvatarUrl = u?.avatar;
    _localAvatarPath = null;
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    _signCtrl.dispose();
    super.dispose();
  }

  /// 保存: 1. toast 提示「提交成功, 等待审核」 2. 回写 BMAuthManager 内存+沙盒 3. 延迟退出当前页
  /// 注: 头像上传真实 OSS/后端接口待后续接入, 这里先把本地路径存进模型等待审核
  Future<void> _handleSave() async {
    if (_saving) return;
    final nick = _nickCtrl.text.trim();
    if (nick.isEmpty) {
      _snack('昵称不能为空');
      return;
    }
    setState(() => _saving = true);
    try {
      // 先更新 BMAuthManager (昵称/签名/新头像路径)
      final old = BMAuthManager().currentUser ?? BMUserModel();
      final updated = BMUserModel.fromJson({
        ...old.toJson(),
        'nickname': nick,
        'signature': _signCtrl.text.trim(),
        if (_localAvatarPath != null && _localAvatarPath!.isNotEmpty)
          'avatar': _localAvatarPath,
      });
      await BMAuthManager().saveUserInfo(updated);
      if (!mounted) return;
      // ⭐️ 需求1: toast 提示「提交成功，等待审核」
      _snack('提交成功，等待审核');
      // ⭐️ 需求2: 延迟 800ms 让用户看到 toast → 再退出当前页, 返回 true 让个人中心刷新
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) _snack('提交失败, 请重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 调用本地相册选头像 (image_picker: ImageSource.gallery)
  ///   无权限/用户取消/异常: 静默不提示或 toast 简单提示
  Future<void> _pickGalleryAvatar() async {
    try {
      final XFile? picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null) {
        // 用户点取消不提示
        return;
      }
      if (!mounted) return;
      setState(() => _localAvatarPath = picked.path);
      _snack('已选择头像');
    } catch (e) {
      if (!mounted) return;
      _snack('打开相册失败, 请检查权限');
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

  /// 头像修改：点击打开本地相册 (image_picker ImageSource.gallery)
  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _pickGalleryAvatar,
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
            child: _buildAvatarImg(),
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

  /// 头像图片渲染: 本地优先 > 云端网络图片 > 占位图标
  Widget _buildAvatarImg() {
    if (_localAvatarPath != null && _localAvatarPath!.isNotEmpty) {
      return Image.file(
        File(_localAvatarPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40, color: BMColors.bright),
      );
    }
    if (_originAvatarUrl != null && _originAvatarUrl!.isNotEmpty) {
      return Image.network(
        _originAvatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40, color: BMColors.bright),
      );
    }
    return const Icon(Icons.person, size: 40, color: BMColors.bright);
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
