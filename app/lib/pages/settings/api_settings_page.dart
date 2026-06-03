import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:smart_travel_app/services/ai_planning_service.dart';
import 'package:smart_travel_app/utils/server_config.dart';
import 'package:smart_travel_app/utils/network_manager.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/components/common/common_input.dart';

class ApiSettingsPage extends StatefulWidget {
  const ApiSettingsPage({super.key});

  @override
  State<ApiSettingsPage> createState() => _ApiSettingsPageState();
}

class _ApiSettingsPageState extends State<ApiSettingsPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _serverHostController = TextEditingController();
  final TextEditingController _serverPortController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _endpointController.dispose();
    _modelController.dispose();
    _serverHostController.dispose();
    _serverPortController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final key = await AIPlanningService.getApiKey();
    final endpoint = await AIPlanningService.getApiEndpoint();
    final model = await AIPlanningService.getModel();
    final host = await ServerConfig.getHost();
    final port = await ServerConfig.getPort();
    if (mounted) {
      setState(() {
        _apiKeyController.text = key ?? '';
        _endpointController.text = endpoint;
        _modelController.text = model;
        _serverHostController.text = host;
        _serverPortController.text = port;
      });
    }
  }

  Future<void> _saveSettings() async {
    await AIPlanningService.setApiKey(_apiKeyController.text.trim());
    await AIPlanningService.setApiEndpoint(_endpointController.text.trim());
    await AIPlanningService.setModel(_modelController.text.trim());
    await ServerConfig.setHost(_serverHostController.text.trim().isEmpty
        ? ServerConfig.defaultHost
        : _serverHostController.text.trim());
    await ServerConfig.setPort(_serverPortController.text.trim().isEmpty
        ? '3000'
        : _serverPortController.text.trim());
    await NetworkManager().refreshBaseUrl();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已保存')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('服务配置'),
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurface,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI 接口',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: AppTheme.spacingM),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusL,
              ),
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  children: [
                    CommonInput(
                      controller: _apiKeyController,
                      hintText: 'API Key（留空使用离线模式）',
                      obscureText: true,
                      prefixIcon:
                          Icon(Icons.key, color: colorScheme.onSurfaceVariant),
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    CommonInput(
                      controller: _endpointController,
                      hintText: 'API 端点地址',
                      prefixIcon:
                          Icon(Icons.link, color: colorScheme.onSurfaceVariant),
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    CommonInput(
                      controller: _modelController,
                      hintText: '模型名称 (如: qwen-plus)',
                      prefixIcon: Icon(Icons.model_training,
                          color: colorScheme.onSurfaceVariant),
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer.withOpacity(0.5),
                        borderRadius: AppTheme.borderRadiusS,
                      ),
                      child: Text(
                        '支持任何兼容 OpenAI 格式的 API，如通义千问、DeepSeek、Moonshot 等。'
                        'API Key 将安全存储在本地设备中。',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppTheme.spacingXL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('保存配置'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.borderRadiusM,
                  ),
                ),
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            Text(
              '后端服务',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: AppTheme.spacingM),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusL,
              ),
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: CommonInput(
                            controller: _serverHostController,
                            hintText: '服务器地址',
                            prefixIcon: Icon(Icons.dns,
                                color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                        SizedBox(width: AppTheme.spacingS),
                        Expanded(
                          flex: 1,
                          child: CommonInput(
                            controller: _serverPortController,
                            hintText: '端口',
                            prefixIcon: Icon(Icons.settings_ethernet,
                                color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withOpacity(0.5),
                        borderRadius: AppTheme.borderRadiusS,
                      ),
                      child: Text(
                        '模拟器调试使用 10.0.2.2，真机使用电脑局域网 IP。'
                        '默认 10.0.2.2:3000，留空恢复默认。',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
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
}
