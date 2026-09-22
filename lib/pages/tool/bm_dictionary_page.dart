import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';

/// 话术分类枚举 (BM 差异化: 对比 hanklive 纯搜索列表, 增加6大场景分类)
enum _BMDictCategory {
  interview('媒体采访', Icons.mic_external_on_outlined, Color(0xFF3B82F6)),
  lockroom('更衣室', Icons.group_outlined, Color(0xFF22C55E)),
  referee('裁判沟通', Icons.gavel_outlined, Color(0xFFF59E0B)),
  press('赛前动员', Icons.flag_outlined, Color(0xFFEF4444)),
  postmatch('赛后总结', Icons.task_alt_outlined, Color(0xFFA855F7)),
  skill('技巧术语', Icons.smart_toy_outlined, Color(0xFF14B8A6));

  /// 分类显示名
  final String label;

  /// 分类图标
  final IconData icon;

  /// 分类主题色
  final Color color;
  const _BMDictCategory(this.label, this.icon, this.color);
}

/// 单条话术模型 (单文件内定义, 内聚使用)
class _BMDictTerm {
  /// 分类 (_BMDictCategory 类型)
  final _BMDictCategory category;

  /// 标题 (String 类型, 粗体显示)
  final String title;

  /// 正文话术 (String 类型, 一键复制内容)
  final String content;

  /// 使用场景提示 (String? 类型, 空则不显示)
  final String? scenario;

  const _BMDictTerm({
    required this.category,
    required this.title,
    required this.content,
    this.scenario,
  });
}

