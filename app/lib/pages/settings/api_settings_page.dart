import 'package:flutter/material.dart';
import 'package:smart_travel_app/services/api_service.dart';
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
  final ApiService _apiService = ApiService();

  bool _isTestingBackend = false;
  bool _isValidatingData = false;
  String? _backendStatusText;
  String? _dataValidationText;
  bool? _backendHealthy;
  bool? _dataHealthy;

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

  Future<void> _saveSettings({bool showSnackBar = true}) async {
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
    if (mounted && showSnackBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已保存')),
      );
    }
  }

  Future<void> _testBackendConnection() async {
    setState(() {
      _isTestingBackend = true;
      _backendStatusText = null;
      _backendHealthy = null;
    });

    await _saveSettings(showSnackBar: false);
    final response = await _apiService.getBackendHealth();

    if (!mounted) return;
    setState(() {
      _isTestingBackend = false;
      _backendHealthy = response.success;
      if (response.success && response.data != null) {
        final mode = response.data!['mode']?.toString() ?? 'unknown';
        final database = response.data!['database'] == true;
        _backendStatusText =
            database ? '连接成功，数据库模式运行中' : '连接成功，当前为$mode模式';
      } else {
        _backendStatusText = response.error ?? '连接失败';
      }
    });
  }

  Future<void> _validateBackendData() async {
    setState(() {
      _isValidatingData = true;
      _dataValidationText = null;
      _dataHealthy = null;
    });

    await _saveSettings(showSnackBar: false);
    final response = await _apiService.validateData();

    if (!mounted) return;
    setState(() {
      _isValidatingData = false;
      if (response.success && response.data != null) {
        final ok = response.data!['ok'] == true;
        final errors = response.data!['errors'];
        final counts = response.data!['counts'];
        final lineCount = counts is Map ? counts['network_lines'] : null;
        final stationRows =
            counts is Map ? counts['network_line_station_rows'] : null;
        _dataHealthy = ok;
        if (ok) {
          _dataValidationText =
              '数据校验通过：已覆盖${lineCount ?? '-'}条线路，${stationRows ?? '-'}条站序记录';
        } else if (errors is List && errors.isNotEmpty) {
          _dataValidationText = '数据仍需检查：${errors.take(2).join('；')}';
        } else {
          _dataValidationText = '数据校验未通过，请检查后端数据库或演示数据';
        }
      } else {
        _dataHealthy = false;
        _dataValidationText = response.error ?? '数据校验失败';
      }
    });
  }

  void _fillBackendPreset(String host, String port) {
    setState(() {
      _serverHostController.text = host;
      _serverPortController.text = port;
    });
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
                    CommonInput(
                      controller: _serverHostController,
                      hintText: '服务器地址或完整接口地址',
                      keyboardType: TextInputType.url,
                      prefixIcon:
                          Icon(Icons.dns, color: colorScheme.onSurfaceVariant),
                    ),
                    SizedBox(height: AppTheme.spacingS),
                    Wrap(
                      spacing: AppTheme.spacingS,
                      runSpacing: AppTheme.spacingS,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              _fillBackendPreset('10.0.2.2', '3000'),
                          icon: const Icon(Icons.phone_android_rounded),
                          label: const Text('安卓模拟器'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _fillBackendPreset('localhost', '3000'),
                          icon: const Icon(Icons.computer_rounded),
                          label: const Text('电脑本机'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _fillBackendPreset('', '3000'),
                          icon: const Icon(Icons.edit_location_alt_rounded),
                          label: const Text('真机手填'),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingS),
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withOpacity(0.5),
                        borderRadius: AppTheme.borderRadiusS,
                      ),
                      child: Text(
                        '模拟器用 10.0.2.2:3000。真机要填电脑 WLAN 的 IPv4 地址，'
                        '例如 http://电脑IP:3000/api，手机和电脑需要在同一网络。',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    CommonInput(
                      controller: _serverPortController,
                      hintText: '端口，默认 3000',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icon(Icons.settings_ethernet,
                          color: colorScheme.onSurfaceVariant),
                    ),
                    SizedBox(height: AppTheme.spacingS),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _serverPortController.text = '3000';
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: const Text('填入端口 3000'),
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            _isTestingBackend ? null : _testBackendConnection,
                        icon: _isTestingBackend
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              )
                            : const Icon(Icons.wifi_tethering_rounded),
                        label: Text(_isTestingBackend ? '测试中...' : '测试后端连接'),
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingS),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            _isValidatingData ? null : _validateBackendData,
                        icon: _isValidatingData
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              )
                            : const Icon(Icons.fact_check_rounded),
                        label: Text(_isValidatingData ? '校验中...' : '校验后端数据'),
                      ),
                    ),
                    if (_backendStatusText != null) ...[
                      SizedBox(height: AppTheme.spacingS),
                      _StatusLine(
                        healthy: _backendHealthy == true,
                        text: _backendStatusText!,
                        successColor: Colors.green.shade700,
                        errorColor: colorScheme.error,
                      ),
                    ],
                    if (_dataValidationText != null) ...[
                      SizedBox(height: AppTheme.spacingS),
                      _StatusLine(
                        healthy: _dataHealthy == true,
                        text: _dataValidationText!,
                        successColor: Colors.green.shade700,
                        errorColor: colorScheme.error,
                      ),
                    ],
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

class _StatusLine extends StatelessWidget {
  final bool healthy;
  final String text;
  final Color successColor;
  final Color errorColor;

  const _StatusLine({
    required this.healthy,
    required this.text,
    required this.successColor,
    required this.errorColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = healthy ? successColor : errorColor;
    return Row(
      children: [
        Icon(
          healthy ? Icons.check_circle_rounded : Icons.error_rounded,
          size: 18,
          color: color,
        ),
        SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                ),
          ),
        ),
      ],
    );
  }
}
