import 'package:flutter/material.dart';
import '../../models/bm_match_model.dart';
import '../../models/bm_news_model.dart';
import '../../models/bm_topic_model.dart';
import '../../theme/bm_colors.dart';
import '../../services/bm_match_api_service.dart';
import '../../services/bm_news_api_service.dart';
import '../../services/bm_community_api_service.dart';

/// BMHomeViewModel - homeview model
/// feature: homedata, focus competition、hot news、hot topic
/// architecturelayerlevel: ViewModel (MVVM), ModelandView
/// cachelogic: tobasketballwhen, hot news/topicifalreadyhascachethenreuse, cacheasemptythen request
class BMHomeViewModel extends ChangeNotifier {
 /// currentselectedsport type (BMSportType enum, defaultfootball)
 BMSportType _currentSport = BMSportType.football;

 /// whethercenterloadingfocus competition (bool type)
 bool _loadingMatch = false;

 /// whethercenterloadingnews (bool type)
 bool _loadingNews = false;

 /// whethercenterloadingtopic (bool type)
 bool _loadingTopics = false;

 /// focus competition data (BMMatchModel? type, lazy load)
 BMMatchModel? _featuredMatch;

 /// hot newscache (List<BMNewsModel> type, football/basketballshared)
 List<BMNewsModel> _cachedNewsList = [];

 /// hot topiccache (List<BMTopicModel> type, football/basketballshared)
 List<BMTopicModel> _cachedTopicList = [];

 /// matchlistdata (List<BMMatchModel> type, forview allnavigate)
 List<BMMatchModel> _matchList = [];

 /// gettakecurrentsport type
 BMSportType get currentSport => _currentSport;

 /// gettakefocus competition
 BMMatchModel? get featuredMatch => _featuredMatch;

 /// fetch hot news list (reuse cache)
 List<BMNewsModel> get newsList => _cachedNewsList;

 /// fetch hot topic list (reuse cache)
 List<BMTopicModel> get topicList => _cachedTopicList;

 /// removespecifiedtopic (localblock)
 /// argument: [topicId] topicID
 /// feature: blocksuccesslaterfromcachelistinremovethetopicandnotificationUIrefresh
 void removeTopic(String topicId) {
 _cachedTopicList.removeWhere((t) => t.topicId == topicId);
 notifyListeners();
 }

 /// gettakematchlist
 List<BMMatchModel> get matchList => _matchList;

 /// loading or notfocus competition
 bool get loadingMatch => _loadingMatch;

 /// loading or notnews
 bool get loadingNews => _loadingNews;

 /// loading or nottopic
 bool get loadingTopics => _loadingTopics;

 /// initializedata (lazy load)
 /// feature: first timewhenloadingallhashomedata (defaultfootball)
 Future<void> loadData() async {
 await Future.wait([
 _loadFeaturedMatch(),
 _loadNewsListIfNeeded(force: true),
 _loadTopicListIfNeeded(force: true),
 ]);
 _loadMatchListMock();
 notifyListeners();
 }

 /// pull downrefreshdata
 /// feature: makeheavynewtakecurrentsport type of allhasthreesectiondata
 /// returns: Future<void>, RefreshIndicatorwillwaititsdone
 Future<void> refreshData() async {
 await Future.wait([
 _loadFeaturedMatch(),
 _loadNewsListIfNeeded(force: true),
 _loadTopicListIfNeeded(force: true),
 ]);
 _loadMatchListMock();
 notifyListeners();
 }

 /// switch sport type
 /// argument: [sport] goalsport type
 /// onlyswitchfocus competition(football/basketballnotsameAPI); news/topiconlywhencacheasemptywhenthen request, hasvaluereuse
 /// makerefreshnews/topicpull downrefresh refreshData()
 Future<void> switchSport(BMSportType sport) async {
 if (_currentSport == sport) return;
 _currentSport = sport;

 await Future.wait([
 _loadFeaturedMatch(),
 _loadNewsListIfNeeded(force: false),
 _loadTopicListIfNeeded(force: false),
 ]);
 _loadMatchListMock();
 notifyListeners();
 }

