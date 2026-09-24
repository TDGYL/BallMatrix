import 'package:flutter/material.dart';

import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../viewmodels/home/bm_home_view_model.dart'
    show BMHomeViewModel, BMSportType;
import '../../services/bm_community_api_service.dart';
import '../../models/bm_match_model.dart';
import '../../models/bm_news_model.dart';
import '../../models/bm_topic_model.dart';
import '../../widgets/home/bm_home_header.dart';
import '../../widgets/home/bm_sport_switcher.dart';
import '../../widgets/home/bm_match_spotlight_card.dart';
import '../../widgets/home/bm_hot_news_section.dart';
import '../../widgets/home/bm_hot_topics_section.dart';
import '../match/matchList.dart';
import '../match/bm_football_detail_page.dart';
import '../match/bm_basketball_detail_page.dart';
import '../news/newsList.dart';
import '../news/bm_news_detail_page.dart';
import '../community/topicList.dart';
import '../community/bm_topic_detail_page.dart';
import '../login/bm_login_page.dart';
import '../../utils/bm_auth_manager.dart';
import 'bm_home_search_page.dart';

/// BMHomePage - home
/// feature: showfocus competition、hot news、hot topic
/// architecture: MVVM Viewlayer, bind BMHomeViewModel
/// modifypoint1: focus competitioncardheaderadd View All button, navigatecompetitionlistpage
/// modifypoint2: abilitytoolbox → hot news (Bannerlist, onepage1.5items)
/// modifypoint3: todaydayheavypointleavemodel → hot topic
class BMHomePage extends BMBasePage {
 /// homeViewModel (BMHomeViewModel type, bypagepassinput)
 final BMHomeViewModel viewModel;

 const BMHomePage({super.key, required this.viewModel});

 @override
 State<BMHomePage> createState() => _BMHomePageState();
}

class _BMHomePageState extends BMBasePageState<BMHomePage> {
 @override
 void initState() {
 super.initState();
 // lazy load: first timeenterwhenloadingdata
 widget.viewModel.loadData();
 }

 @override
 Widget buildBody(BuildContext context) {
 return ListenableBuilder(
 listenable: widget.viewModel,
 builder: (context, child) {
 return RefreshIndicator(
 color: BMColors.bright,
 backgroundColor: BMColors.pitch850,
 onRefresh: () => widget.viewModel.refreshData(),
 child: SingleChildScrollView(
 physics: const AlwaysScrollableScrollPhysics(),
 padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 BMHomeHeader(onSearchTap: _onSearchTap),
 const SizedBox(height: 20),
 BMSportSwitcher(
 currentSport: widget.viewModel.currentSport,
 onSportChanged: (sport) =>
 widget.viewModel.switchSport(sport),
),
 const SizedBox(height: 20),
 _buildFeaturedMatchSection(),
 const SizedBox(height: 20),
 _buildHotNewsSection(),
 const SizedBox(height: 20),
 _buildHotTopicsSection(),
 ],
),
),
);
 },
);
 }

 /// buildfocus competitionzone (No. onesection)
 /// zoneheaderincludestitleand"view all"button, tap to navigatecompetitionlistpage
 Widget _buildFeaturedMatchSection() {
 final bool loading = widget.viewModel.loadingMatch;
 final BMMatchModel? match = widget.viewModel.featuredMatch;
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Row(
 children: [
 const Icon(Icons.stadium, size: 16, color: BMColors.bright),
 const SizedBox(width: 6),
 const Text(
 'focus competition',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                if (loading) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: BMColors.bright,
                    ),
                  ),
                ],
              ],
            ),
            GestureDetector(
              onTap: loading ? null : _navigateToMatchList,
              child: Opacity(
                opacity: loading ? 0.4 : 1.0,
                child: const Row(
                  children: [
                    Text(
                      'view all',
 style: TextStyle(fontSize: 12, color: BMColors.bright),
),
 Icon(Icons.chevron_right, size: 14, color: BMColors.bright),
 ],
),
),
),
 ],
),
 const SizedBox(height: 10),
 loading
 ? _buildMatchSkeleton()