/// Mock 话术数据 (BM 差异化: 按6类组织, 针对足篮球教练/队长/球员真实场景)
const List<_BMDictTerm> _kAllTerms = [
  // ---------- 媒体采访 ----------
  _BMDictTerm(
    category: _BMDictCategory.interview,
    title: '失利后保持风度标准回答',
    content: '今天的结果不是我们预期的，我们尊重对手的表现。回去之后会复盘每一个细节，从防守组织到前场终结效率都有提升空间。感谢球迷的支持，下一场我们会以更积极的态度面对。',
    scenario: '球队输球后被媒体围堵',
  ),
  _BMDictTerm(
    category: _BMDictCategory.interview,
    title: '关于转会传闻正面回应',
    content: '我现在只专注于当前俱乐部和国家队的每一场比赛，合同期内的每一分钟我都会全力以赴。未来的事情交给经纪人和俱乐部沟通，现在不做任何推测。',
    scenario: '被记者问及转会绯闻',
  ),
  _BMDictTerm(
    category: _BMDictCategory.interview,
    title: 'MVP 获奖感言',
    content: '这个奖项属于整个团队。没有队友每一场的拼抢、教练组每一次的战术调整、工作人员默默的付出，我不可能站在这里。这是对我们整支球队过去一段时间努力的肯定，接下来继续前进。',
    scenario: '单场/月度最佳获奖采访',
  ),
  // ---------- 更衣室 ----------
  _BMDictTerm(
    category: _BMDictCategory.lockroom,
    title: '半场落后 1 球打气',
    content: '兄弟们抬起头来！现在只是落后一个球，不是输了整场。上半场我们的控球和机会都不差，最后一下的处理再冷静一点。防守端人盯人跟紧，进攻端多倒脚拉扯空间。下半场 15 分钟之内先把比分扳回来，做不做得到？',
    scenario: '半场 0-1 进入更衣室',
  ),
  _BMDictTerm(
    category: _BMDictCategory.lockroom,
    title: '队长点名批评核心球员（温和版）',
    content: '我今天要直接点出问题——我们攻防转换的节奏慢了。作为中场持球点，每一次被对方反抢都给后防挖坑。你是核心，大家看着你，接下来拿出你训练里的节奏，你能做到。',
    scenario: '更衣室半场调整，核心失误多',
  ),
  _BMDictTerm(
    category: _BMDictCategory.lockroom,
    title: '更衣室团结口号',
    content: '我们不是十一个人在踢，我们是一个整体。有人丢球有人补，有人抽筋有人顶，谁都不准一个人扛。接下来我们一起上，一起下，懂？',
    scenario: '关键比赛前最后动员',
  ),
  // ---------- 裁判沟通 ----------
  _BMDictTerm(
    category: _BMDictCategory.referee,
    title: '抗议越位误判（冷静版）',
    content: '裁判先生，我们非常尊重您的判罚，但是这一次请您回看一下助理裁判的举旗时机。我方前锋启动瞬间防守方最后一名后卫明显拖在后面，能否请您和边裁再沟通确认？',
    scenario: '进球被判越位，需要申诉',
  ),
  _BMDictTerm(
    category: _BMDictCategory.referee,
    title: '申请黄牌警告尺度一致',
    content: '先生，上半场对方 10 号相同动作我们队长已经吃到了黄牌，这一次同样的犯规如果尺度不一致会影响比赛节奏。请您保持判罚标准统一，谢谢。',
    scenario: '双方尺度不一致时和第四官员沟通',
  ),
  _BMDictTerm(
    category: _BMDictCategory.referee,
    title: '点球申诉冷静话术',
    content: '裁判先生，对方后卫在禁区内手上有明显拉拽动作，我方球员在射门节奏被完全破坏前才摔倒。请您考虑通过 VAR 再确认一次这个接触，谢谢。',
    scenario: '禁区内接触没吹点球',
  ),
  // ---------- 赛前动员 ----------
  _BMDictTerm(
    category: _BMDictCategory.press,
    title: '德比大战赛前 5 分钟动员',
    content: '今天站在这里，没有一个人可以说自己 100% 准备好，但我们今天要赢的不是能力，是意志。每一个 50-50 球要比对方快半米，每一次头球要比对方高半厘米。为了所有熬夜支持我们的球迷，拼下这 90 分钟！',
    scenario: '德比/决赛赛前球员通道内',
  ),
  _BMDictTerm(
    category: _BMDictCategory.press,
    title: '弱队逆袭赛前动员',
    content: '今天外界没有人看好我们，但足球是圆的。对方实力在我们之上，但他们今天压力比我们大得多——我们就抱着每球必争的心态打反击，所有人回防到本方 30 米。他们慌了，机会就来了。',
    scenario: '赛前实力明显弱于对手',
  ),
  // ---------- 赛后总结 ----------
  _BMDictTerm(
    category: _BMDictCategory.postmatch,
    title: '赢球但过程不满意复盘',
    content: '虽然今天三分到手，但我要强调：下半场最后 20 分钟我们的注意力明显下滑。如果对手门前把握再好一点，今天的结果完全可能不一样。回去后每一个人看自己的防守失误视频，周三训练前提交个人总结。',
    scenario: '赢球但状态不佳赛后',
  ),
  _BMDictTerm(
    category: _BMDictCategory.postmatch,
    title: '点球大战失利安慰全队',
    content: '点球输不是今天的问题，是运气。过去 120 分钟我们每一个人都把自己榨干了，没有人有资格指责我们。抬起头来，今天我们向所有人证明了我们能和任何球队战斗到最后一秒。下一场再战！',
    scenario: '杯赛点球被淘汰',
  ),
  // ---------- 技巧术语 ----------
  _BMDictTerm(
    category: _BMDictCategory.skill,
    title: 'Tiki-Taka 解释',
    content: 'Tiki-Taka：源自西班牙语对连续快速传球的拟声。通过短距离地面传递 + 全员跑动换位控制节奏，核心思想是用控球代替防守，代表球队为巅峰时期巴萨与西班牙国家队。',
    scenario: '战术讲解 / 解说术语',
  ),
  _BMDictTerm(
    category: _BMDictCategory.skill,
    title: 'Gegenpress 反抢解释',
    content: 'Gegenpress（克洛普式高位反抢）：丢球后 5 秒内，就近 3~4 名球员立刻从多个方向围堵对方第一出球点，夺回球权后就地组织反击。对体能要求极高，是现代压迫式足球的核心战术。',
    scenario: '战术讲解 / 教练术语',
  ),
  _BMDictTerm(
    category: _BMDictCategory.skill,
    title: 'False 9 伪九号解释',
    content: 'False 9（伪九号）：表面站中锋位置，实际频繁回撤到后腰区域接球、串联中场，拉出对方中卫制造身后空当给边锋内切利用。代表球员：梅西、菲尔米诺。',
    scenario: '战术板讲解 / 排兵布阵',
  ),
  _BMDictTerm(
    category: _BMDictCategory.skill,
    title: 'xG 预期进球解释',
    content: 'xG（Expected Goals）：基于射门位置、角度、防守人距离、门将位置等数十个维度计算的 0~1 进球概率。单场 xG 高但进球少说明机会多但终结差，xG 低但进球多代表把握机会能力强或运气好。',
    scenario: '数据分析 / 赛后复盘',
  ),
];

