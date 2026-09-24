import 'package:flutter/material.dart';

import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';

/// BMApplyPlayerInfoPage - playerinfotablesinglepage
/// feature: inputplayerthisinfo + best league + best position + career historylater
/// architecture: MVVM Viewlayer (UItablesingle, logicplaceholder)
/// purposescope: from「my of 」page push enter of playerinfoinput
/// note: asbottomoverflow(overflow), buildBody outerunified SingleChildScrollView,
/// leagueselectzonemakeuse Wrap stylelayoutautoswapline, notmakeusefixed height ListView, correct overflow.
class BMApplyPlayerInfoPage extends BMBasePage {
 const BMApplyPlayerInfoPage({super.key});

 @override
 State<BMApplyPlayerInfoPage> createState() => _BMApplyPlayerInfoPageState();
}

class _BMApplyPlayerInfoPageState extends BMBasePageState<BMApplyPlayerInfoPage> {
 // ============ tablesinglestate ============

 /// nameinput fieldcontroller (TextEditingController type)
 final TextEditingController _nameController = TextEditingController();

 /// heightinput fieldcontroller (TextEditingController type, cm)
 final TextEditingController _heightController = TextEditingController();

 /// weightinput fieldcontroller (TextEditingController type, kg)
 final TextEditingController _weightController = TextEditingController();

 /// career historyinput fieldcontroller (TextEditingController type, moreline)
 final TextEditingController _experienceController = TextEditingController();

 /// genderselectindex (int type, 0=male, 1=female, 2=dense)
 int _genderIndex = 0;

 /// outputdate (DateTime? type, defaultunselected)
 DateTime? _birthday;

 /// selectedin of leagueindexmerge (Set<int> type, supportmulti-select, autodeduplicate)
 final Set<int> _selectedLeagueIndices = <int>{0};

 /// leagueselectwhetherexpand (bool type, true=show4line, false=collapseonly1line)
 bool _leagueExpanded = false;

 /// singlelineleaguechipzoneheightestimatecalcvalue (double type, includeslinespacing runSpacing)
 final double _oneLeagueRowHeight = 54;

 /// expandstatemaxdisplaylinecount (int type, byrequirement=4)
 final int _maxLeagueRows = 4;

 /// selectedin of courtupperpositionindexmerge (Set<int> type, supportmulti-select)
 final Set<int> _selectedPositionIndices = <int>{2};

 /// genderoption (List<(String, IconData)> type, and _genderIndex corresponding)
 final List<(String, IconData)> _genderOptions = const [
 ('male', Icons.male),
    ('female', Icons.female),
    ('dense', Icons.no_accounts_outlined),
 ];

 /// leagueoption Mock data (List<(String, String, IconData)> type, in//iconthreeelementgroup)
 /// description: 16 itemslet Wrap automoreline, tomorrownotwill overflow
 final List<(String, String, IconData)> _leagueOptions = const [
 ('Premier League', 'Premier League', Icons.sports_soccer),
    ('', 'La Liga', Icons.sports_soccer),
    ('', 'Serie A', Icons.sports_soccer),
    ('Bundesliga', 'Bundesliga', Icons.sports_soccer),
    ('', 'Ligue 1', Icons.sports_soccer),
    ('champion', 'Champions League', Icons.emoji_events),
    ('', 'Europa League', Icons.emoji_events_outlined),
    ('runner-upchampion', 'AFC Champions', Icons.public),
    ('in', 'CSL', Icons.flag),
    ('day', 'J1 League', Icons.circle),
    ('Kleague', 'K League 1', Icons.sports_soccer),
    ('', 'MLS', Icons.sports_soccer),
    ('NBA', 'NBA', Icons.sports_basketball),
    ('CBA', 'CBA', Icons.sports_basketball),
    ('EuroLeague', 'Euro Basketball', Icons.sports_basketball),
    ('WNBA', 'WNBA', Icons.sports_basketball),
 ];