 /// loadingfocus competition data (trueactual API)
 /// football: POST /api/livespeed/football/matches tab=5 size=1
 /// basketball: POST /api/livespeed/basketball/matches tab=5 size=1
 Future<void> _loadFeaturedMatch() async {
 _loadingMatch = true;
 notifyListeners();

 try {
 if (_currentSport == BMSportType.football) {
 final match = await BMMatchApiService().fetchFeaturedFootballMatch();
 if (match != null) {
 _featuredMatch = match;
 } else {
 _featuredMatch = _mockFootballMatch();
 }
 } else {
 final match = await BMMatchApiService().fetchFeaturedBasketballMatch();
 if (match != null) {
 _featuredMatch = match;
 } else {
 _featuredMatch = _mockBasketballMatch();
 }
 }
 } catch (e) {
 debugPrint('BMHomeViewModel focus competitionrequestexception: $e');
 _featuredMatch = _currentSport == BMSportType.football
 ? _mockFootballMatch()
: _mockBasketballMatch();
 } finally {
 _loadingMatch = false;
 }
 }

 /// loadinghot news (with cache logic)
 /// force=true: force re-request (football mode)
 /// force=false: reuse cache if present, emptythen request (basketball mode)
 Future<void> _loadNewsListIfNeeded({required bool force}) async {
 if (!force && _cachedNewsList.isNotEmpty) {
 return;
 }

 _loadingNews = true;
 notifyListeners();

 try {
 final list = await BMNewsApiService().fetchNewsModels(count: 5);
 if (list.isNotEmpty) {
 _cachedNewsList = list;
 } else {
 _cachedNewsList = _mockNewsList();
 }
 } catch (e) {
 debugPrint('BMHomeViewModel hot newsrequestexception: $e');
 if (_cachedNewsList.isEmpty) {
 _cachedNewsList = _mockNewsList();
 }
 } finally {
 _loadingNews = false;
 }
 }

 /// loadinghot topic (with cache logic)
 /// force=true: force re-request (football mode)
 /// force=false: reuse cache if present, emptythen request (basketball mode)
 Future<void> _loadTopicListIfNeeded({required bool force}) async {
 if (!force && _cachedTopicList.isNotEmpty) {
 return;
 }

 _loadingTopics = true;
 notifyListeners();

 try {
 final list = await BMCommunityApiService().fetchTopicModels(
 count: 3,
);
 if (list.isNotEmpty) {
 _cachedTopicList = list;
 } else {
 _cachedTopicList = _mockTopicList();
 }
 } catch (e) {
 debugPrint('BMHomeViewModel hot topicrequestexception: $e');
 if (_cachedTopicList.isEmpty) {
 _cachedTopicList = _mockTopicList();
 }
 } finally {
 _loadingTopics = false;
 }
 }

 /// loadingmatchlistMock (view allnavigateusage)
 void _loadMatchListMock() {
 if (_currentSport == BMSportType.football) {
 _matchList = [
 _mockFootballMatch(),
 BMMatchModel(
 matchId: 'bayern-psg',
          homeTeamName: '',
          awayTeamName: 'day',
          homeScore: null,
          awayScore: null,
          leagueName: 'champion league',
          round: 'halfmatch',
          status: BMMatchStatus.upcoming,
          matchTime: '03:00',
        ),
      ];
    } else {
      _matchList = [
        _mockBasketballMatch(),
        BMMatchModel(
          matchId: 'celtics-heat',
          homeTeamName: 'special people',
          awayTeamName: '',
          homeScore: null,
          awayScore: null,
          leagueName: 'NBA playoffs',
          round: 'match',
          status: BMMatchStatus.upcoming,
          matchTime: '08:00',
),
 ];
 }
 }

 // ========= withlowerasMockfallbackdata, forAPIfailurewhenshow =========

 /// Mockfootballfocus competition
 BMMatchModel _mockFootballMatch() {
 return BMMatchModel(
 matchId: 'real-mci',
      homeTeamName: '',
      awayTeamName: 'special',
      homeTeamLogo: null,
      awayTeamLogo: null,
      homeScore: 2,
      awayScore: 1,
      leagueName: 'champion semi-final',
      round: 'focus clash',
      status: BMMatchStatus.live,
      matchTime: "68'",
 aiWinRate: 64,
 homeXG: 1.84,
 awayXG: 1.12,
 momentumPercent: 58,
 isFeatured: true,
);
 }

