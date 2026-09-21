import 'package:flutter/material.dart';
import '../../models/bm_match_model.dart';
import '../../models/bm_news_model.dart';
import '../../models/bm_topic_model.dart';
import '../../theme/bm_colors.dart';
import '../../services/bm_match_api_service.dart';
import '../../services/bm_news_api_service.dart';
import '../../services/bm_community_api_service.dart';

/// BMHomeViewModel - 首页视图模型
/// 功能: 管理首页数据, 包括焦点赛事、热门资讯、热门话题
/// 架构层级: ViewModel (MVVM), 连接Model与View
/// 缓存逻辑: 切到篮球时, 热门资讯/话题若已有缓存则复用, 缓存为空才请求
class BMHomeViewModel extends ChangeNotifier {
  /// 当前选中的运动类型 (BMSportType 枚举, 默认足球)
  BMSportType _currentSport = BMSportType.football;

  /// 是否正在加载焦点赛事 (bool 类型)
  bool _loadingMatch = false;

  /// 是否正在加载资讯 (bool 类型)
  bool _loadingNews = false;

  /// 是否正在加载话题 (bool 类型)
  bool _loadingTopics = false;

  /// 焦点赛事数据 (BMMatchModel? 类型, 懒加载)
  BMMatchModel? _featuredMatch;

  /// 热门资讯缓存 (List<BMNewsModel> 类型, 足球/篮球共用)
  List<BMNewsModel> _cachedNewsList = [];

  /// 热门话题缓存 (List<BMTopicModel> 类型, 足球/篮球共用)
  List<BMTopicModel> _cachedTopicList = [];

  /// 比赛列表数据 (List<BMMatchModel> 类型, 用于view all跳转)
  List<BMMatchModel> _matchList = [];

  /// 获取当前运动类型
  BMSportType get currentSport => _currentSport;

  /// 获取焦点赛事
  BMMatchModel? get featuredMatch => _featuredMatch;

  /// 获取热门资讯列表 (复用缓存)
  List<BMNewsModel> get newsList => _cachedNewsList;

  /// 获取热门话题列表 (复用缓存)
  List<BMTopicModel> get topicList => _cachedTopicList;

  /// 获取比赛列表
  List<BMMatchModel> get matchList => _matchList;

  /// 是否加载中焦点赛事
  bool get loadingMatch => _loadingMatch;

  /// 是否加载中资讯
  bool get loadingNews => _loadingNews;

  /// 是否加载中话题
  bool get loadingTopics => _loadingTopics;

  /// 初始化数据 (懒加载)
  /// 功能: 首次访问时加载所有首页数据 (默认足球)
  Future<void> loadData() async {
    await Future.wait([
      _loadFeaturedMatch(),
      _loadNewsListIfNeeded(force: true),
      _loadTopicListIfNeeded(force: true),
    ]);
    _loadMatchListMock();
    notifyListeners();
  }

  /// 下拉刷新数据
  /// 功能: 强制重新拉取当前运动类型的所有三段数据
  /// 返回: Future<void>, RefreshIndicator会等待其完成
  Future<void> refreshData() async {
    await Future.wait([
      _loadFeaturedMatch(),
      _loadNewsListIfNeeded(force: true),
      _loadTopicListIfNeeded(force: true),
    ]);
    _loadMatchListMock();
    notifyListeners();
  }

  /// 切换运动类型
  /// 参数: [sport] 目标运动类型
  /// 仅切换焦点赛事(足球/篮球不同API); 资讯/话题仅当缓存为空时才请求, 有值直接复用
  /// 强制刷新资讯/话题走下拉刷新 refreshData()
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