/// BMDictionaryPage: Verbal Trick Dictionary 话术词典页
/// 差异化设计 (对比 hanklive 纯搜索+可折叠卡片):
/// 1. 深绿 BallMatrix 主题
/// 2. 左侧分类导航（6 大场景分类，点击快速切换）+ 右侧话术卡片
/// 3. 每张卡片右下角「一键复制」按钮（点击直接 copy 话术到剪贴板 + SnackBar 提示）
/// 4. 顶部保留搜索栏（支持标题+正文全字段模糊匹配）
/// 架构: 单类单文件, 继承 BMBasePage
class BMDictionaryPage extends BMBasePage {
  const BMDictionaryPage({super.key});

  @override
  State<BMDictionaryPage> createState() => _BMDictionaryPageState();
}

class _BMDictionaryPageState extends BMBasePageState<BMDictionaryPage> {
  /// 搜索关键字 (String 类型)
  String _keyword = '';

  /// 当前选中分类 (_BMDictCategory? 类型, null=显示全部)
  _BMDictCategory? _current = null;

  /// 搜索输入框控制器
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_BMDictTerm> get _filtered {
    var list = _current == null ? _kAllTerms : _kAllTerms.where((e) => e.category == _current).toList();
    if (_keyword.trim().isNotEmpty) {
      final kw = _keyword.trim().toLowerCase();
      list = list.where((e) =>
          e.title.toLowerCase().contains(kw) ||
          e.content.toLowerCase().contains(kw) ||
          (e.scenario ?? '').toLowerCase().contains(kw)).toList();
    }
    return list;
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ 话术已复制到剪贴板', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        backgroundColor: Color(0xFF14532D),
        duration: Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return Scaffold(
      backgroundColor: BMColors.pitch900,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearch(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLeftNav(),
                Expanded(child: _buildRightList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: BMColors.pitch950,
      elevation: 0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: BMColors.pitch850,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
          ),
          child: const Icon(Icons.chevron_left, color: Colors.white, size: 18),
        ),
      ),
      title: const Text(
        'Verbal Trick Dictionary',
        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      color: BMColors.pitch950,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: BMColors.pitch850,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 14, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _keyword = v),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  hintText: '搜索话术标题 / 内容 / 场景...',
                  hintStyle: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_keyword.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _keyword = '');
                },
                child: const Icon(Icons.close, size: 14, color: Color(0xFF9CA3AF)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftNav() {
    final items = <(String, _BMDictCategory?, IconData, Color)>[
      ('全部', null, Icons.all_inbox_outlined, BMColors.bright),
      ..._BMDictCategory.values.map((c) => (c.label, c, c.icon, c.color)),
    ];
    return Container(
      width: 94,
      color: BMColors.pitch950,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (_, i) {
          final (lb, cat, ic, col) = items[i];
          final active = (cat == null && _current == null) || (cat != null && cat == _current);
          return GestureDetector(
            onTap: () => setState(() => _current = cat),
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: active ? col.withValues(alpha: 0.14) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: active ? Border.all(color: col.withValues(alpha: 0.4), width: 1.0) : null,
              ),
              child: Column(
                children: [
                  Icon(ic, size: 16, color: active ? col : BMColors.textSecondary),
                  const SizedBox(height: 4),
                  Text(
                    lb,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: active ? Colors.white : BMColors.textSecondary,
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRightList() {
    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 44, color: BMColors.textTertiary),
            const SizedBox(height: 8),
            Text('暂无匹配话术', style: TextStyle(color: BMColors.textSecondary, fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildCard(list[i]),
    );
  }

  Widget _buildCard(_BMDictTerm t) {
    final col = t.category.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: BMColors.pitch850,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: col.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
                  child: Icon(t.category.icon, size: 14, color: col),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        t.category.label,
                        style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                      if (t.scenario != null && t.scenario!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: BMColors.pitch950.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.place_outlined, size: 9, color: Color(0xFF9CA3AF)),
                              const SizedBox(width: 3),
                              Text('场景：${t.scenario!}', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: BMColors.pitch950.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: col.withValues(alpha: 0.25), width: 0.8),
              ),
              child: Text(
                t.content,
                style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 12, height: 1.6),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _copy(t.content),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: col.withValues(alpha: 0.14),
                      border: Border.all(color: col.withValues(alpha: 0.5), width: 1.0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_all_outlined, size: 11, color: col),
                        const SizedBox(width: 4),
                        Text('一键复制', style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.w800)),
                      ],
                    ),
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