 /// Mockbasketballfocus competition
 BMMatchModel _mockBasketballMatch() {
 return BMMatchModel(
 matchId: 'lakers-warriors',
      homeTeamName: 'people',
      awayTeamName: '',
      homeTeamLogo: null,
      awayTeamLogo: null,
      homeScore: 102,
      awayScore: 98,
      leagueName: 'NBA playoffs',
      round: 'focus clash',
      status: BMMatchStatus.live,
      matchTime: "Q3 04:12",
 aiWinRate: 0,
 homeXG: 0,
 awayXG: 0,
 momentumPercent: 0,
 isFeatured: true,
);
 }

 /// Mockhot news list (5items)
 List<BMNewsModel> _mockNewsList() {
 return [
 BMNewsModel(
 newsId: 'news-1',
        title: 'champion semi-finaldeepfirst: homecourtabilitymakepassbodysystem',
        summary: 'AImodel | home teamfirstcourtindexnearseasonvalue',
        imageUrl: '',
        tag: 'exclusive',
        tagColor: BMColors.accent.toARGB32(),
        publishTime: '2hourfirst',
      ),
      BMNewsModel(
        newsId: 'news-2',
        title: 'NBAplayoffsoddspoint: peopleconverteffectratefullplanecompare',
        summary: 'PACEhigh-speed model | near3timegetmin32min',
        imageUrl: '',
        tag: 'news flash',
        tagColor: BMColors.cyan.toARGB32(),
        publishTime: '3hourfirst',
      ),
      BMNewsModel(
        newsId: 'news-3',
        title: 'Premier Leaguefourwhite: homecourtxGheight2.41databoard',
        summary: 'heightbuildmodule | homepoweringuardmissingimpact',
        imageUrl: '',
        tag: 'deep',
        tagColor: BMColors.gold.toARGB32(),
        publishTime: '5hourfirst',
      ),
      BMNewsModel(
        newsId: 'news-4',
        title: 'indexdifftest: thisweekfivelargeleagueodds valuechangefullrecord',
        summary: ' | eachlargestructoddsexceptionleavedegree',
        imageUrl: '',
        tag: 'alert',
        tagColor: BMColors.purple.toARGB32(),
        publishTime: '6hourfirst',
      ),
      BMNewsModel(
        newsId: 'news-5',
        title: 'Bundesligareceivesection: homecourtbestmomentumaddandoddsanalysis',
        summary: 'specialcardmodule | 10000timecalchome win probability62.8%',
        imageUrl: '',
        tag: 'exclusive',
        tagColor: BMColors.accent.toARGB32(),
        publishTime: '8hourfirst',
),
 ];
 }

 /// Mockhot topic list (3items)
 List<BMTopicModel> _mockTopicList() {
 return [
 BMTopicModel(
 topicId: 'topic-1',
        title: ' vs ',
        category: 'Premier League · No. 34round 23:00',
        heatCount: 2840,
        prediction: 'prediction: home win / 2.5over',
        aiInsight: 'near4courthomecourtxG2.41，homepoweringuardmissing，home teamfirstcourtindexnearseasonvalue。',
        tagColor: BMColors.accent.toARGB32(),
        tagText: 'modelmatch level 92%',
        iconType: BMTopicIconType.info,
      ),
      BMTopicModel(
        topicId: 'topic-2',
        title: 'people vs ',
        category: 'NBA playoffs · 08:30',
        heatCount: 1960,
        prediction: 'prediction: 224.5 totallarge',
        aiInsight: 'teamnear3timeconvertgetmin32min，thiscourtindexadjustopening oddsupper3.5min，trendmerge。',
        tagColor: BMColors.cyan.toARGB32(),
        tagText: 'basketball PACE high-speed model',
        iconType: BMTopicIconType.chart,
      ),
      BMTopicModel(
        topicId: 'topic-3',
        title: ' vs morespecial',
        category: 'Bundesliga · No. 32round 01:30',
        heatCount: 3210,
        prediction: 'prediction: home win / let-0.5',
        aiInsight: 'homecourtcontinuenotalready18court，morespecialawaycourtconcederatenear5round1.8ball/court。',
        tagColor: BMColors.gold.toARGB32(),
        tagText: 'homecourtmodel match level 88%',
 iconType: BMTopicIconType.info,
),
 ];
 }
}

/// BMSportType - sport type enum
enum BMSportType {
 /// football
 football,

 /// basketball
 basketball,
}