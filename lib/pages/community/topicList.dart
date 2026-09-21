import 'package:flutter/material.dart';

import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_topic_model.dart';
import '../../widgets/home/bm_hot_topics_section.dart' show TopicPostCard;

/// BMTopicListPage - 话题列表页 (首页第三段「查看全部」push 进来)
/// 功能: 纯展示界面, 不请求网络
class BMTopicListPage extends BMBasePage {
  const BMTopicListPage({
    super.key,
  });

  @override
  State<BMTopicListPage> createState() => _BMTopicListPageState();
}

class _BMTopicListPageState extends BMBasePageState<BMTopicListPage> {
  /// 话题列表数据 (List<BMTopicModel> 类型)
  List<BMTopicModel> _topicList = [];

  @override
  void initState() {
    super.initState();
    _topicList = _mockTopicList();
  }

  /// Mock 话题数据
  List<BMTopicModel> _mockTopicList() {
    return [];
  }

  /// 下拉刷新回调 (无网络请求, 空实现)
  Future<void> _onRefresh() async {
    return;
  }

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        _buildNavBar(context),
        Expanded(child: _buildTopicList()),
      ],
    );
  }

  /// 自定义导航栏 (返回 + 标题)
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
              'Topic List',
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

  /// 话题列表区
  Widget _buildTopicList() {
    if (_topicList.isEmpty) {
      return RefreshIndicator(
        color: BMColors.bright,
        backgroundColor: BMColors.pitch850,
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 140),
            Center(
              child: Icon(
                Icons.bolt_outlined,
                size: 48,
                color: BMColors.textTertiary,
              ),
            ),
            SizedBox(height: 12),
            Center(
              child: Text(
                '暂无话题',
                style: TextStyle(fontSize: 13, color: BMColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: BMColors.bright,
      backgroundColor: BMColors.pitch850,
      onRefresh: _onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        itemCount: _topicList.length,
        itemBuilder: (ctx, index) {
          final t = _topicList[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TopicPostCard(
              topic: t,
              onTap: () {},
              onMoreAction: (_, __) {},
            ),
          );
        },
      ),
    );
  }
}
