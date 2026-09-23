import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../bm_base_page.dart';
import '../login/bm_login_page.dart';
import 'bm_edit_profile_page.dart';
import '../common/bm_webview_page.dart';
import '../../theme/bm_colors.dart';
import '../../utils/bm_auth_manager.dart';
import '../../network/bm_network_manager.dart';
import '../../models/bm_user_model.dart';
import '../../models/bm_hot_match_model.dart';
import '../match/bm_football_detail_page.dart';
import '../match/bm_basketball_detail_page.dart';

/// BMMinePage - 我的页面
/// 功能: 展示用户信息、热门比赛、设置、退出登录
/// 架构: MVVM View层
/// 作用范围: 底部导航第四个Tab
class BMMinePage extends BMBasePage {
  /// 父容器底部Tab切换监听 (ValueNotifier<int> 类型, 值范围 0~3)
  ///   作用: 当从其他Tab切回到 index=3 我的页面时, 如果已登录则刷新用户信息
  final ValueNotifier<int>? currentTabNotifier;

  const BMMinePage({
    super.key,
    this.currentTabNotifier,
  });

  @override
  State<BMMinePage> createState() => _BMMinePageState();
}

class _BMMinePageState extends BMBasePageState<BMMinePage> {
  /// 服务热线 (String 类型, 固定客服邮箱)
  static const String _kServiceHotline = 'BallMatrixService@gmail.com';

  /// 真实 APP 版本号 (String? 类型, 异步从 package_info_plus 拿 pubspec.yaml 中的 version 字段)
  ///   format: 'v$version+$buildNumber'  例: pubspec version:1.0.0+1 → 'v1.0.0+1'
  String? _appVersion;

  /// 热门比赛列表 (List<BMHotMatchModel> 类型, 真实 API 返回值)
  List<BMHotMatchModel> _hotMatches = const [];

  /// 热门比赛加载中状态 (bool 类型)
  bool _loadingHotMatches = true;

  /// 热门比赛加载失败提示 (String? 类型, null=未失败)
  String? _hotMatchesError;

