import 'package:flutter/material.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';

class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const TopNavBar(
        title: '用户协议',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              '一、协议接受',
              '欢迎使用地铁跑酷换乘助手（以下简称"本应用"）。在使用本应用前，请仔细阅读本用户协议。一旦您下载、安装、使用本应用，即表示您已充分理解并同意本协议的全部内容。如果您不同意本协议的任何内容，请立即停止使用本应用。',
            ),
            _buildSection(
              context,
              '二、服务说明',
              '本应用提供以下服务：\n'
              '1. 地铁路线规划：根据用户输入的起点和终点，智能规划最优出行路线。\n'
              '2. 实时出行提醒：提供地铁线路延误、故障、维护等实时信息。\n'
              '3. 个性化设置：支持用户自定义出行偏好、行动能力和行李设置。\n'
              '4. 常用路线管理：用户可添加、删除和管理常用路线。\n'
              '5. 换乘导航：提供详细的换乘指引信息。',
            ),
            _buildSection(
              context,
              '三、用户权利与义务',
              '1. 用户有权按照本协议的约定使用本应用提供的各项服务。\n'
              '2. 用户应保证提供的个人信息真实、准确、完整。\n'
              '3. 用户不得利用本应用从事任何违法、违规活动。\n'
              '4. 用户不得对本应用进行反向工程、反编译或试图获取源代码。\n'
              '5. 用户应妥善保管账户信息，因用户自身原因导致的损失由用户自行承担。',
            ),
            _buildSection(
              context,
              '四、隐私保护',
              '1. 本应用尊重并保护用户的个人隐私，将按照法律法规的要求收集、使用、存储和保护用户的个人信息。\n'
              '2. 本应用可能收集的信息包括：设备信息、位置信息、使用习惯等，用于优化服务体验。\n'
              '3. 未经用户同意，本应用不会向任何第三方披露用户的个人信息，法律法规另有规定的除外。\n'
              '4. 用户有权查阅、更正、删除自己的个人信息。',
            ),
            _buildSection(
              context,
              '五、知识产权',
              '1. 本应用的所有内容，包括但不限于文字、图片、音频、视频、软件、程序、代码、界面设计等，均受知识产权法保护。\n'
              '2. 未经本应用权利人书面许可，任何人不得擅自使用、修改、复制、传播本应用的内容。\n'
              '3. 用户在使用本应用过程中产生的内容，其知识产权归用户所有，但用户同意授予本应用非独占的、免费的、全球范围内的使用权。',
            ),
            _buildSection(
              context,
              '六、免责声明',
              '1. 本应用提供的路线规划信息仅供参考，实际出行情况可能因天气、交通状况等因素有所不同，用户应自行判断并承担相应风险。\n'
              '2. 本应用不对因网络故障、系统维护、设备损坏等原因导致的服务中断承担责任。\n'
              '3. 本应用不对用户因使用本应用而产生的任何间接、附带、特殊或后果性损害承担责任。\n'
              '4. 本应用中可能包含第三方提供的链接或服务，本应用对其内容、隐私政策或做法不承担责任。',
            ),
            _buildSection(
              context,
              '七、协议变更',
              '1. 本应用有权根据国家法律法规变化、业务发展需要等因素，适时修改本协议。\n'
              '2. 协议修改后，本应用将通过应用内通知、弹窗等方式告知用户。\n'
              '3. 用户继续使用本应用即视为接受修改后的协议。如用户不同意修改内容，有权停止使用本应用。',
            ),
            _buildSection(
              context,
              '八、争议解决',
              '1. 本协议的解释、效力及纠纷的解决，适用中华人民共和国法律。\n'
              '2. 若用户与本应用之间发生任何纠纷或争议，首先应友好协商解决。\n'
              '3. 协商不成的，任何一方均有权向本应用运营方所在地有管辖权的人民法院提起诉讼。',
            ),
            _buildSection(
              context,
              '九、其他条款',
              '1. 本协议自用户首次使用本应用之日起生效。\n'
              '2. 本协议任何条款被认定为无效或不可执行，不影响其他条款的效力。\n'
              '3. 本协议构成用户与本应用之间关于使用本应用的完整协议。',
            ),
            SizedBox(height: AppTheme.spacingL),
            Center(
              child: Text(
                '更新日期：2026年5月19日',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(height: AppTheme.spacingM),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: AppTheme.spacingS),
          Text(
            content,
            style: textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
