import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';

/// split classesenum (BM differentiation: compare hanklive searchlist, addadd6largescenariosplit classes)
enum _BMDictCategory {
 interview('body', Icons.mic_external_on_outlined, Color(0xFF3B82F6)),
  lockroom('', Icons.group_outlined, Color(0xFF22C55E)),
  referee('common', Icons.gavel_outlined, Color(0xFFF59E0B)),
  press('match start XI', Icons.flag_outlined, Color(0xFFEF4444)),
  postmatch('match end', Icons.task_alt_outlined, Color(0xFFA855F7)),
  skill('', Icons.smart_toy_outlined, Color(0xFF14B8A6));

 /// split classesdisplayname
 final String label;

 /// split classesicon
 final IconData icon;

 /// split classesaccent color
 final Color color;
 const _BMDictCategory(this.label, this.icon, this.color);
}

/// singlemodel (singletextfileinner, innermakeusage)
class _BMDictTerm {
 /// split classes (_BMDictCategory type)
 final _BMDictCategory category;

 /// title (String type, bolddisplay)
 final String title;

 /// centertext (String type, Copycontent)
 final String content;

 /// makeusescenariotoast (String? type, emptythennotdisplay)
 final String? scenario;

 const _BMDictTerm({
 required this.category,
 required this.title,
 required this.content,
 this.scenario,
 });
}

/// Mock data (BM differentiation: by6classgroup, correctfootbasketballcoach/teamlength/playertrueactualscenario)
const List<_BMDictTerm> _kAllTerms = [
 // ---------- body ----------
 _BMDictTerm(
 category: _BMDictCategory.interview,
 title: 'second-half degree tag back',
    content: 'today of resultnotyesmy of ，myheavyopponent of table。backafterwillrepeatoddseachonesection，fromgrouptofirstcourtfinalendeffectratehasempty。fans of support，loweronecourtmywillwithvolume of statedegreeplanecorrect。',
    scenario: 'team goal then by body',
  ),
  _BMDictTerm(
    category: _BMDictCategory.interview,
    title: 'about conversion pass center plane back should',
    content: 'mynowonlydedicatedcurrentpartandcountryteam of eachonecourtmatch，mergesameineachoneminutemywillfullpowerwith。future of topeopleandpartcommon，nownotdoanytest。',
    scenario: 'by one and convert',
  ),
  _BMDictTerm(
    category: _BMDictCategory.interview,
    title: 'MVP get',
    content: 'itemsitemwholeitemsteam。nohasteameachonecourt of 、coachgroupeachonetime of tacticaladjust、dopeoplemember of output，mynotcanability。yescorrectmywholeteampastonesectiontimepower of ，lowercontinuefirst。',
    scenario: 'singlecourt/monthdegreeget',
),
 // ---------- ----------
 _BMDictTerm(
 category: _BMDictCategory.lockroom,
 title: 'halfcourtlater 1 ball',
    content: 'header！nowonlyyeslateroneball，notyesinputwholecourt。upperhalfcourtmy of ballandwillnotdiff，lateronelower of handleagainonepoint。sidepeoplepeople，sidemoreempty。lowerhalfcourt 15 minuteinnerfirsttakescoreback，donotdogetto？',
    scenario: 'halfcourt 0-1 enter',
  ),
  _BMDictTerm(
    category: _BMDictCategory.lockroom,
    title: 'teamlengthpointnamecoreplayer（and）',
    content: 'mytodayneedpointoutputissue——myconvert of sectionslow。doasincourtballpoint，eachonetimebycorrectdirectiontolater。yescore，largeview，lowergetoutput of section，abilitydoto。',
    scenario: 'halfcourtadjust，coremore',
  ),
  _BMDictTerm(
    category: _BMDictCategory.lockroom,
    title: 'endNo.',
    content: 'mynotyestenoneprofile，myyesonewhole。haspeopleballhaspeoplepatch，haspeoplehaspeopletop，notoneprofile。lowermyoneupper，onelower，？',
    scenario: 'key match first XI',
),
 // ---------- common ----------
 _BMDictTerm(
 category: _BMDictCategory.referee,
 title: 'offside（）',
    content: 'first，mynonheavy of ，yesonetimebackviewonelower of when。our sidefirst forwardlaunchinstantdirectionlateronenamelaterguardtomorrowshowlaterplane，abilityandedgeagaincommonconfirm？',
    scenario: 'goalbyoffside，needs',
  ),
  _BMDictTerm(
    category: _BMDictCategory.referee,
    title: 'yellow cardwarningdegreeone',
    content: 'first，upperhalfcourtcorrectdirection 10 No.samedomyteamlengthalreadytoyellow card，onetimesamekind of foullikeresultdegreenotonewillimpactmatchsection。keeptagunified，。',
    scenario: 'doubledirectiondegreenotonewhenandNo. fourmembercommon',
  ),
  _BMDictTerm(
    category: _BMDictCategory.referee,
    title: 'penalty',
    content: 'first，correctdirectionlaterguardforbiddenzoneinnerupperhastomorrowshowdo，our sideplayersectionbycompletefullbadfirst。common VAR againconfirmonetimeitems，。',
    scenario: 'no penalty inside the box',
),
 // ---------- match start XI ----------
 _BMDictTerm(
 category: _BMDictCategory.press,
 title: 'ratiolargematchfirst 5 minutemember',
    content: 'today，nohasoneprofilecanwithsayown 100% backupgood，mytodayneed of notyesabilitypower，yes。eachone 50-50 ballneedratiocorrectdirectionfasthalf，eachonetimeheaderballneedratiocorrectdirectionheighthalf。asallhasnightsupportmy of fans，lower 90 minute！',
    scenario: 'ratio/matchmatchfirstplayercommoninner',
  ),
  _BMDictTerm(
    category: _BMDictCategory.press,
    title: 'teammatch start XI',
    content: 'todayouterboundarynohaspeopleviewgoodmy，footballyes of 。correctdirectionactualpowermyupper，todaypowerratiomylargegetmore——myeachball of state，allhaspeoplebacktothisdirection 30 。，will。',
    scenario: 'match ability tomorrow show opponent',
),
 // ---------- match end ----------
 _BMDictTerm(
 category: _BMDictCategory.postmatch,
 title: 'ball not full repeat odds',
    content: 'todaythreeminto，myneed：lowerhalfcourtlater 20 minutemy of notepowertomorrowshowlower。likeresultopponentfirsttakeagaingoodonepoint，today of resultcompletefullcanabilitynotonekind。backlatereachoneprofileviewown of view，weekthreefirstprofileend。',
    scenario: 'ball state not match end',
  ),
  _BMDictTerm(
    category: _BMDictCategory.postmatch,
    title: 'penalty large full team',
    content: 'penaltyinputnotyestoday of issue，yes。past 120 minutemyeachoneprofiletakeown，nohaspeoplehasgridmy。header，todaymydirectionallhaspeopletomorrowmyabilityandanyteamtolateronesecond。loweronecourtagain！',
    scenario: 'cup penalty',
),
 // ---------- ----------
 _BMDictTerm(
 category: _BMDictCategory.skill,
 title: 'Tiki-Taka ',
    content: 'Tiki-Taka：correctcontinuefastpassball of 。commondistanceleaveplanepass + fullmemberswappositionmakesection，corewantyesuseball，tableteamaswhenandcountryteam。',
    scenario: 'tactical / say',
  ),
  _BMDictTerm(
    category: _BMDictCategory.skill,
    title: 'Gegenpress ',
    content: 'Gegenpress（generalstyleheightposition）：balllater 5 secondinner，near 3~4 nameplayerimmediatelyfrommultipledirectioncorrectdirectionNo. oneoutputballpoint，backballlatergroup。correctbodyabilityneedheight，yesstylefootball of coretactical。',
    scenario: 'tactical / coach',
  ),
  _BMDictTerm(
    category: _BMDictCategory.skill,
    title: 'False 9 nineNo.',
    content: 'False 9（nineNo.）：tableplaneinforwardposition，actualbacktolaterzoneball、stringincourt，outputcorrectdirectioninguardmakemakeheightlateremptywhentoedgeforwardinneruse。tableplayer：、。',
    scenario: 'tactical / order',
  ),
  _BMDictTerm(
    category: _BMDictCategory.skill,
    title: 'xG goal',
    content: 'xG（Expected Goals）：position、cornerdegree、peopledistanceleave、willpositionwaitcounttenitemsdegreecompute of 0~1 goalprobability。singlecourt xG heightgoallessdescriptionwillmorefinalenddiff，xG goalmoretabletakewillabilitypowerorgood。',
    scenario: 'dataanalysis / matchlaterrepeatodds',
),
];