  /// 加载焦点赛事数据 (真实API)
  /// 足球: POST /api/livespeed/football/matches tab=5 size=1
  /// 篮球: POST /api/livespeed/basketball/matches tab=5 size=1
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
      debugPrint('BMHomeViewModel 焦点赛事请求异常: $e');
      _featuredMatch = _currentSport == BMSportType.football
          ? _mockFootballMatch()
          : _mockBasketballMatch();
    } finally {
      _loadingMatch = false;
    }
  }

  /// 加载热门资讯 (带缓存逻辑)
  /// force=true: 强制重新请求 (足球模式)
  /// force=false: 若缓存有值则复用, 空才请求 (篮球模式)
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
      debugPrint('BMHomeViewModel 热门资讯请求异常: $e');
      if (_cachedNewsList.isEmpty) {
        _cachedNewsList = _mockNewsList();
      }
    } finally {
      _loadingNews = false;
    }
  }

  /// 加载热门话题 (带缓存逻辑)
  /// force=true: 强制重新请求 (足球模式)
  /// force=false: 若缓存有值则复用, 空才请求 (篮球模式)
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
      debugPrint('BMHomeViewModel 热门话题请求异常: $e');
      if (_cachedTopicList.isEmpty) {
        _cachedTopicList = _mockTopicList();
      }
    } finally {
      _loadingTopics = false;
    }
  }

  /// 加载比赛列表Mock (view all跳转用)
  void _loadMatchListMock() {
    if (_currentSport == BMSportType.football) {
      _matchList = [
        _mockFootballMatch(),
        BMMatchModel(
          matchId: 'bayern-psg',
          homeTeamName: '拜仁慕尼黑',
          awayTeamName: '巴黎圣日耳曼',
          homeScore: null,
          awayScore: null,
          leagueName: '欧洲冠军联赛',
          round: '半决赛',
          status: BMMatchStatus.upcoming,
          matchTime: '03:00',
        ),
      ];
    } else {
      _matchList = [
        _mockBasketballMatch(),
        BMMatchModel(
          matchId: 'celtics-heat',
          homeTeamName: '凯尔特人',
          awayTeamName: '热火',
          homeScore: null,
          awayScore: null,
          leagueName: 'NBA 季后赛',
          round: '常规赛',
          status: BMMatchStatus.upcoming,
          matchTime: '08:00',
        ),
      ];
    }
  }

  // ========= 以下为Mock兜底数据, 用于API失败时展示 =========

  /// Mock足球焦点赛事
  BMMatchModel _mockFootballMatch() {
    return BMMatchModel(
      matchId: 'real-mci',
      homeTeamName: '皇家马德里',
      awayTeamName: '曼彻斯特城',
      homeTeamLogo: null,
      awayTeamLogo: null,
      homeScore: 2,
      awayScore: 1,
      leagueName: '欧冠半决赛',
      round: '焦点对决',
      status: BMMatchStatus.live,
      matchTime: "68'",
      aiWinRate: 64,
      homeXG: 1.84,
      awayXG: 1.12,
      momentumPercent: 58,
      isFeatured: true,
    );
  }

  /// Mock篮球焦点赛事
  BMMatchModel _mockBasketballMatch() {
    return BMMatchModel(
      matchId: 'lakers-warriors',
      homeTeamName: '洛杉矶湖人',
      awayTeamName: '金州勇士',
      homeTeamLogo: null,
      awayTeamLogo: null,
      homeScore: 102,
      awayScore: 98,
      leagueName: 'NBA 季后赛',
      round: '焦点对决',
      status: BMMatchStatus.live,
      matchTime: "Q3 04:12",
      aiWinRate: 0,
      homeXG: 0,
      awayXG: 0,
      momentumPercent: 0,
      isFeatured: true,
    );
  }

  /// Mock热门资讯列表 (5条)
  List<BMNewsModel> _mockNewsList() {
    return [
      BMNewsModel(
        newsId: 'news-1',
        title: '欧冠半决赛深度前瞻: 皇马主场能否压制曼城传控体系',
        summary: 'AI模型推演 | 主队前场压迫指数达近两季峰值',
        imageUrl: '',
        tag: '独家',
        tagColor: BMColors.accent.toARGB32(),
        publishTime: '2小时前',
      ),
      BMNewsModel(
        newsId: 'news-2',
        title: 'NBA季后赛盘点: 湖人勇士转换进攻效率全面对比',
        summary: 'PACE高速模型 | 近3次交手得分均超32分',
        imageUrl: '',
        tag: '快讯',
        tagColor: BMColors.cyan.toARGB32(),
        publishTime: '3小时前',
      ),
      BMNewsModel(
        newsId: 'news-3',
        title: '英超争四白热化: 阿森纳主场xG高达2.41领跑数据榜',
        summary: '高阶建模 | 切尔西主力中卫缺阵影响几何',
        imageUrl: '',
        tag: '深度',
        tagColor: BMColors.gold.toARGB32(),
        publishTime: '5小时前',
      ),
      BMNewsModel(
        newsId: 'news-4',
        title: '凯利指数异动监测: 本周五大联赛水位变轨全记录',
        summary: '资金博弈 | 各大机构赔率异常偏离度追踪',
        imageUrl: '',
        tag: '预警',
        tagColor: BMColors.purple.toARGB32(),
        publishTime: '6小时前',
      ),
      BMNewsModel(
        newsId: 'news-5',
        title: '德甲收官阶段: 拜仁主场优势加权推演与盘路分析',
        summary: '蒙特卡洛模拟 | 10000次运算主胜概率62.8%',
        imageUrl: '',
        tag: '独家',
        tagColor: BMColors.accent.toARGB32(),
        publishTime: '8小时前',
      ),
    ];
  }

  /// Mock热门话题列表 (3条)
  List<BMTopicModel> _mockTopicList() {
    return [
      BMTopicModel(
        topicId: 'topic-1',
        title: '阿森纳 vs 切尔西',
        category: '英超 · 第34轮 23:00',
        heatCount: 2840,
        prediction: '预测: 主胜 / 2.5大球',
        aiInsight: '阿森纳近4场主场xG达2.41，切尔西主力中卫缺阵，主队前场压迫指数达近两季峰值。',
        tagColor: BMColors.accent.toARGB32(),
        tagText: '模型匹配度 92%',
        iconType: BMTopicIconType.info,
      ),
      BMTopicModel(
        topicId: 'topic-2',
        title: '湖人 vs 勇士',
        category: 'NBA 季后赛 · 08:30',
        heatCount: 1960,
        prediction: '预测: 224.5 总分大',
        aiInsight: '两队近3次交手转换进攻得分均超32分，本场指数调整较初盘上调3.5分，走势吻合。',
        tagColor: BMColors.cyan.toARGB32(),
        tagText: '篮球 PACE 高速模型',
        iconType: BMTopicIconType.chart,
      ),
      BMTopicModel(
        topicId: 'topic-3',
        title: '拜仁 vs 多特蒙德',
        category: '德甲 · 第32轮 01:30',
        heatCount: 3210,
        prediction: '预测: 主胜 / 让-0.5',
        aiInsight: '拜仁主场连续不败纪录已达18场，多特蒙德客场失球率近5轮飙升至1.8球/场。',
        tagColor: BMColors.gold.toARGB32(),
        tagText: '主场模型 匹配度 88%',
        iconType: BMTopicIconType.info,
      ),
    ];
  }
}

/// BMSportType - 运动类型枚举
enum BMSportType {
  /// 足球
  football,

  /// 篮球
  basketball,
}