  /// 用户信息是否刷新中 (bool 类型, 避免切Tab时重复请求)
  bool _refreshingUser = false;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    // 进入页面首帧前就开始请求热门比赛列表
    _loadHotMatches();
    // 监听底部Tab切换: 每次切到 index=3 我的页面且已登录 → 重新请求 /member 刷新用户
    widget.currentTabNotifier?.addListener(_onTabChanged);
    // 首帧渲染完后如果已经在"我的"Tab且已登录 → 立即刷新一次用户信息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if ((widget.currentTabNotifier?.value ?? 3) == 3 && BMAuthManager().isLoggedIn) {
        _refreshUserInfo();
      }
    });
  }

  @override
  void dispose() {
    widget.currentTabNotifier?.removeListener(_onTabChanged);
    super.dispose();
  }

  /// 底部Tab切换回调: 仅当切到"我的"Tab(index=3)且已登录时 → 刷新用户信息
  void _onTabChanged() {
    final idx = widget.currentTabNotifier?.value ?? 0;
    if (idx != 3) return;
    if (!BMAuthManager().isLoggedIn) return;
    _refreshUserInfo();
  }

  /// 刷新用户信息: 同登录成功后调用 GET /api/livespeed/member, 回写最新 user 到 BMAuthManager
  ///   需求: 每次打开我的页面时(如从其他Tab切回), 都用 token 拉最新用户数据刷新本地缓存
  Future<void> _refreshUserInfo() async {
    if (_refreshingUser || !mounted) return;
    _refreshingUser = true;
    try {
      final response = await BMNetworkManager().getRequest('/api/livespeed/member');
      if (!mounted) return;
      if (!response.isSuccess || response.data == null) {
        // token 失效等情况: 401 等直接不处理, 保留本地缓存
        return;
      }
      final dynamic raw = response.data;
      if (raw is! Map<String, dynamic>) return;
      final user = BMUserModel.fromJson(raw);
      // 更新内存 + SharedPreferences 持久化最新
      await BMAuthManager().saveUserInfo(user);
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      // 静默失败, 不打断用户 (网络错误不影响UI)
    } finally {
      _refreshingUser = false;
    }
  }

  /// 异步加载 APP 真实版本号 (来自 package_info_plus 的 PackageInfo.fromPlatform())
  /// 对应 pubspec.yaml 顶部 `version: 1.0.0+1` 字段
  Future<void> _loadAppVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        // 例: version='1.0.0' + buildNumber='1' -> 显示 'v1.0.0+1'
        _appVersion = 'v${info.version}+${info.buildNumber}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _appVersion = 'v1.0.0');
    }
  }

  /// 请求热门比赛接口: GET /api/livespeed/index/search/match/hot
  ///   无入参, 返回 List<BMHotMatchModel>
  Future<void> _loadHotMatches() async {
    setState(() {
      _loadingHotMatches = true;
      _hotMatchesError = null;
    });
    try {
      final response = await BMNetworkManager().getRequest(
        '/api/livespeed/index/search/match/hot',
      );
      if (!mounted) return;
      if (!response.isSuccess || response.data == null) {
        setState(() {
          _loadingHotMatches = false;
          _hotMatchesError = response.message ?? '暂无热门比赛数据';
        });
        return;
      }
      // 解析 List<Map> -> List<BMHotMatchModel>
      final List<BMHotMatchModel> result = [];
      final dynamic rawList = response.data;
      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            try {
              result.add(BMHotMatchModel.fromJson(item));
            } catch (_) {}
          }
        }
      }
      // 需求: 热门比赛只取前2条
      final finalList = result.length > 2 ? result.sublist(0, 2) : result;
      setState(() {
        _loadingHotMatches = false;
        _hotMatches = finalList;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingHotMatches = false;
        _hotMatchesError = '网络错误, 请稍后重试';
      });
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    final BMUserModel? user = BMAuthManager().currentUser;
    final bool loggedIn = BMAuthManager().isLoggedIn;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(user, loggedIn),
          const SizedBox(height: 20),
          _buildHotMatches(),
          const SizedBox(height: 20),
          _buildSettingsList(),
          if (loggedIn) ...[const SizedBox(height: 24), _buildLogoutButton()],
        ],
      ),
    );
  }

  // ================================================================
  // 顶部个人信息卡片 (已登录/未登录 两种UI)
  // ================================================================

  /// 构建用户资料头部卡片
  /// [user] - 已登录: 真实 BMUserModel; 未登录: null
  /// [loggedIn] - 是否已登录
  Widget _buildProfileHeader(BMUserModel? user, bool loggedIn) {
    final String nick =
        (loggedIn && user?.nickname != null && user!.nickname!.isNotEmpty)
        ? user.nickname!
        : '未登录';
    final String subLabel = loggedIn && user != null
        ? 'ID: ${user.id ?? '—'} · ${user.account ?? user.email ?? '已登录'}'
        : '点击头像登录账号';
    final String? avatarUrl = loggedIn ? user?.avatar : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xD9143328), Color(0xF00E261E)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BMColors.pitch600.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _onAvatarTap(loggedIn),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 56,
              height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: BMColors.bright, width: 2),
                color: BMColors.pitch800,
              ),
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 28,
                        color: BMColors.bright,
                      ),
                    )
                  : Icon(
                      loggedIn ? Icons.person : Icons.login,
                      size: 28,
                      color: BMColors.bright,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nick,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: BMColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!loggedIn)
            Icon(Icons.chevron_right, size: 20, color: BMColors.textTertiary),
        ],
      ),
    );
  }

  /// 头像点击处理
  /// 未登录 → push 登录页 → 登录成功 pop(true) → setState 刷新
  /// 已登录 → push 编辑页 → 保存后 pop(true) → setState 刷新
  Future<void> _onAvatarTap(bool loggedIn) async {
    final bool? changed;
    if (!loggedIn) {
      changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const BMLoginPage()),
      );
    } else {
      changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const BMEditProfilePage()),
      );
    }
    if (changed == true && mounted) {
      setState(() {});
    }
  }

  // ================================================================
  // 热门比赛列表
  // ================================================================

  /// 构建热门比赛卡片列表 (真实接口: GET /api/livespeed/index/search/match/hot, 无入参)
  ///   3 种状态: loading 骨架 / 错误提示 / 真实列表
  Widget _buildHotMatches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.local_fire_department, size: 14, color: BMColors.amber),
            SizedBox(width: 6),
            Text(
              '热门比赛',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFCBD5E1),
              ),
            ),
            // ⚠️ 根据需求: 右侧"查看全部"已删除
          ],
        ),
        const SizedBox(height: 8),
        if (_loadingHotMatches)
          _buildHotMatchesLoading()
        else if (_hotMatchesError != null)
          _buildHotMatchesError(_hotMatchesError!)
        else if (_hotMatches.isEmpty)
          _buildHotMatchesEmpty()
        else
          ..._hotMatches.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _HotMatchCard(match: m),
            ),
          ),
      ],
    );
  }

  /// 热门比赛: 加载中骨架 (3 行渐变骨架, 不显示空白)
  Widget _buildHotMatchesLoading() {
    return Column(
      children: List.generate(3, (_) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: BMColors.pitch850.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.4)),
          ),
          child: const Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(color: BMColors.bright, strokeWidth: 2),
            ),
          ),
        ),
      )),
    );
  }

  /// 热门比赛: 加载错误占位 (可点击重试)
  Widget _buildHotMatchesError(String err) {
    return GestureDetector(
      onTap: _loadHotMatches,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: BMColors.pitch850.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(Icons.refresh, size: 16, color: BMColors.bright),
            const SizedBox(height: 4),
            Text(
              err,
              style: const TextStyle(fontSize: 11, color: BMColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            const Text(
              '点击重试',
              style: TextStyle(fontSize: 10, color: BMColors.bright, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  /// 热门比赛: 空列表占位
  Widget _buildHotMatchesEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: BMColors.pitch850.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.4)),
      ),
      child: const Text(
        '暂无热门比赛',
        style: TextStyle(fontSize: 11, color: BMColors.textTertiary),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ================================================================
  // 设置列表 4行: 在线客服 / 用户协议 / 隐私政策 / 版本号
  // ================================================================

  /// 构建设置列表
  Widget _buildSettingsList() {
    final settings = <_SettingItem>[
      _SettingItem(
        icon: Icons.call_outlined,
        label: '在线客服',
        trailing: _kServiceHotline,
        trailingColor: BMColors.bright,
        showChevron: false,
        onTap: () => _snack('在线客服 $_kServiceHotline'),
      ),
      _SettingItem(
        icon: Icons.article_outlined,
        label: '用户协议',
        showChevron: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BMWebViewPage(
                htmlFileName: 'user-agreement.html',
              ),
            ),
          );
        },
      ),
      _SettingItem(
        icon: Icons.shield_outlined,
        label: '隐私政策',
        showChevron: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BMWebViewPage(
                htmlFileName: 'privacy-agreement.html',
              ),
            ),
          );
        },
      ),
      _SettingItem(
        icon: Icons.info_outline,
        label: '版本号',
        trailing: _appVersion,
        trailingColor: BMColors.textTertiary,
        showChevron: false,
        onTap: null,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '偏好设置与系统',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFCBD5E1),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: BMColors.pitch850.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BMColors.pitch700),
          ),
          child: Column(
            children: List.generate(settings.length, (i) {
              final s = settings[i];
              final isLast = i == settings.length - 1;
              return GestureDetector(
                onTap: s.onTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: isLast
                          ? BorderSide.none
                          : const BorderSide(color: Color(0x501C4537)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(s.icon, size: 16, color: BMColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            s.label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ],
                      ),
                      if (s.trailing != null)
                        Text(
                          s.trailing!,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: s.trailingColor,
                          ),
                        ),
                      if (s.showChevron)
                        const Icon(
                          Icons.chevron_right,
                          size: 12,
                          color: BMColors.textTertiary,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // 退出登录 (仅登录时显示)
  // ================================================================

  /// 构建底部退出登录按钮 (仅登录时显示)
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _confirmLogout,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F0),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: const Color(0xFFFCA5A5), width: 1.0),
        ),
        child: const Text(
          '退出登录',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  /// 二次确认弹窗 → 确认 → 清除本地用户信息 + 请求头移除 token
  Future<void> _confirmLogout() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: BMColors.pitch900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          '确认退出登录?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '退出后将删除本地登录信息, 需要重新登录才能使用个性化功能',
          style: TextStyle(
            color: BMColors.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              '取消',
              style: TextStyle(color: BMColors.textSecondary, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '确认退出',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (result != true || !mounted) return;

    // 1. BMAuthManager.logout(): 清内存token+清内存user + SharedPreferences 删除 bm_user_token + bm_user_info
    // 2. BMNetworkManager.clearAuthToken(): 移除请求头 Authorization
    await BMAuthManager().logout();

    // 保证 token 已从请求头彻底移除 (双重确保)
    BMNetworkManager().clearAuthToken();

    // 兜底清理: 直接操作 SharedPreferences 再次删除 key (防止历史缓存)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bm_user_token');
    await prefs.remove('bm_user_info');

    if (!mounted) return;
    _snack('已退出登录');

    // 需求7: 退出后 setState 重新走 buildBody → 自动切换为"未登录 UI"占位
    setState(() {});
  }

  /// SnackBar 统一提示
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: BMColors.pitch850,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// =====================================================================
// 辅助私有模型 & Widget
// =====================================================================

/// 设置行模型
class _SettingItem {
  /// 左侧图标 (IconData 类型)
  final IconData icon;

  /// 标题文字 (String 类型)
  final String label;

  /// 右侧副标题 (String? 类型, 版本号/服务热线显示值)
  final String? trailing;

  /// 副标题颜色 (Color 类型)
  final Color trailingColor;

  /// 是否显示右侧 chevron 箭头 (bool 类型)
  final bool showChevron;

  /// 点击回调 (VoidCallback? 类型)
  final VoidCallback? onTap;

  _SettingItem({
    required this.icon,
    required this.label,
    this.trailing,
    this.trailingColor = BMColors.textSecondary,
    required this.showChevron,
    this.onTap,
  });
}

/// 热门比赛卡片 (真实接口数据)
///   左: 主队logo + 主队名 vs 客队名 + 客队logo
///   左上: 联赛名 + 分类小标签 (足球/篮球)
///   左下: 开赛时间 MM/DD HH:mm
///   右: 当前比分 (未开赛=空格占位, 进行中=比分亮绿加粗)
class _HotMatchCard extends StatelessWidget {
  final BMHotMatchModel match;
  const _HotMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final bool hasStarted =
        (match.homeTeamScore ?? 0) > 0 || (match.awayTeamScore ?? 0) > 0;
    final String score = hasStarted
        ? '${match.homeTeamScore ?? 0} : ${match.awayTeamScore ?? 0}'
        : 'VS';
    final Color scoreColor = hasStarted ? BMColors.bright : BMColors.textTertiary;
    final FontWeight scoreWeight =
        hasStarted ? FontWeight.w900 : FontWeight.w700;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final m = match.toMatchModel;
        if (m.matchId.isEmpty) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => match.category == 1
                ? BMFootballDetailPage(match: m)
                : BMBasketballDetailPage(match: m),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xD9143328), Color(0xF00E261E)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BMColors.pitch600.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            // 顶部: 联赛名 + 项目小标签
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: BMColors.pitch800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    match.categoryLabel,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: BMColors.bright,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    match.competitionName ?? '联赛',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: BMColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  match.formattedMatchTime,
                  style: const TextStyle(
                    fontSize: 10,
                    color: BMColors.textTertiary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 中间: 主队logo + VS/比分 + 客队logo
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 主队
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          match.homeTeamName ?? '主队',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TeamLogo(url: match.homeTeamLogo),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  constraints: const BoxConstraints(minWidth: 56),
                  alignment: Alignment.center,
                  child: Text(
                    score,
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: 1.5,
                      fontFamily: 'monospace',
                      color: scoreColor,
                      fontWeight: scoreWeight,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 客队
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _TeamLogo(url: match.awayTeamLogo),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          match.awayTeamName ?? '客队',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 球队logo (32x32 圆形，加载失败用首字占位)
class _TeamLogo extends StatelessWidget {
  final String? url;
  const _TeamLogo({this.url});

  @override
  Widget build(BuildContext context) {
    final u = url ?? '';
    if (u.isEmpty) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: BMColors.pitch800,
          shape: BoxShape.circle,
          border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
        ),
        child: const Icon(Icons.sports_soccer, size: 14, color: BMColors.bright),
      );
    }
    return Container(
      width: 30,
      height: 30,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: BMColors.pitch800,
        shape: BoxShape.circle,
        border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
      ),
      child: Image.network(
        u,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.sports_soccer, size: 14, color: BMColors.bright),
      ),
    );
  }
}
