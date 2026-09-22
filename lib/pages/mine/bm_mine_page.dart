import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../login/bm_login_page.dart';
import '../../theme/bm_colors.dart';
import '../../utils/bm_auth_manager.dart';
import '../../models/bm_user_model.dart';

/// BMMinePage - 我的页面
/// 功能: 展示用户信息、统计仪表、分析报告、设置选项
/// 架构: MVVM View层
/// 作用范围: 底部导航第四个Tab
class BMMinePage extends BMBasePage {
  const BMMinePage({super.key});

  @override
  State<BMMinePage> createState() => _BMMinePageState();
}

class _BMMinePageState extends BMBasePageState<BMMinePage> {
  @override
  Widget buildBody(BuildContext context) {
    // 每次 build 读取最新内存中的登录态/用户信息 (登录成功 pop 返回时触发 setState 重新走这里)
    final BMUserModel? user = BMAuthManager().currentUser;
    final bool loggedIn = BMAuthManager().isLoggedIn;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(user, loggedIn),
          const SizedBox(height: 16),
          _buildStatsStrip(),
          const SizedBox(height: 16),
          _buildSavedReports(),
          const SizedBox(height: 16),
          _buildSettingsList(),
        ],
      ),
    );
  }

  /// 构建用户资料头部卡片
  /// [user] - 已登录: 真实 BMUserModel; 未登录: null → 使用占位文案
  /// [loggedIn] - 是否已登录 bool, 控制昵称/ID/头像数据源
  Widget _buildProfileHeader(BMUserModel? user, bool loggedIn) {
    final String nick = loggedIn && user?.nickname != null && user!.nickname!.isNotEmpty
        ? user.nickname!
        : '智算领航员';
    final String accountLabel = loggedIn && user != null
        ? 'ID: ${user.id ?? '—'} · ${user.account ?? user.email ?? '已登录账号'}'
        : 'ID: 88492041 · 专家级模型权限';
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
            onTap: () async {
              // 登录成功 Navigator.pop(true) → 这里 setState 重新 build, 自动拉最新 BMAuthManager.currentUser
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const BMLoginPage()),
              );
              if (result == true && mounted) {
                setState(() {});
              }
            },
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
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 28, color: BMColors.bright),
                    )
                  : const Icon(Icons.person, size: 28, color: BMColors.bright),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      nick,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    if (loggedIn)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [BMColors.amber, BMColors.gold]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'VIP PRO',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: BMColors.pitch950),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  accountLabel,
                  style: const TextStyle(fontSize: 12, color: BMColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计仪表条
  Widget _buildStatsStrip() {
    final stats = [
      ('82.4%', '模型命中率', BMColors.bright),
      ('142', '保存报告', BMColors.amber),
      ('18', '关注赛事', BMColors.cyan),
    ];
    return Row(
      children: stats.map((s) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: BMColors.pitch850.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BMColors.pitch700),
          ),
          child: Column(
            children: [
              Text(
                s.$1,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  color: s.$3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.$2,
                style: const TextStyle(fontSize: 10, color: BMColors.textSecondary),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  /// 构建已保存分析报告
  Widget _buildSavedReports() {
    final reports = [
      ('皇家马德里 vs 曼城 · 欧冠模型报告', '今天 08:30', '正回报', BMColors.bright),
      ('湖人 vs 勇士 · PACE 速度推算', '昨天 19:15', '已存档', BMColors.textSecondary),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.bookmark, size: 14, color: BMColors.bright),
                SizedBox(width: 6),
                Text(
                  '我的云端分析归档 (近期)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFCBD5E1)),
                ),
              ],
            ),
            Text('查看全部', style: TextStyle(fontSize: 10, color: BMColors.textTertiary)),
          ],
        ),
        const SizedBox(height: 8),
        ...reports.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.$1,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE2E8F0)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '生成时间: ${r.$2}',
                      style: const TextStyle(fontSize: 10, color: BMColors.textSecondary),
                    ),
                  ],
                ),
                Text(
                  r.$3,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: r.$4,
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  /// 构建设置列表
  Widget _buildSettingsList() {
    final settings = [
      (Icons.notifications, '推送预警设置', null, null),
      (Icons.tune, '默认分析模型算法权重', 'xG 混合 v4', BMColors.bright),
      (Icons.info_outline, '关于绿场智算 / 版本号', 'v2.4.0 Pro', BMColors.textTertiary),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '偏好设置与系统',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFCBD5E1)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: BMColors.pitch850.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BMColors.pitch700),
          ),
          child: Column(
            children: settings.map((s) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: s != settings.last
                      ? const BorderSide(color: Color(0x501C4537))
                      : BorderSide.none,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(s.$1, size: 16, color: BMColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        s.$2,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0)),
                      ),
                    ],
                  ),
                  if (s.$3 != null)
                    Text(
                      s.$3!,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: s.$4 ?? BMColors.textSecondary,
                      ),
                    )
                  else
                    const Icon(Icons.chevron_right, size: 12, color: BMColors.textTertiary),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}