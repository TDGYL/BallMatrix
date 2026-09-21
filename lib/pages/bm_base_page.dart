import 'package:flutter/material.dart';
import '../theme/bm_colors.dart';

/// BMBasePage - 所有页面的基类
/// 功能: 统一设置页面背景色、状态栏样式等公共属性
/// 继承要求: 所有新页面均需继承此基类
abstract class BMBasePage extends StatefulWidget {
  const BMBasePage({super.key});
}

/// BMBasePageState - 基类State
/// 功能: 提供公共的页面配置, 子类重写 [buildBody] 方法构建内容
abstract class BMBasePageState<T extends BMBasePage> extends State<T> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BMColors.pitch900,
      body: SafeArea(
        top: true,
        bottom: false,
        child: buildBody(context),
      ),
    );
  }

  /// 构建页面主体内容
  /// 子类必须实现此方法
  Widget buildBody(BuildContext context);
}