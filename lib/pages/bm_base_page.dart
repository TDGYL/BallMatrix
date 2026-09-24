import 'package:flutter/material.dart';
import '../theme/bm_colors.dart';

/// BMBasePage - allhaspage of class
/// feature: unifiedsettingspagebackground color、status barstylewaitproperty
/// extendsneed: allhasnewpageneedextendsclass
abstract class BMBasePage extends StatefulWidget {
 const BMBasePage({super.key});
}

/// BMBasePageState - classState
/// feature: of pageplace, subclassheavywrite [buildBody] methodbuildcontent
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

 /// buildpagemain content
 /// subclassmustimplementmethod
 Widget buildBody(BuildContext context);
}