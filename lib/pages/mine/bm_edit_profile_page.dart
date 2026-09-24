import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../utils/bm_auth_manager.dart';
import '../../models/bm_user_model.dart';

/// BMEditProfilePage - edituserinfopage
/// feature: modifyavatar(tapswap+nickname+itemssign，savelaterbackwrite BMAuthManager.currentUser memory+SharedPreferences
/// differentiation: dark greentheme，toppillsavebutton(andtopicpageone，input field pitch850 dark greenbottom，nickname48pxheight，sign 6 lineheight
/// architecture: one class per file，extends BMBasePage
class BMEditProfilePage extends BMBasePage {
 const BMEditProfilePage({super.key});

 @override
 State<BMEditProfilePage> createState() => _BMEditProfilePageState();
}

class _BMEditProfilePageState extends BMBasePageState<BMEditProfilePage> {
 /// nicknameinputcontroller (TextEditingController type)
 late final TextEditingController _nickCtrl;

 /// itemssigninputcontroller (TextEditingController type)
 late final TextEditingController _signCtrl;

 /// originalhassideavatarURL (String? type, forcompareuserwhethermodifyavatar)
 String? _originAvatarUrl;

 /// newselected of localavatartextfilepath (String? type, userfromlocalphoto librarylatervalue File(XFile).path)
 String? _localAvatarPath;

 /// whethersavein (bool type, duplicatetap)
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

 /// save: 1. toast toast「success, wait」 2. backwrite BMAuthManager memory+ 3. delaylogoutcurrent page
 /// : avataruploadtrueactual OSS/latersideAPIlatercontinueinput, firsttakelocalpathstoremodelwait
 Future<void> _handleSave() async {
 if (_saving) return;
 final nick = _nickCtrl.text.trim();
 if (nick.isEmpty) {
 _snack('Nickname cannot be empty');
 return;
 }
 setState(() => _saving = true);
 try {
 // firstupdate BMAuthManager (nickname/sign/newavatarpath)
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
 // ⭐️ requirement1: toast toast「success，wait」
 _snack('success，wait');
 // ⭐️ requirement2: delay 800ms letuserviewto toast → againlogoutcurrent page, returns true letprofileinrefresh
 await Future.delayed(const Duration(milliseconds: 800));
 if (!mounted) return;
 Navigator.of(context).pop(true);
 } catch (_) {
 if (mounted) _snack('failure, please retry');
 } finally {
 if (mounted) setState(() => _saving = false);
 }
 }

 /// calllocalphoto libraryavatar (image_picker: ImageSource.gallery)
 /// nonepermission/userTake effect/exception: nottoastor toast singletoast
 Future<void> _pickGalleryAvatar() async {
 try {
 final XFile? picked = await ImagePicker().pickImage(
 source: ImageSource.gallery,
 imageQuality: 80,
 maxWidth: 512,
 maxHeight: 512,
);
 if (picked == null) {
 // userpointTake effectnottoast
 return;
 }
 if (!mounted) return;
 setState(() => _localAvatarPath = picked.path);
 _snack('Avatar selected');
    } catch (e) {
      if (!mounted) return;
      _snack('openphoto libraryfailure, checkpermission');
 }
 }

 /// SnackBar unified toast
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

 /// topapp bar：left sidereturns + middletitle + right sidepillsavebutton
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
 'editprofile',
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
                        'save',
                        style: TextStyle(color: BMColors.bright, fontSize: 12, fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// avatarmodify：tapopenlocalphoto library (image_picker ImageSource.gallery)
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
            'Tap to change avatar',
 style: TextStyle(color: BMColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
),
 ],
),
);
 }

 /// avatarimagerender: localpriority > sidenetworkimage > placeholdericon
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

 /// nicknameinput field
 Widget _buildNickField() {
 return _fieldBox(
 label: 'nickname',
      child: TextField(
        controller: _nickCtrl,
        maxLength: 16,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          counterText: '',
          hintText: 'Enter nickname',
 hintStyle: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
 contentPadding: EdgeInsets.symmetric(vertical: 14),
),
),
);
 }

 /// itemssigninput field
 Widget _buildSignField() {
 return _fieldBox(
 label: 'itemssign',
      child: TextField(
        controller: _signCtrl,
        maxLines: 4,
        maxLength: 80,
        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          counterStyle: TextStyle(color: Color(0xFF6B7280), fontSize: 10),
          hintText: 'onelowerown (more80text)',
 hintStyle: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
 contentPadding: EdgeInsets.symmetric(vertical: 12),
),
),
);
 }

 /// commoninput fieldcontainer
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
