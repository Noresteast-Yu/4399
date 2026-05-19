import 'package:flutter/material.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  final List<Map<String, dynamic>> _faqCategories = const [
    {
      'title': '路线规划',
      'icon': Icons.route,
      'questions': [
        {
          'question': '如何规划地铁路线？',
          'answer': '在首页输入起点和终点，点击"开始规划"按钮，系统会为您智能规划最优路线。您也可以点击地图上的站点直接选择。',
        },
        {
          'question': '为什么路线规划结果不准确？',
          'answer': '请确保输入的站点名称准确。系统支持模糊匹配，但建议使用完整的站点名称以获得最佳结果。',
        },
        {
          'question': '如何查看换乘信息？',
          'answer': '在路线规划结果中，点击任意路线卡片可以查看详细的换乘信息，包括换乘站点、步行距离和预计时间。',
        },
      ],
    },
    {
      'title': '出行偏好',
      'icon': Icons.settings,
      'questions': [
        {
          'question': '如何设置出行偏好？',
          'answer': '在个人中心点击"出行偏好"，您可以设置优先最少换乘、最快路线、最少步行等偏好。',
        },
        {
          'question': '行动能力设置有什么用？',
          'answer': '行动能力设置可以帮助系统为您规划无障碍路线，包括电梯、扶梯等设施信息，适合行动不便的用户。',
        },
        {
          'question': '行李设置会影响路线规划吗？',
          'answer': '是的，开启行李设置后，系统会优先规划适合携带行李的路线，并提示宽闸机位置。',
        },
      ],
    },
    {
      'title': '实时信息',
      'icon': Icons.info,
      'questions': [
        {
          'question': '如何查看地铁延误信息？',
          'answer': '在首页的"实时出行提醒"区域可以查看当前的地铁延误、故障等实时信息。',
        },
        {
          'question': '消息通知可以关闭吗？',
          'answer': '可以。在个人中心点击"消息通知"，您可以自定义接收的通知类型。',
        },
        {
          'question': '如何获取实时拥挤度？',
          'answer': '系统会根据历史数据和实时客流信息，在路线规划时显示各线路的拥挤程度。',
        },
      ],
    },
    {
      'title': '账户与设置',
      'icon': Icons.person,
      'questions': [
        {
          'question': '如何修改主题颜色？',
          'answer': '在个人中心点击"外观"，您可以选择蓝色、橙色、绿色、红色、紫色等主题颜色。',
        },
        {
          'question': '如何调整字体大小？',
          'answer': '在"外观"设置中，您可以选择最小、较小、标准、较大、最大五种字体大小。',
        },
        {
          'question': '常用路线如何管理？',
          'answer': '在个人中心的"常用路线"区域，您可以添加、删除常用路线，点击导航按钮可快速规划。',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const TopNavBar(
        title: '帮助中心',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusL,
              ),
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  children: [
                    Icon(
                      Icons.help_outline,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    Text(
                      '常见问题',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingS),
                    Text(
                      '以下是用户最常遇到的问题及解答',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            ..._faqCategories.map((category) => _buildCategorySection(
                  context,
                  category,
                )),
            SizedBox(height: AppTheme.spacingL),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusL,
              ),
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.contact_support,
                          color: colorScheme.primary,
                        ),
                        SizedBox(width: AppTheme.spacingS),
                        Text(
                          '联系客服',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    Text(
                      '如果您还有其他问题，不欢迎通过以下方式联系我们：',
                      style: textTheme.bodyMedium,
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    _buildContactItem(
                      context,
                      Icons.email,
                      '邮箱',
                      '2350790@tongji.edu.cn',
                    ),
                    _buildContactItem(
                      context,
                      Icons.phone,
                      '电话',
                      '别打了',
                    ),
                    _buildContactItem(
                      context,
                      Icons.chat,
                      '在线客服',
                      '没客服',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    Map<String, dynamic> category,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              category['icon'] as IconData,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: AppTheme.spacingS),
            Text(
              category['title'] as String,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingM),
        ...List<Map<String, String>>.from(category['questions']).map(
          (faq) => _buildFaqItem(context, faq),
        ),
        SizedBox(height: AppTheme.spacingL),
      ],
    );
  }

  Widget _buildFaqItem(
    BuildContext context,
    Map<String, String> faq,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ExpansionTile(
      title: Text(
        faq['question']!,
        style: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      iconColor: colorScheme.primary,
      collapsedIconColor: colorScheme.onSurfaceVariant,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
          child: Text(
            faq['answer']!,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    IconData icon,
    String title,
    String content,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
          SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  content,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
