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

/// BMMinePage - my of page
/// feature: showuserinfo、hot matches、settings、logout
/// architecture: MVVM Viewlayer
/// purposescope: bottomnavigationNo. fouritemsTab
class BMMinePage extends BMBasePage {
  /// containerbottomTabswitchlistener (ValueNotifier<int> type, valuescope 0~3)
  /// purpose: whenfromothersTabbackto index=3 my of pagewhen, likeresultlogged inthenrefreshuserinfo
  final ValueNotifier<int>? currentTabNotifier;

  const BMMinePage({super.key, this.currentTabNotifier});

  @override
  State<BMMinePage> createState() => _BMMinePageState();
}

class _BMMinePageState extends BMBasePageState<BMMinePage> {
  /// serviceline (String type, fixedsupportemail)
  static const String _kServiceHotline = 'BallMatrixService@gmail.com';

  /// trueactual APP versionNo. (String? type, asyncfrom package_info_plus get pubspec.yaml in of version field)
  /// format: 'v$version+$buildNumber' e.g.: pubspec version:1.0.0+1 → 'v1.0.0+1'
  String? _appVersion;

  /// hot matcheslist (List<BMHotMatchModel> type, trueactual API return value)
  List<BMHotMatchModel> _hotMatches = const [];

  /// hot matchesloadinginstate (bool type)
  bool _loadingHotMatches = true;

  /// hot matchesLoad Failedtoast (String? type, null=not yetfailure)
  String? _hotMatchesError;

