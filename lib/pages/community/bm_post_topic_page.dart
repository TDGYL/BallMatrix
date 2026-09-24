import 'package:flutter/material.dart';

import '../../models/bm_search_match_model.dart';
import '../../services/bm_community_api_service.dart';
import '../../theme/bm_colors.dart';
import '../../utils/bm_auth_manager.dart';
import '../bm_base_page.dart';
import '../login/bm_login_page.dart';
import 'bm_post_topic_match_search_page.dart';

/// BMPostTopicPage - post topicpage (topiclistpagetop-right corner「publish」push enter)
/// featurealigned with API hanklive HankPostCommunityPage:
/// 1. top: topiccontentmorelineinput field (less10text)
/// 2. middle: related match entry (push searchpageselect, canremove)
/// 3. bottom: multi-selecttopictagmenu (fixedwaitshow + refresh)
/// 4. publish: POST /api/livespeed/community/save
/// argument: {id: 0, content, images: [topiccomma No.string], match_type, match_id}
/// 5. not logged infirstjumploginpage
/// UI differentiation: darkpitch green theme (pitch950 bottom + bright greenhomecolor + strokeinputzone + bottomfixedpublishitems),
/// referencepageaswhitebottom + topbar Post buttonlayout, visually distinct
class BMPostTopicPage extends BMBasePage {
  const BMPostTopicPage({super.key});

  @override
  State<BMPostTopicPage> createState() => _BMPostTopicPageState();
}

class _BMPostTopicPageState extends BMBasePageState<BMPostTopicPage> {
  /// contentinputcontroller (TextEditingController type)
  final TextEditingController _contentController = TextEditingController();

  /// community API service (BMCommunityApiService type, publishAPI)
  final BMCommunityApiService _apiService = BMCommunityApiService();

  /// topicwait (List<String> type, alignment hanklive 12 itemstopic)
  static const List<String> _allTopics = [
    'match',
    'Tactical Analysis',
    'conversion state',
    'backuptest',
    'Champion Prediction',
    'observe',
    'fans',
    'matchresult',
    'playerpoint',
    'historyback',
    'ruleread',
    'leagueend',
  ];

  /// currentshow of topic (List<String> type, waittake5items)
  List<String> _topics = [];

  /// selectedtopic (List<String> type, multi-select)
  final List<String> _selectedTopics = [];

  /// selectedrelated match (BMSearchMatch? type, null=not yetclose)
  BMSearchMatch? _selectedMatch;

  /// publishin (bool type, duplicate)
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    // initialstartshow 5 itemstopic
    _topics = _randomTopics(5);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// fromwaittake N itemsnot yetshow of topic
  /// [count] - takeoutputcount (int type)
  /// returns: List<String> topiclist
  List<String> _randomTopics(int count) {
    final pool = List<String>.from(_allTopics);
    pool.shuffle();
    return pool.take(count).toList();
  }

  /// refreshtopic (orderdivcurrentshow of, heavyplace)
  void _shuffleTopics() {
    setState(() {
      _topics = _randomTopics(5);
    });
  }

  /// switchtopicselectedstate (multi-select)
  /// [topic] - topictag (String type)
  void _toggleTopic(String topic) {
    setState(() {
      if (_selectedTopics.contains(topic)) {
        _selectedTopics.remove(topic);
      } else {
        _selectedTopics.add(topic);
      }
    });
  }

  /// navigatematchsearchpageselectrelated match (pop returns BMSearchMatch)
  Future<void> _pickMatch() async {
    final match = await Navigator.push<BMSearchMatch>(
      context,
      MaterialPageRoute(builder: (_) => const BMPostTopicMatchSearchPage()),
    );
    if (match != null) {
      setState(() => _selectedMatch = match);
    }
  }

  /// removealreadyrelated match
  void _removeMatch() {
    setState(() => _selectedMatch = null);
  }

