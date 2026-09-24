import 'package:flutter/material.dart';
import '../../models/bm_news_model.dart';
import '../../theme/bm_colors.dart';

/// BMHotNewsSection - hot newsBannerlistzone
/// feature: showhot newsBannercarousel, onepagecanviewto1.5itemscard
/// purposescope: homeNo. twosection, onlyshow: image / 2linetitle / publishtime
class BMHotNewsSection extends StatelessWidget {
 /// hot news list (List<BMNewsModel> type)
 final List<BMNewsModel> newsList;

 /// newstap callback (ValueChanged<BMNewsModel> type, can be empty)
 final ValueChanged<BMNewsModel>? onNewsTap;

 const BMHotNewsSection({
 super.key,
 required this.newsList,
 this.onNewsTap,
 });

 @override
 Widget build(BuildContext context) {
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 _buildBannerList(context),
 ],
);
 }

 /// buildBannerdirectionlist, makeusePageViewimplementonepageview1.5items
 Widget _buildBannerList(BuildContext context) {
 if (newsList.isEmpty) {
 return const SizedBox.shrink();
 }
 return SizedBox(
 height: 160,
 child: PageView.builder(
 controller: PageController(viewportFraction: 0.6667),
 itemCount: newsList.length,
 padEnds: false,
 itemBuilder: (context, index) {
 return _buildNewsCard(newsList[index]);
 },
),
);
 }

 /// buildsinglenewsBannercard
 /// onlyshow: imagebackground + title(2line) + publishtime, noneotherstag
 Widget _buildNewsCard(BMNewsModel news) {
 final coverUrl = news.displayCoverUrl;
 final hasCover = coverUrl.isNotEmpty;
 final publishText = news.displayPublishTime;
 return GestureDetector(
 onTap: () => onNewsTap?.call(news),
 child: Container(
 margin: const EdgeInsets.only(right: 8),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.4)),
 image: hasCover
 ? DecorationImage(
 image: NetworkImage(coverUrl),
 fit: BoxFit.cover,
 onError: (_, __) {},
)
: null,
),
 child: ClipRRect(
 borderRadius: BorderRadius.circular(16),
 child: Container(
 decoration: BoxDecoration(
 gradient: hasCover
 ? const LinearGradient(
 begin: Alignment.topCenter,
 end: Alignment.bottomCenter,
 colors: [
 Colors.transparent,
 Colors.black54,
 Colors.black87,
 ],
 stops: [0.3, 0.7, 1.0],
)
: null,
),
 padding: const EdgeInsets.all(14),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 const Spacer(),
 Text(
 news.title,
 style: TextStyle(
 fontSize: 14,
 fontWeight: FontWeight.bold,
 color: hasCover ? Colors.white: BMColors.textPrimary,
),
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
),
 const SizedBox(height: 8),
 if (publishText.isNotEmpty)
 Row(
 children: [
 const Icon(Icons.schedule, size: 10, color: Color(0xFF94A3B8)),
 const SizedBox(width: 4),
 Text(
 publishText,
 style: TextStyle(
 fontSize: 10,
 color: hasCover ? Colors.white70: BMColors.textTertiary,
),
),
 ],
),
 ],
),
),
),
),
);
 }
}