 /// courtupperposition Mock data (List<(String, String)> type, in/text)
 final List<(String, String)> _positionOptions = const [
 ('will', 'GK'),
    ('left back', 'LB'),
    ('center back', 'CB'),
    ('right back', 'RB'),
    ('later', 'CDM'),
    ('defensive midfielder', 'CM'),
    ('first', 'CAM'),
    ('leftforward', 'LW'),
    ('right winger', 'RW'),
    ('inforward', 'ST'),
    ('wing back', 'PG'),
    ('getmcenter back', 'SG'),
    ('smallfirst forward', 'SF'),
    ('largefirst forward', 'PF'),
    ('inforward', 'C'),
 ];

 @override
 void dispose() {
 _nameController.dispose();
 _heightController.dispose();
 _weightController.dispose();
 _experienceController.dispose();
 super.dispose();
 }

 // ============ buildinput ============

 @override
 Widget buildBody(BuildContext context) {
 // outer SingleChildScrollView fallback: notmorelesstablesinglecontent + anysize,
 // notwilloutput bottom overflow, canonescrolltobottombutton.
 // quotaouteradd MediaQuery.viewInsets.bottom (oddspopheight) to padding bottom,
 // oddspopwhenas bottom overflow.
 final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
 return SingleChildScrollView(
 padding: EdgeInsets.fromLTRB(16, 8, 16, 120 + bottomInset),
 physics: const AlwaysScrollableScrollPhysics(),
 keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
 child: Column(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 _buildNavBar(context),
 const SizedBox(height: 16),
 _buildSectionTitle('thisinfo', Icons.person_outline),
          const SizedBox(height: 8),
          _buildBasicInfoCard(),
          const SizedBox(height: 16),
          _buildLeagueSectionTitle(),
          const SizedBox(height: 8),
          _buildLeagueSelectionWrap(),
          const SizedBox(height: 16),
          _buildSectionTitle('best position (canmulti-select)', Icons.filter_center_focus),
          const SizedBox(height: 8),
          _buildPositionSelectionWrap(),
          const SizedBox(height: 16),
          _buildSectionTitle('career history', Icons.menu_book_outlined),
 const SizedBox(height: 8),
 _buildExperienceCard(),
 const SizedBox(height: 24),
 _buildSubmitButton(),
 ],
),
);
 }

 // ============ topnavigation ============

 /// custom app bar (returns + centertitle)
 Widget _buildNavBar(BuildContext context) {
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
 onPressed: () => Navigator.of(context).pop(),
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
 'playerinfo',
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

 /// buildsectiontitle (left icon + text)
 Widget _buildSectionTitle(String title, IconData icon) {
 return Row(
 children: [
 Icon(icon, size: 14, color: BMColors.bright),
 const SizedBox(width: 6),
 Text(
 title,
 style: const TextStyle(
 fontSize: 13,
 fontWeight: FontWeight.w800,
 color: Color(0xFFE2E8F0),
),
),
 ],
);
 }

 /// leaguesectiondedicatedtitle (right side「expand/collapse」button, tapswitchcancollapsestate)
 Widget _buildLeagueSectionTitle() {
 return Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Row(
 children: const [
 Icon(Icons.emoji_events_outlined, size: 14, color: BMColors.bright),
 SizedBox(width: 6),
 Text(
 'best league (canmulti-select)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => setState(() => _leagueExpanded = !_leagueExpanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedRotation(
                  duration: const Duration(milliseconds: 220),
                  turns: _leagueExpanded ? 0.5 : 0,
                  curve: Curves.easeOut,
                  child: const Icon(Icons.expand_more, size: 17, color: BMColors.bright),
                ),
                const SizedBox(width: 3),
                Text(
                  _leagueExpanded ? 'collapse' : 'expand',
 style: const TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w700,
 color: BMColors.bright,
),
),
 ],
),
),
),
 ],
);
 }

 // ============ thisinfocard ============

 /// thisinfotablesinglecard (avatar + name + gender + birthday + heightweight)
 Widget _buildBasicInfoCard() {
 return Container(
 padding: const EdgeInsets.all(14),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
),
 child: Column(
 children: [
 _buildAvatarPicker(),
 const SizedBox(height: 14),
 _buildTextField(
 controller: _nameController,
 label: 'Real Name',
            hintText: 'inputplayerReal Name',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 12),
          _buildGenderSelector(),
          const SizedBox(height: 12),
          _buildBirthdayPicker(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _heightController,
                  label: 'height (cm)',
                  hintText: 'examplelike 185',
                  icon: Icons.height,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _weightController,
                  label: 'weight (kg)',
                  hintText: 'examplelike 78',
 icon: Icons.monitor_weight_outlined,
 keyboardType: TextInputType.number,
),
),
 ],
),
 ],
),
);
 }

 /// avatarselectwidget (circle + Tap to change avatarplaceholdercallback)
 Widget _buildAvatarPicker() {
 return GestureDetector(
 onTap: () {
 debugPrint('BMApplyPlayerInfoPage Tap to change avatar (placeholder)');
 },
 behavior: HitTestBehavior.opaque,
 child: Stack(
 alignment: Alignment.bottomRight,
 children: [
 Container(
 width: 76,
 height: 76,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 border: Border.all(color: BMColors.bright, width: 1.5),
 color: BMColors.pitch800,
),
 child: const Icon(Icons.person, size: 36, color: BMColors.bright),
),
 Container(
 width: 26,
 height: 26,
 decoration: BoxDecoration(
 color: BMColors.bright,
 shape: BoxShape.circle,
 border: Border.all(color: BMColors.pitch850, width: 2),
),
 child: const Icon(Icons.camera_alt, size: 13, color: BMColors.pitch950),
),
 ],
),
);
 }

 /// commoninput field (label + TextField + left icon + rightlowerstrokecontainer)
 Widget _buildTextField({
 required TextEditingController controller,
 required String label,
 required String hintText,
 required IconData icon,
 TextInputType? keyboardType,
 int? maxLines,
 }) {
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 label,
 style: const TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.w600,
 color: BMColors.textSecondary,
),
),
 const SizedBox(height: 6),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
 decoration: BoxDecoration(
 color: BMColors.pitch950.withValues(alpha: 0.6),
 borderRadius: BorderRadius.circular(10),
 border: Border.all(color: BMColors.pitch700),
),
 child: TextField(
 controller: controller,
 keyboardType: keyboardType,
 maxLines: maxLines ?? 1,
 style: const TextStyle(
 fontSize: 13,
 fontWeight: FontWeight.w600,
 color: BMColors.textPrimary,
),
 decoration: InputDecoration(
 border: InputBorder.none,
 hintText: hintText,
 hintStyle: const TextStyle(fontSize: 12, color: BMColors.textTertiary),
 icon: Icon(icon, size: 16, color: BMColors.bright),
 contentPadding: const EdgeInsets.symmetric(vertical: 10),
 isDense: true,
),
),
),
 ],
);
 }

 /// genderpicker (direction 3 items chip single)
 Widget _buildGenderSelector() {
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 const Text(
 'gender',
 style: TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.w600,
 color: BMColors.textSecondary,
),
),
 const SizedBox(height: 6),
 Row(
 children: _genderOptions.asMap().entries.map((e) {
 final idx = e.key;
 final item = e.value;
 final isSelected = _genderIndex == idx;
 return Expanded(
 child: Padding(
 padding: EdgeInsets.only(right: idx != _genderOptions.length - 1 ? 8: 0),
 child: GestureDetector(
 onTap: () => setState(() => _genderIndex = idx),
 behavior: HitTestBehavior.opaque,
 child: AnimatedContainer(
 duration: const Duration(milliseconds: 180),
 curve: Curves.easeOut,
 padding: const EdgeInsets.symmetric(vertical: 10),
 decoration: BoxDecoration(
 color: isSelected
 ? BMColors.bright.withValues(alpha: 0.15)
: BMColors.pitch950.withValues(alpha: 0.6),
 borderRadius: BorderRadius.circular(10),
 border: Border.all(
 color: isSelected ? BMColors.bright: BMColors.pitch700,
 width: isSelected ? 1.2: 0.6,
),
),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 item.$2,
 size: 14,
 color: isSelected ? BMColors.bright: BMColors.textTertiary,
),
 const SizedBox(width: 4),
 Text(
 item.$1,
 style: TextStyle(
 fontSize: 12,
 fontWeight: isSelected ? FontWeight.w700: FontWeight.w600,
 color: isSelected ? BMColors.bright: BMColors.textPrimary,
),
),
 ],
),
),
),
),
);
 }).toList(),
),
 ],
);
 }

 /// outputdateselect (left icon + rightselectedyearmonthday + tappop DatePicker)
 Widget _buildBirthdayPicker() {
 final display = _birthday == null
 ? 'Select date'
        : '${_birthday!.year.toString()}-'
            '${_birthday!.month.toString().padLeft(2, '0')}-'
            '${_birthday!.day.toString().padLeft(2, '0')}';
    final displayColor = _birthday == null ? BMColors.textTertiary : BMColors.textPrimary;
    return GestureDetector(
      onTap: _pickBirthday,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'outputdate',
 style: TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.w600,
 color: BMColors.textSecondary,
),
),
 const SizedBox(height: 6),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
 decoration: BoxDecoration(
 color: BMColors.pitch950.withValues(alpha: 0.6),
 borderRadius: BorderRadius.circular(10),
 border: Border.all(color: BMColors.pitch700),
),
 child: Row(
 children: [
 const Icon(Icons.calendar_month, size: 16, color: BMColors.bright),
 const SizedBox(width: 8),
 Expanded(
 child: Text(
 display,
 style: TextStyle(
 fontSize: 13,
 fontWeight: FontWeight.w600,
 color: displayColor,
),
),
),
 const Icon(Icons.chevron_right, size: 16, color: BMColors.textTertiary),
 ],
),
),
 ],
),
);
 }

 /// popsystemsystem DatePicker selectbirthday
 Future<void> _pickBirthday() async {
 final now = DateTime.now();
 final first = DateTime(now.year - 60);
 final last = DateTime(now.year - 10);
 final picked = await showDatePicker(
 context: context,
 initialDate: _birthday ?? DateTime(now.year - 25, 6, 1),
 firstDate: first,
 lastDate: last,
 locale: const Locale('zh', 'CN'),
 builder: (ctx, child) {
 return Theme(
 data: Theme.of(ctx).copyWith(
 colorScheme: ColorScheme.dark(
 primary: BMColors.bright,
 surface: BMColors.pitch900,
 onSurface: BMColors.textPrimary,
),
 dialogTheme: DialogThemeData(backgroundColor: BMColors.pitch950),
 datePickerTheme: DatePickerThemeData(
 backgroundColor: BMColors.pitch900,
 headerBackgroundColor: BMColors.pitch850,
 headerForegroundColor: BMColors.bright,
 dayForegroundColor: WidgetStateProperty.all(BMColors.textPrimary),
 todayForegroundColor: WidgetStateProperty.all(BMColors.bright),
 todayBackgroundColor: WidgetStateProperty.all(
 BMColors.bright.withValues(alpha: 0.2),
),
),
),
 child: child!,
);
 },
);
 if (picked != null && mounted) {
 setState(() => _birthday = picked);
 }
 }

 // ============ leagueselect (core: makeuseWrap, correctnotwillbottom overflow) ============

 /// best leaguemulti-selectlist
 /// description: momentmakeuse Wrap (notyesfixed heightListView, notyesRow, notyesColumn)
 /// Wrap willdatawidthautoswapline, eachoneline of elementcountadaptive,
 /// wholeheightbycontentexpand, outer SingleChildScrollView continuescrolltobottom.
 /// andleagueselectsamemodulestyle of alsohaslowerdirectionpositionselect, double bottom overflow.
 /// best leaguemulti-select (cancollapseUIcompletefullmergerequirement: default1line, expand=4line, 4linecanswipe)
 /// 1) default _leagueExpanded=false: AnimatedContainer maxHeight=_oneLeagueRowHeight (1line),
 /// physics=NeverScrollableScrollPhysics, redundantchipbyClip.antiAlias
 /// 2) taprightupperexpandbutton _leagueExpanded=true: maxHeight=4lineheight, physics=AlwaysScrollable,
 /// whenleaguechiptotal > 4linewhen, scrollviewallhasleague
 Widget _buildLeagueSelectionWrap() {
 final maxH = _leagueExpanded
 ? _oneLeagueRowHeight * _maxLeagueRows
: _oneLeagueRowHeight;
 return Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
),
 child: AnimatedContainer(
 duration: const Duration(milliseconds: 260),
 curve: Curves.easeInOutCubic,
 constraints: BoxConstraints(maxHeight: maxH),
 clipBehavior: Clip.antiAlias,
 decoration: BoxDecoration(borderRadius: BorderRadius.circular(2)),
 child: SingleChildScrollView(
 physics: _leagueExpanded
 ? const AlwaysScrollableScrollPhysics()
: const NeverScrollableScrollPhysics(),
 child: Wrap(
 spacing: 8,
 runSpacing: 8,
 alignment: WrapAlignment.start,
 crossAxisAlignment: WrapCrossAlignment.center,
 children: _leagueOptions.asMap().entries.map((entry) {
 final idx = entry.key;
 final lg = entry.value;
 final isSelected = _selectedLeagueIndices.contains(idx);
 return GestureDetector(
 onTap: () {
 setState(() {
 if (isSelected) {
 _selectedLeagueIndices.remove(idx);
 } else {
 _selectedLeagueIndices.add(idx);
 }
 });
 },
 behavior: HitTestBehavior.opaque,
 child: AnimatedContainer(
 duration: const Duration(milliseconds: 180),
 curve: Curves.easeOut,
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
 decoration: BoxDecoration(
 color: isSelected
 ? BMColors.bright.withValues(alpha: 0.15)
: BMColors.pitch900.withValues(alpha: 0.6),
 borderRadius: BorderRadius.circular(10),
 border: Border.all(
 color: isSelected
 ? BMColors.bright
: BMColors.pitch700.withValues(alpha: 0.6),
 width: isSelected ? 1.2: 0.6,
),
),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 lg.$3,
 size: 14,
 color: isSelected ? BMColors.bright: BMColors.textTertiary,
),
 const SizedBox(width: 6),
 Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 mainAxisSize: MainAxisSize.min,
 children: [
 Text(
 lg.$1,
 style: TextStyle(
 fontSize: 12,
 fontWeight: isSelected ? FontWeight.w700: FontWeight.w600,
 color: isSelected ? BMColors.bright: BMColors.textPrimary,
),
),
 Text(
 lg.$2,
 style: TextStyle(
 fontSize: 9,
 color: isSelected
 ? BMColors.bright.withValues(alpha: 0.75)
: BMColors.textTertiary,
),
),
 ],
),
 const SizedBox(width: 4),
 if (isSelected)
 const Icon(Icons.check_circle, size: 13, color: BMColors.bright),
 ],
),
),
);
 }).toList(),
),
),
),
);
 }

 // ============ positionselect (sameWrap) ============

 /// courtupperpositionmulti-select (Wrap adaptivemoreline, nonefixed height, notoverflow)
 Widget _buildPositionSelectionWrap() {
 return Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
),
 child: Wrap(
 spacing: 8,
 runSpacing: 8,
 children: _positionOptions.asMap().entries.map((entry) {
 final idx = entry.key;
 final pos = entry.value;
 final isSelected = _selectedPositionIndices.contains(idx);
 return GestureDetector(
 onTap: () {
 setState(() {
 if (isSelected) {
 _selectedPositionIndices.remove(idx);
 } else {
 _selectedPositionIndices.add(idx);
 }
 });
 },
 behavior: HitTestBehavior.opaque,
 child: AnimatedContainer(
 duration: const Duration(milliseconds: 180),
 curve: Curves.easeOut,
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
 constraints: const BoxConstraints(minWidth: 72),
 decoration: BoxDecoration(
 color: isSelected
 ? BMColors.accent.withValues(alpha: 0.18)
: BMColors.pitch900.withValues(alpha: 0.6),
 borderRadius: BorderRadius.circular(10),
 border: Border.all(
 color: isSelected ? BMColors.accent: BMColors.pitch700.withValues(alpha: 0.6),
 width: isSelected ? 1.2: 0.6,
),
),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 Text(
 pos.$1,
 textAlign: TextAlign.center,
 style: TextStyle(
 fontSize: 12,
 fontWeight: isSelected ? FontWeight.w700: FontWeight.w600,
 color: isSelected ? BMColors.accent: BMColors.textPrimary,
),
),
 const SizedBox(height: 2),
 Text(
 pos.$2,
 style: TextStyle(
 fontSize: 9,
 fontFamily: 'monospace',
 color: isSelected
 ? BMColors.accent.withValues(alpha: 0.8)
: BMColors.textTertiary,
),
),
 ],
),
),
);
 }).toList(),
),
);
 }

 // ============ career history & ============

 /// career historytextframe (moreline)
 Widget _buildExperienceCard() {
 return Container(
 padding: const EdgeInsets.all(14),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
),
 child: _buildTextField(
 controller: _experienceController,
 label: 'career history / getcase / allpart',
        hintText: 'examplee.g.: 2018-2022 specialyearteam; 2022 fullU23tagmatchchampion...',
 icon: Icons.edit_note,
 maxLines: 5,
),
);
 }

 /// bottombutton (disabledstate / loadingin)
 Widget _buildSubmitButton() {
 return GestureDetector(
 onTap: _submitForm,
 behavior: HitTestBehavior.opaque,
 child: Container(
 width: double.infinity,
 padding: const EdgeInsets.symmetric(vertical: 14),
 decoration: BoxDecoration(
 gradient: const LinearGradient(
 colors: [BMColors.accent, Color(0xFF2DD4BF)],
),
 borderRadius: BorderRadius.circular(14),
 boxShadow: [
 BoxShadow(
 color: BMColors.accent.withValues(alpha: 0.25),
 blurRadius: 20,
 offset: const Offset(0, 8),
),
 ],
),
 child: const Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(Icons.send_and_archive, size: 15, color: BMColors.pitch950),
 SizedBox(width: 6),
 Text(
 'playerinfo',
 style: TextStyle(
 fontSize: 14,
 fontWeight: FontWeight.w900,
 color: BMColors.pitch950,
),
),
 ],
),
),
);
 }

 /// tablesingle (placeholderlogic: debugPrint, withlaterswapastrueactualPOSTAPI)
 Future<void> _submitForm() async {
 final name = _nameController.text.trim();
 final height = _heightController.text.trim();
 final weight = _weightController.text.trim();
 final experience = _experienceController.text.trim();
 debugPrint('====================================');
    debugPrint('📝 BMApplyPlayerInfoPage player');
    debugPrint(' name=$name');
    debugPrint(' gender=${_genderOptions[_genderIndex].$1}');
    debugPrint(' birthday=${_birthday?.toIso8601String() ?? "not yetselect"}');
    debugPrint(' height=${height.isEmpty ? "not filled": "$height cm"}');
    debugPrint(' weight=${weight.isEmpty ? "not filled": "$weight kg"}');
    debugPrint(' best league=${_selectedLeagueIndices.map((i) => _leagueOptions[i].$1).join(",")}');
    debugPrint(' best position=${_selectedPositionIndices.map((i) => _positionOptions[i].$1).join(",")}');
    debugPrint(' career history=${experience.isEmpty ? "not filled": experience.length}text');
    debugPrint('====================================');
  }
}