  /// post topic (POST /api/livespeed/community/save)
  /// validate: contentless10text → not logged injumplogin → → success pop(true)
  Future<void> _handlePublish() async {
    final content = _contentController.text.trim();
    if (content.length < 10) {
      _toast('topiccontentlessinput10itemstext');
      return;
    }
    // not logged infirstlogin, loginsuccesscontinuepublish
    if (!BMAuthManager().isLoggedIn) {
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const BMLoginPage()),
      );
      if (ok != true) return;
    }
    setState(() => _isPublishing = true);
    final (ok, msg) = await _apiService.saveTopicPost(
      content: content,
      topics: _selectedTopics,
      matchId: _selectedMatch?.matchId,
      matchType: _selectedMatch?.categoryId,
    );
    if (!mounted) return;
    if (ok) {
      _toast('Posted');
      Navigator.pop(context, true);
      return;
    }
    setState(() => _isPublishing = false);
    _toast(msg);
  }

  /// SnackBar toast
  /// [message] - toasttext (String type)
  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return Container(
      color: BMColors.pitch950,
      child: Column(
        children: [
          _buildNavBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContentInput(),
                  const SizedBox(height: 14),
                  _buildMatchSection(),
                  const SizedBox(height: 14),
                  _buildTopicsSection(),
                ],
              ),
            ),
          ),
          _buildPublishBar(),
        ],
      ),
    );
  }

  /// topnavigation (returns + title)
  Widget _buildNavBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      decoration: BoxDecoration(
        color: BMColors.pitch950,
        border: Border(
          bottom: BorderSide(color: BMColors.pitch800, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 18,
              color: BMColors.textPrimary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const Expanded(
            child: Text(
              'post topic',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BMColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// No. 1 section: topiccontentinput field (darkstroke + cornertagcountcount)
  Widget _buildContentInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      decoration: BoxDecoration(
        color: BMColors.pitch900.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BMColors.pitch800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _contentController,
            maxLines: 6,
            maxLength: 500,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: BMColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'min of point, less input 10items text...',
              hintStyle: TextStyle(color: BMColors.textTertiary, fontSize: 13),
              border: InputBorder.none,
              counterText: '',
            ),
            onChanged: (_) {
              if (mounted) setState(() {});
            },
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _contentController,
            builder: (_, value, __) {
              return Text(
                '${value.text.length}/500',
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: BMColors.textTertiary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// No. 2 section: related match entry (unselected=inputcard / selected=match cardcanremove)
  Widget _buildMatchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // title row
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.sports_soccer, size: 14, color: BMColors.bright),
              const SizedBox(width: 5),
              const Text(
                'related match',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: BMColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: BMColors.pitch900,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: BMColors.pitch800),
                ),
                child: const Text(
                  '',
                  style: TextStyle(fontSize: 10, color: BMColors.textTertiary),
                ),
              ),
            ],
          ),
        ),
        // contentzone
        if (_selectedMatch == null) _buildMatchEntry() else _buildMatchCard(),
      ],
    );
  }

  /// not yetclosewhen of inputcard (left sidebright greenaddNo.circle + text, tapsearchpage)
  /// differentiation: referencepageasdashed lineborderwholecardcenter, this pageasleft alignedorderinput
  Widget _buildMatchEntry() {
    return GestureDetector(
      onTap: _pickMatch,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: BMColors.pitch900.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BMColors.bright.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: BMColors.bright.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: BMColors.bright.withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(Icons.add, size: 18, color: BMColors.bright),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Tap to select a match',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: BMColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'related match later topic show match card',
                    style: TextStyle(
                      fontSize: 11,
                      color: BMColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: BMColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  /// alreadyrelated match card (league name + home/away team logoteam namescore + rightupperremovebutton)
  Widget _buildMatchCard() {
    final m = _selectedMatch!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BMColors.pitch900.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BMColors.bright.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          // league name + removebutton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  m.competitionName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: BMColors.bright,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _removeMatch,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: BMColors.pitch800,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 13,
                    color: BMColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // home team + score + away team
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildTeamLogo(m.homeTeamLogo, 34),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        m.homeTeamName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: BMColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${m.homeTeamScore ?? 0} - ${m.awayTeamScore ?? 0}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    color: BMColors.bright,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        m.awayTeamName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: BMColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTeamLogo(m.awayTeamLogo, 34),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// No. 3 section: multi-selecttopicmenu (waitshow + refresh + multi-select chips)
  Widget _buildTopicsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BMColors.pitch900.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BMColors.pitch800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title row + refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'selecttopic',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: BMColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: _shuffleTopics,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: const [
                    Icon(Icons.refresh, size: 12, color: BMColors.bright),
                    SizedBox(width: 3),
                    Text(
                      'refresh',
                      style: TextStyle(fontSize: 11, color: BMColors.bright),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // multi-select chips (selected=bright greenstroke+text, unselected=text)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _topics.map((topic) {
              final selected = _selectedTopics.contains(topic);
              return GestureDetector(
                onTap: () => _toggleTopic(topic),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? BMColors.bright.withValues(alpha: 0.15)
                        : BMColors.pitch950.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected ? BMColors.bright : BMColors.pitch800,
                      width: selected ? 1.2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        const Icon(
                          Icons.check,
                          size: 11,
                          color: BMColors.bright,
                        ),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        topic,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? BMColors.bright
                              : BMColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// bottomfixedpublishitems (left sideselectedtopiccountcount + right sidepost button)
  /// differentiation: referencepage Post buttontopbar, this pageasbottomcommonbarlargebutton
  Widget _buildPublishBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: BMColors.pitch950,
        border: Border(top: BorderSide(color: BMColors.pitch800, width: 0.5)),
      ),
      child: Row(
        children: [
          // selectedtopiccountcount
          Text(
            'selectedtopic ${_selectedTopics.length}',
            style: const TextStyle(
              fontSize: 11,
              color: BMColors.textTertiary,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _isPublishing ? null : _handlePublish,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isPublishing
                      ? BMColors.bright.withValues(alpha: 0.4)
                      : BMColors.bright,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isPublishing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: BMColors.pitch950,
                        ),
                      )
                    : const Text(
                        'publish',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: BMColors.pitch950,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// team logo (dark circle background + network Logo + failurefallbackshield icon)
  /// [url] - Logo URL (String? type)
  /// [size] - size (double type)
  Widget _buildTeamLogo(String? url, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: BMColors.pitch800,
      ),
      child: ClipOval(
        child: (url != null && url.isNotEmpty)
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackIcon(size),
              )
            : _fallbackIcon(size),
      ),
    );
  }

  /// team logofallbackicon (shield)
  /// [size] - size (double type)
  Widget _fallbackIcon(double size) {
    return Icon(Icons.shield, size: size * 0.55, color: BMColors.textTertiary);
  }
}