: (match != null
 ? BMMatchSpotlightCard(
 match: match,
 onTap: () {
 Navigator.push(
 context,
 MaterialPageRoute(
 builder: (_) =>
 widget.viewModel.currentSport ==
 BMSportType.football
 ? BMFootballDetailPage(match: match)
: BMBasketballDetailPage(match: match),
),
);
 },
)
: const SizedBox.shrink()),
 ],
);
 }

 /// buildfocus competitionloadingskeleton
 Widget _buildMatchSkeleton() {
 return Container(
 width: double.infinity,
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
),
 child: Column(
 children: [
 Row(
 children: [
 Container(
 width: 8,
 height: 8,
 decoration: const BoxDecoration(
 shape: BoxShape.circle,
 color: Color(0xFF1E40AF),
),
),
 const SizedBox(width: 6),
 Container(
 width: 120,
 height: 12,
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(6),
),
),
 const Spacer(),
 Container(
 width: 70,
 height: 20,
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(12),
),
),
 ],
),
 const SizedBox(height: 16),
 Row(
 children: [
 Expanded(
 child: Column(
 children: [
 Container(
 width: 48,
 height: 48,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 color: BMColors.pitch800,
),
),
 const SizedBox(height: 8),
 Container(
 width: 80,
 height: 12,
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(6),
),
),
 ],
),
),
 Column(
 children: [
 Row(
 children: [
 Container(
 width: 26,
 height: 28,
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(4),
),
),
 const SizedBox(width: 8),
 Container(
 width: 10,
 height: 16,
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(2),
),
),
 const SizedBox(width: 8),
 Container(
 width: 26,
 height: 28,
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(4),
),
),
 ],
),
 ],
),
 Expanded(
 child: Column(
 children: [
 Container(
 width: 48,
 height: 48,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 color: BMColors.pitch800,
),
),
 const SizedBox(height: 8),
 Container(
 width: 80,
 height: 12,
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(6),
),
),
 ],
),
),
 ],
),
 ],
),
);
 }

 /// buildhot newszone (No. twosection, modifypoint2)
 Widget _buildHotNewsSection() {
 final bool loading = widget.viewModel.loadingNews;
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Row(
 children: [
 const Icon(
 Icons.local_fire_department,
 size: 16,
 color: BMColors.bright,
),
 const SizedBox(width: 6),
 const Text(
 'hot news',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                if (loading) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: BMColors.bright,
                    ),
                  ),
                ],
              ],
            ),
            GestureDetector(
              onTap: loading ? null : _navigateToNewsList,
              child: Opacity(
                opacity: loading ? 0.4 : 1.0,
                child: const Row(
                  children: [
                    Text(
                      'view all',
 style: TextStyle(fontSize: 12, color: BMColors.bright),
),
 Icon(Icons.chevron_right, size: 14, color: BMColors.bright),
 ],
),
),
),
 ],
),
 const SizedBox(height: 10),
 loading ? _buildNewsSkeleton(): _buildNewsContent(),
 ],
);
 }

 Widget _buildNewsContent() {
 return BMHotNewsSection(
 newsList: widget.viewModel.newsList,
 onNewsTap: (BMNewsModel news) {
 final int? id = int.tryParse(news.newsId);
 Navigator.push(
 context,
 MaterialPageRoute(
 builder: (_) =>
 BMNewsDetailPage(newsId: id ?? 0, newsTitle: news.title),
),
);
 },
);
 }

 /// buildhot newsloadingskeleton (singlepage1.5itemscard)
 Widget _buildNewsSkeleton() {
 return SizedBox(
 height: 160,
 child: Row(
 children: [
 Expanded(flex: 6, child: _buildNewsCardSkeleton()),
 const SizedBox(width: 8),
 Expanded(flex: 3, child: _buildNewsCardSkeleton()),
 const SizedBox(width: 8),
 ],
),
);
 }

 Widget _buildNewsCardSkeleton() {
 return Container(
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.4)),
),
 padding: const EdgeInsets.all(14),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 const Spacer(),
 Container(
 width: double.infinity,
 height: 14,
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(6),
),
),
 const SizedBox(height: 6),
 Container(
 width: 160,
 height: 14,
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(6),
),
),
 const SizedBox(height: 10),
 Row(
 children: [
 Container(
 width: 48,
 height: 10,
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(4),
),
),
 ],
),
 ],
),
);
 }

 /// buildhot topiczone (third section, modifypoint3)
 Widget _buildHotTopicsSection() {
 final bool loading = widget.viewModel.loadingTopics;
 final List<BMTopicModel> topics = widget.viewModel.topicList;
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Row(
 children: [
 const Icon(Icons.bolt, size: 16, color: BMColors.amber),
 const SizedBox(width: 6),
 const Text(
 'hot topic',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                if (loading) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: BMColors.amber,
                    ),
                  ),
                ],
              ],
            ),
            GestureDetector(
              onTap: loading ? null : _navigateToTopicList,
              child: Opacity(
                opacity: loading ? 0.4 : 1.0,
                child: const Row(
                  children: [
                    Text(
                      'view all',
 style: TextStyle(fontSize: 12, color: BMColors.bright),
),
 Icon(Icons.chevron_right, size: 14, color: BMColors.bright),
 ],
),
),
),
 ],
),
 const SizedBox(height: 12),
 if (loading)
 _buildTopicsSkeleton()
 else
 BMHotTopicsSection(
 topicList: topics,
 onTopicTap: _onTopicTap,
 onMatchTap: _onTopicMatchTap,
 onBlockTopic: _onBlockTopic,
 onViewAll: _navigateToTopicList,
),
 ],
);
 }

 Widget _buildTopicsSkeleton() {
 return Column(
 children: [
 _buildTopicCardSkeleton(),
 const SizedBox(height: 12),
 _buildTopicCardSkeleton(),
 const SizedBox(height: 12),
 _buildTopicCardSkeleton(),
 ],
);
 }

 Widget _buildTopicCardSkeleton() {
 return Container(
 padding: const EdgeInsets.all(14),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Container(
 width: 32,
 height: 32,
 decoration: const BoxDecoration(
 shape: BoxShape.circle,
 color: BMColors.pitch700,
),
),
 const SizedBox(width: 8),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Container(
 width: 100,
 height: 12,
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(6),
),
),
 const SizedBox(height: 4),
 Container(
 width: 60,
 height: 10,
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(5),
),
),
 ],
),
),
 Container(
 width: 26,
 height: 26,
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(8),
),
),
 ],
),
 const SizedBox(height: 10),
 Container(
 width: 100,
 height: 22,
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(12),
),
),
 const SizedBox(height: 8),
 Container(
 width: double.infinity,
 height: 10,
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(4),
),
),
 const SizedBox(height: 4),
 Container(
 width: double.infinity,
 height: 10,
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(4),
),
),
 const SizedBox(height: 10),
 Container(
 padding: const EdgeInsets.all(10),
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(10),
),
 child: Row(
 children: [
 Container(
 width: 160,
 height: 10,
 decoration: BoxDecoration(
 color: BMColors.pitch700,
 borderRadius: BorderRadius.circular(4),
),
),
 ],
),
),
 ],
),
);
 }

 /// navigatetocompetitionlistpage (modifypoint1 of navigatelogic)
 void _navigateToMatchList() {
 Navigator.of(context).push(
 MaterialPageRoute(
 builder: (context) =>
 BMMatchListPage(sportType: widget.viewModel.currentSport),
),
);
 }

 /// navigatetonewslistpage (No. twosection「view all」navigate)
 void _navigateToNewsList() {
 Navigator.of(context)
.push(MaterialPageRoute(builder: (context) => const BMNewsListPage()));
 }

 /// navigatetotopiclistpage (third section「view all」navigate, type=2 latest)
 void _navigateToTopicList() {
 Navigator.of(context)
.push(MaterialPageRoute(builder: (context) => const BMTopicListPage()));
 }

 /// homehot topic cardtap to navigatetopic detail page
 /// [topic] - currenttopicmodel (BMTopicModel type, topicId i.e.postID)
 /// returns true meanspostbyremove, notification ViewModel localremove
 Future<void> _onTopicTap(BMTopicModel topic) async {
 final int postId = int.tryParse(topic.topicId) ?? 0;
 if (postId == 0) return;
 final deleted = await Navigator.of(context).push(
 MaterialPageRoute(
 builder: (context) => BMTopicDetailPage(postId: postId),
),
);
 if (deleted == true && mounted) {
 widget.viewModel.removeTopic(topic.topicId);
 }
 }

 /// topsearchbuttontap push searchpage (includessearch historycache + matchdetailnavigate)
 void _onSearchTap() {
 Navigator.of(
 context,
).push(MaterialPageRoute(builder: (context) => const BMHomeSearchPage()));
 }

 /// homehot topicinnermatchcardnavigate (by sport typesplit by: basketball -> basketball detail / others -> football detail)
 /// [topic] - currenttopicmodel (BMTopicModel type, take embeddedMatch)
 void _onTopicMatchTap(BMTopicModel topic) {
 final match = topic.embeddedMatch;
 if (match == null) return;
 Navigator.of(context).push(
 MaterialPageRoute(
 builder: (context) => match.sportType == BMMatchSportType.basketball
 ? BMBasketballDetailPage(match: match)
: BMFootballDetailPage(match: match),
),
);
 }

 /// homehot topicblockhandle (andtopiclistpagelogicone)
 /// [topic] - currenttopicmodel (BMTopicModel type)
 /// flow: double confirmationdialog -> POST block_post -> successlater ViewModel delete locally
 Future<void> _onBlockTopic(BMTopicModel topic) async {
 // blocklogin required, not logged innavigate to loginUI (loginsuccessreturnslatercontinueblock)
 if (!BMAuthManager().isLoggedIn) {
 final ok = await Navigator.push<bool>(
 context,
 MaterialPageRoute(builder: (_) => const BMLoginPage()),
);
 if (ok != true) return;
 if (!mounted) return;
 }
 final int postId = int.tryParse(topic.topicId) ?? 0;
 if (postId == 0) return;

 // blockfirstconfirmation dialogconfirm
 final bool? confirmed = await showDialog<bool>(
 context: context,
 builder: (ctx) => AlertDialog(
 backgroundColor: BMColors.pitch850,
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(14),
 side: BorderSide(color: BMColors.pitch700.withValues(alpha: 0.5)),
),
 title: const Text(
 'Block Confirm',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: BMColors.textPrimary,
          ),
        ),
        content: const Text(
          'You will no longer see this post after blocking',
          style: TextStyle(fontSize: 13, color: BMColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Take effect',
              style: TextStyle(fontSize: 14, color: BMColors.textTertiary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'block',
 style: TextStyle(fontSize: 14, color: Color(0xFFDC2626)),
),
),
 ],
),
);
 if (confirmed != true || !mounted) return;

 // block: APIsuccesslater ViewModel delete locallythetopic
 final bool ok = await BMCommunityApiService().blockPost(
 postId: postId,
 type: 1,
);
 if (!mounted) return;
 if (ok) {
 widget.viewModel.removeTopic(topic.topicId);
 } else {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: const Text(
 'blockfailure, please retry later',
            style: TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: BMColors.pitch800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
