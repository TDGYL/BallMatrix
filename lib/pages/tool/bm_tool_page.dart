import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';

/// BMToolPage - 智算工具页
/// 功能: 展示高阶计算矩阵、雷达图、分析工具卡片
/// 架构: MVVM View层
/// 作用范围: 底部导航第三个Tab
class BMToolPage extends BMBasePage {
  const BMToolPage({super.key});

  @override
  State<BMToolPage> createState() => _BMToolPageState();
}

class _BMToolPageState extends BMBasePageState<BMToolPage> {
  /// 主队选择索引 (int 类型)
  int _teamAIndex = 0;

  /// 客队选择索引 (int 类型)
  int _teamBIndex = 0;

  /// 主场优势加权 (int 类型, 0-30)
  int _weight = 12;

  /// 是否计算中 (bool 类型)
  bool _isCalculating = false;

  /// 计算结果文本 (String 类型)
  String? _resultText;

  /// 主队列表
  final List<String> _teamAOptions = ['皇家马德里', '阿森纳', '拜仁慕尼黑'];
  final List<String> _teamBOptions = ['曼彻斯特城', '切尔西', '巴黎圣日耳曼'];

  @override
  Widget buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildRadarSection(),
          const SizedBox(height: 16),
          _buildToolGrid(),
        ],
      ),
    );
  }

  /// 构建页面头部
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.memory, size: 12, color: BMColors.bright),
                const SizedBox(width: 4),
                const Text(
                  '独家高阶计算矩阵',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: BMColors.bright),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              '智算数据分析实验室',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: BMColors.pitch800,
            border: Border.all(color: BMColors.pitch700),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '模型版本 v4.2',
            style: TextStyle(fontSize: 10, color: BMColors.textSecondary),
          ),
        ),
      ],
    );
  }

  /// 构建雷达图区域
  Widget _buildRadarSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xD9143328), Color(0xF00E261E)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BMColors.pitch600.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRadarHeader(),
          const SizedBox(height: 12),
          _buildTeamSelectors(),
          const SizedBox(height: 12),
          _buildRadarPlaceholder(),
          const SizedBox(height: 12),
          _buildWeightSlider(),
          const SizedBox(height: 12),
          _buildCalculateButton(),
        ],
      ),
    );
  }

  /// 构建雷达区域标题
  Widget _buildRadarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.pie_chart_outline, size: 14, color: BMColors.bright),
            const SizedBox(width: 6),
            const Text(
              '两队多维雷达实力模型引擎',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE2E8F0)),
            ),
          ],
        ),
        const Text(
          '实时计算中',
          style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: BMColors.bright),
        ),
      ],
    );
  }

  /// 构建队伍选择器
  Widget _buildTeamSelectors() {
    return Row(
      children: [
        Expanded(child: _buildTeamSelector('主队 Team A', _teamAOptions, _teamAIndex, (v) => setState(() => _teamAIndex = v))),
        const SizedBox(width: 8),
        Expanded(child: _buildTeamSelector('客队 Team B', _teamBOptions, _teamBIndex, (v) => setState(() => _teamBIndex = v))),
      ],
    );
  }

  /// 构建单个队伍选择器
  /// 参数: [label] 标签, [options] 选项列表, [selectedIndex] 选中索引, [onChanged] 回调
  Widget _buildTeamSelector(String label, List<String> options, int selectedIndex, ValueChanged<int> onChanged) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: BMColors.pitch950,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BMColors.pitch700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: BMColors.textSecondary)),
          const SizedBox(height: 4),
          DropdownButton<int>(
            value: selectedIndex,
            underline: const SizedBox(),
            isExpanded: true,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BMColors.textPrimary),
            dropdownColor: BMColors.pitch900,
            items: options.asMap().entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => onChanged(v ?? 0),
          ),
        ],
      ),
    );
  }

  /// 构建雷达图占位
  Widget _buildRadarPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: BMColors.pitch950.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.radar, size: 48, color: BMColors.bright),
            SizedBox(height: 8),
            Text(
              '多维雷达实力模型',
              style: TextStyle(fontSize: 12, color: BMColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建权重滑块
  Widget _buildWeightSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '主场优势加权 (Home Advantage)',
              style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
            ),
            Text(
              '+$_weight%',
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: BMColors.bright,
              ),
            ),
          ],
        ),
        Slider(
          value: _weight.toDouble(),
          min: 0,
          max: 30,
          activeColor: BMColors.bright,
          onChanged: (v) => setState(() => _weight = v.toInt()),
        ),
      ],
    );
  }

  /// 构建计算按钮
  Widget _buildCalculateButton() {
    return GestureDetector(
      onTap: _isCalculating ? null : _startCalculation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [BMColors.accent, Color(0xFF2DD4BF)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: BMColors.accent.withValues(alpha: 0.2), blurRadius: 20),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isCalculating)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: BMColors.pitch950),
              )
            else
              const Icon(Icons.play_arrow, size: 14, color: BMColors.pitch950),
            const SizedBox(width: 6),
            Text(
              _resultText ?? '生成蒙特卡洛 10000 次模拟报告',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: BMColors.pitch950,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 启动计算模拟
  void _startCalculation() {
    setState(() {
      _isCalculating = true;
      _resultText = '算力运算中...';
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isCalculating = false;
          _resultText = '已生成：主胜概率 62.8%';
        });
      }
    });
  }

  /// 构建工具卡片网格
  Widget _buildToolGrid() {
    final tools = [
      ('凯利与必发冷热指数', '捕获各大机构赔率异常偏离度与资金博弈方向', Icons.calculate, BMColors.cyan),
      ('历史交锋盘路克制', '结合裁判尺度、主客战术相克属性深挖克星指数', Icons.timeline, BMColors.purple),
      ('实时比赛 Momentum 走势', '分钟级进攻压制力曲线，捕捉临场进球信号', Icons.waves, BMColors.amber),
      ('异动指标实时预警', '自定义 xG 突破、红黄牌及剧烈水位变轨推送', Icons.notifications_off_outlined, BMColors.bright),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _buildToolCard(tool.$1, tool.$2, tool.$3, tool.$4);
      },
    );
  }

  /// 构建单个工具卡片
  /// 参数: [title] 标题, [desc] 描述, [icon] 图标, [color] 颜色
  Widget _buildToolCard(String title, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xD9143328), Color(0xF00E261E)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BMColors.pitch600.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BMColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(fontSize: 10, height: 1.3, color: BMColors.textSecondary),
          ),
        ],
      ),
    );
  }
}