  /// userinfowhetherrefreshin (bool type, Tabwhenduplicaterequest)
  bool _refreshingUser = false;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    // enterpagefirststartrequesthot matcheslist
    _loadHotMatches();
    // listenerbottomTabswitch: each timeto index=3 my of pageandlogged in → re-request /member refreshuser
    widget.currentTabNotifier?.addListener(_onTabChanged);
    // rendercompletelaterlikeresultalready"my of "Tabandlogged in → immediatelyrefreshonetimeuserinfo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if ((widget.currentTabNotifier?.value ?? 3) == 3 &&
          BMAuthManager().isLoggedIn) {
        _refreshUserInfo();
      }
    });
  }

  @override
  void dispose() {
    widget.currentTabNotifier?.removeListener(_onTabChanged);
    super.dispose();
  }

  /// bottomTabswitchcallback: onlywhento"my of "Tab(index=3)andlogged inwhen → refreshuserinfo
  void _onTabChanged() {
    final idx = widget.currentTabNotifier?.value ?? 0;
    if (idx != 3) return;
    if (!BMAuthManager().isLoggedIn) return;
    _refreshUserInfo();
  }

  /// refreshuserinfo: sameloginsuccesslatercall GET /api/livespeed/member, backwritelatest user to BMAuthManager
  /// requirement: each timeopenmy of pagewhen(likefromothersTabback), use token latestuserdatarefreshlocalcache
  Future<void> _refreshUserInfo() async {
    if (_refreshingUser || !mounted) return;
    _refreshingUser = true;
    try {
      final response = await BMNetworkManager().getRequest(
        '/api/livespeed/member',
      );
      if (!mounted) return;
      if (!response.isSuccess || response.data == null) {
        // token effectwaitcase: 401 waitnothandle, keeplocalcache
        return;
      }
      final dynamic raw = response.data;
      if (raw is! Map<String, dynamic>) return;
      final user = BMUserModel.fromJson(raw);
      // updatememory + SharedPreferences persistlatest
      await BMAuthManager().saveUserInfo(user);
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      // failure, notbreakuser (networkerrornotimpactUI)
    } finally {
      _refreshingUser = false;
    }
  }

  /// asyncloading APP trueactualversionNo. ( package_info_plus of PackageInfo.fromPlatform())
  /// corresponding pubspec.yaml top `version: 1.0.0+1` field
  Future<void> _loadAppVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        // e.g.: version='1.0.0' + buildNumber='1' -> display 'v1.0.0+1'
        _appVersion = 'v${info.version}+${info.buildNumber}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _appVersion = 'v1.0.0');
    }
  }

  /// requesthot matchesAPI: GET /api/livespeed/index/search/match/hot
  /// noneinput, returns List<BMHotMatchModel>
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
          _hotMatchesError = response.message ?? 'no hot matchesdata';
        });
        return;
      }
      // parse List<Map> -> List<BMHotMatchModel>
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
      // requirement: hot matchesonlytakefirst2items
      final finalList = result.length > 2 ? result.sublist(0, 2) : result;
      setState(() {
        _loadingHotMatches = false;
        _hotMatches = finalList;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingHotMatches = false;
        _hotMatchesError = 'networkerror, please retry later';
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
  // topprofileinfocard (logged in/not logged in kindUI)
  // ================================================================

  /// builduserprofileheadercard
  /// [user] - logged in: trueactual BMUserModel; not logged in: null
  /// [loggedIn] - whetherlogged in
  Widget _buildProfileHeader(BMUserModel? user, bool loggedIn) {
    final String nick =
        (loggedIn && user?.nickname != null && user!.nickname!.isNotEmpty)
        ? user.nickname!
        : 'not logged in';
    final String subLabel = loggedIn && user != null
        ? 'ID: ${user.id ?? '—'} · ${user.account ?? user.email ?? 'logged in'}'
        : 'Tap avatar to sign in';
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

  /// avatartap handler
  /// not logged in → push loginpage → loginsuccess pop(true) → setState refresh
  /// logged in → push editpage → savelater pop(true) → setState refresh
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
  // hot matcheslist
  // ================================================================

  /// buildmatch cardlist (trueactual API: GET /api/livespeed/index/search/match/hot, noneinput)
  /// 3 kindstate: loading skeleton / errortoast / trueactuallist
  Widget _buildHotMatches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.local_fire_department, size: 14, color: BMColors.amber),
            SizedBox(width: 6),
            Text(
              'hot matches',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFCBD5E1),
              ),
            ),
            // ⚠️ datarequirement: right side"view all"alreadyremove
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

  /// hot matches: loadinginskeleton (3 linechangeskeleton, notdisplayemptywhite)
  Widget _buildHotMatchesLoading() {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: BMColors.pitch850.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: BMColors.pitch700.withValues(alpha: 0.4),
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: BMColors.bright,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// hot matches: loadingerrorplaceholder (cantapretry)
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
              style: const TextStyle(
                fontSize: 11,
                color: BMColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            const Text(
              'tapretry',
              style: TextStyle(
                fontSize: 10,
                color: BMColors.bright,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// hot matches: emptylistplaceholder
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
        'no hot matches',
        style: TextStyle(fontSize: 11, color: BMColors.textTertiary),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ================================================================
  // settingslist 4line: support / User Agreement / Privacy Policy / versionNo.
  // ================================================================

  /// buildsettingslist
  Widget _buildSettingsList() {
    final settings = <_SettingItem>[
      _SettingItem(
        icon: Icons.call_outlined,
        label: 'support',
        trailing: _kServiceHotline,
        trailingColor: BMColors.bright,
        showChevron: false,
        onTap: () => _snack('support $_kServiceHotline'),
      ),
      _SettingItem(
        icon: Icons.article_outlined,
        label: 'User Agreement',
        showChevron: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const BMWebViewPage(htmlFileName: 'user-agreement.html'),
            ),
          );
        },
      ),
      _SettingItem(
        icon: Icons.shield_outlined,
        label: 'Privacy Policy',
        showChevron: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const BMWebViewPage(htmlFileName: 'privacy-agreement.html'),
            ),
          );
        },
      ),
      _SettingItem(
        icon: Icons.info_outline,
        label: 'versionNo.',
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
          'Preferences & System',
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
  // logout (onlyloginwhendisplay)
  // ================================================================

  /// buildbottomlogoutbutton (onlyloginwhendisplay)
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
          'logout',
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

  /// double confirmationdialog → confirm → divlocaluserinfo + requestheaderremove token
  Future<void> _confirmLogout() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: BMColors.pitch900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Confirm Logout?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'logout later will remove local login info, need sheavy new login ability makeuse items feature',
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
              'Cancel',
              style: TextStyle(color: BMColors.textSecondary, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Confirm',
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

    // 1. BMAuthManager.logout(): memorytoken+memoryuser + SharedPreferences remove bm_user_token + bm_user_info
    // 2. BMNetworkManager.clearAuthToken(): removerequestheader Authorization
    await BMAuthManager().logout();

    // token alreadyfromrequestheaderbottomremove (doubleheavy)
    BMNetworkManager().clearAuthToken();

    // fallback: do SharedPreferences againtimeremove key (historycache)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bm_user_token');
    await prefs.remove('bm_user_info');

    if (!mounted) return;
    _snack('Logged out');

    // requirement7: logoutlater setState heavynew buildBody → autoswitchas"not logged in UI"placeholder
    setState(() {});
  }

  /// SnackBar unified toast
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
// auxiliaryprivatemodel & Widget
// =====================================================================

/// settingslinemodel
class _SettingItem {
  /// left sideicon (IconData type)
  final IconData icon;

  /// titletext (String type)
  final String label;

  /// right sidecopytitle (String? type, versionNo./servicelinedisplayvalue)
  final String? trailing;

  /// copytitlecolor (Color type)
  final Color trailingColor;

  /// whetherdisplayright side chevron arrow (bool type)
  final bool showChevron;

  /// tap callback (VoidCallback? type)
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

/// match card (trueactual APIdata)
/// left: home teamlogo + home teamname vs away teamname + away teamlogo
/// leftupper: league name + split classessmalltag (football/basketball)
/// leftlower: kickoff time MM/DD HH:mm
/// right: currentscore (not started=emptygridplaceholder, in progress=scorebright greenadd)
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
    final Color scoreColor = hasStarted
        ? BMColors.bright
        : BMColors.textTertiary;
    final FontWeight scoreWeight = hasStarted
        ? FontWeight.w900
        : FontWeight.w700;
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
            // top: league name + itemitemsmalltag
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
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
                    match.competitionName ?? 'league',
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
            // middle: home teamlogo + VS/score + away teamlogo
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // home team
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          match.homeTeamName ?? 'home team',
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
                // away team
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _TeamLogo(url: match.awayTeamLogo),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          match.awayTeamName ?? 'away team',
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

/// teamlogo (32x32 circle，Load Failedusetextplaceholder)
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
        child: const Icon(
          Icons.sports_soccer,
          size: 14,
          color: BMColors.bright,
        ),
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