/// BMDictionaryPage: Verbal Trick Dictionary dictionarypage
/// differentiated design (compare hanklive search+cancollapsecard):
/// 1. dark green BallMatrix theme
/// 2. left sidesplit classesnavigation（6 largescenariosplit classes，tapfastswitch）+ right sidecard
/// 3. eachcardbottom-right corner「Copy」button（tap copy toclipboard + SnackBar toast）
/// 4. topkeepsearchbar（supporttitle+centertextfullfieldmodule）
/// architecture: one class per file, extends BMBasePage
class BMDictionaryPage extends BMBasePage {
 const BMDictionaryPage({super.key});

 @override
 State<BMDictionaryPage> createState() => _BMDictionaryPageState();
}

class _BMDictionaryPageState extends BMBasePageState<BMDictionaryPage> {
 /// search keyword (String type)
 String _keyword = '';

 /// currentselectedsplit classes (_BMDictCategory? type, null=displayall)
 _BMDictCategory? _current = null;

 /// search input fieldcontroller
 final _searchCtrl = TextEditingController();

 @override
 void dispose() {
 _searchCtrl.dispose();
 super.dispose();
 }

 List<_BMDictTerm> get _filtered {
 var list = _current == null ? _kAllTerms: _kAllTerms.where((e) => e.category == _current).toList();
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
        content: Text('✅ Copied to clipboard', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
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
                  hintText: 'searchtitle / content / scenario...',
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
      ('all', null, Icons.all_inbox_outlined, BMColors.bright),
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
            Text('No ', style: TextStyle(color: BMColors.textSecondary, fontSize: 12)),
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
                              Text('scenario：${t.scenario!}', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9, fontWeight: FontWeight.w600)),
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
                        Text('Copy', style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.w800)),
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
