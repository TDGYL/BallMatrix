import 'package:flutter/material.dart';
import '../../models/bm_match_model.dart';
import '../../models/bm_news_model.dart';
import '../../models/bm_topic_model.dart';
import '../../theme/bm_colors.dart';

/// BMHomeViewModel - 首页视图模型
/// 功能: 管理首页数据, 包括焦点赛事、热门资讯、热门话题
/// 架构层级: ViewModel (MVVM), 连接Model与View
class BMHomeViewModel extends ChangeNotifier {
  /// 当前选中的运动类型 (BMSportType 枚举, 默认足球)
  BMSportType _currentSport = BMSportType.football;

  /// 焦点赛事数据 (BMMatchModel 类型, 懒加载)
  BMMatchModel? _featuredMatch;

  /// 热门资讯列表 (List<BMNewsModel> 类型)
  List<BMNewsModel> _newsList = [];

  /// 热门话题列表 (List<BMTopicModel> 类型)
  List<BMTopicModel> _topicList = [];

  /// 比赛列表数据 (List<BMMatchModel> 类型, 用于view all跳转)
  List<BMMatchModel> _matchList = [];

  /// 获取当前运动类型
  BMSportType get currentSport => _currentSport;

  /// 获取焦点赛事
  BMMatchModel? get featuredMatch => _featuredMatch;

  /// 获取热门资讯列表
  List<BMNewsModel> get newsList => _newsList;

  /// 获取热门话题列表
  List<BMTopicModel> get topicList => _topicList;

  /// 获取比赛列表
  List<BMMatchModel> get matchList => _matchList;

  /// 初始化数据 (懒加载)
  /// 功能: 首次访问时加载所有首页数据
  void loadData() {
    _loadFeaturedMatch();
    _loadNewsList();
    _loadTopicList();
    _loadMatchList();
    notifyListeners();
  }

  /// 切换运动类型
  /// 参数: [sport] 目标运动类型
  void switchSport(BMSportType sport) {
    if (_currentSport == sport) return;
    _currentSport = sport;
    _loadFeaturedMatch();
    _loadMatchList();
    notifyListeners();
  }

  /// 加载焦点赛事数据
  void _loadFeaturedMatch() {
    _featuredMatch = BMMatchModel(
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

  /// 加载热门资讯数据
  void _loadNewsList() {
    _newsList = [
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

  /// 加载热门话题数据
  void _loadTopicList() {
    _topicList = [
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
    ];
  }

  /// 加载比赛列表数据
  void _loadMatchList() {
    _matchList = [
      BMMatchModel(
        matchId: 'real-mci',
        homeTeamName: '皇家马德里',
        awayTeamName: '曼彻斯特城',
        homeScore: 2,
        awayScore: 1,
        leagueName: '欧洲冠军联赛',
        round: '半决赛',
        status: BMMatchStatus.live,
        matchTime: "68'",
        aiWinRate: 64,
        homeXG: 1.84,
        awayXG: 1.12,
        momentumPercent: 58,
      ),
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
        aiWinRate: 0,
        homeXG: 0,
        awayXG: 0,
        momentumPercent: 0,
      ),
      BMMatchModel(
        matchId: 'lakers-warriors',
        homeTeamName: '洛杉矶湖人',
        awayTeamName: '金州勇士',
        homeScore: 118,
        awayScore: 112,
        leagueName: 'NBA 季后赛',
        round: '常规赛',
        status: BMMatchStatus.ended,
        matchTime: '完场',
        aiWinRate: 0,
        homeXG: 0,
        awayXG: 0,
        momentumPercent: 0,
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