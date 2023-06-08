import 'package:after_layout/after_layout.dart';
import 'package:circle_chart/circle_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:toolbox/core/route.dart';
import 'package:toolbox/data/provider/server.dart';
import 'package:toolbox/data/res/ui.dart';
import 'package:toolbox/locator.dart';

import '../../core/analysis.dart';
import '../../core/update.dart';
import '../../core/utils/ui.dart';
import '../../data/model/server/server.dart';
import '../../data/model/server/server_private_info.dart';
import '../../data/model/server/server_status.dart';
import '../../data/res/color.dart';
import 'server/detail.dart';
import 'server/edit.dart';
import 'setting.dart';

class FullScreenPage extends StatefulWidget {
  const FullScreenPage({Key? key}) : super(key: key);

  @override
  _FullScreenPageState createState() => _FullScreenPageState();
}

class _FullScreenPageState extends State<FullScreenPage>
    with AfterLayoutMixin, AutomaticKeepAliveClientMixin {
  late S _s;
  late MediaQueryData _media;
  late ThemeData _theme;

  final _pageController = PageController(initialPage: 0);
  final _serverProvider = locator<ServerProvider>();

  @override
  void initState() {
    super.initState();
    hideStatusBar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _s = S.of(context)!;
    _media = MediaQuery.of(context);
    _theme = Theme.of(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SafeArea(
        child: RotatedBox(
          quarterTurns: 3,
          child: Stack(
            children: [
              _buildMain(),
              Positioned(
                top: 0,
                left: 0,
                child: _buildSettingBtn(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingBtn() {
    return IconButton(
        onPressed: () => AppRoute(
              const SettingPage(),
              'Setting',
            ).go(context),
        icon: const Icon(Icons.settings, color: Colors.grey));
  }

  Widget _buildMain() {
    return Consumer<ServerProvider>(builder: (_, pro, __) {
      if (pro.serverOrder.isEmpty) {
        return Center(
          child: TextButton(
              onPressed: () => AppRoute(
                    const ServerEditPage(),
                    'Add server info page',
                  ).go(context),
              child: Text(
                _s.addAServer,
                style: const TextStyle(fontSize: 27),
              )),
        );
      }
      return PageView.builder(
        controller: _pageController,
        itemCount: pro.servers.length,
        itemBuilder: (_, idx) {
          final id = pro.serverOrder[idx];
          final s = pro.servers[id];
          if (s == null) {
            return placeholder;
          }
          return _buildRealServerCard(s.status, s.state, s.spi);
        },
      );
    });
  }

  Widget _buildRealServerCard(
    ServerStatus ss,
    ServerState cs,
    ServerPrivateInfo spi,
  ) {
    final rootDisk = ss.disk.firstWhere((element) => element.loc == '/');

    return InkWell(
      onTap: () => AppRoute(
        ServerDetailPage(spi.id),
        'server detail page',
      ).go(context),
      child: Stack(
          children: [
            Positioned(top: 0, left: 0, right: 0, child: _buildServerCardTitle(ss, cs, spi)),
            Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
              children: [
            SizedBox(height: _media.size.width * 0.1),
                Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPercentCircle(ss.cpu.usedPercent()),
                _buildPercentCircle(ss.mem.usedPercent * 100),
                _buildIOData(
                    'Conn:\n${ss.tcp.maxConn}', 'Fail:\n${ss.tcp.fail}'),
                _buildIOData(
                  'Total:\n${rootDisk.size}',
                  'Used:\n${rootDisk.usedPercent}%',
                )
              ],
            ),
            SizedBox(height: _media.size.width * 0.1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildExplainText('CPU'),
                _buildExplainText('Mem'),
                _buildExplainText('Net'),
                _buildExplainText('Disk'),
              ],
            ),
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildServerCardTitle(
    ServerStatus ss,
    ServerState cs,
    ServerPrivateInfo spi,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _media.size.width * 0.05),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                spi.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                textScaleFactor: 1.0,
                textAlign: TextAlign.center,
              ),
              const Icon(
                Icons.keyboard_arrow_right,
                size: 21,
                color: Colors.grey,
              )
            ],
          ),
          height13,
          _buildTopRightText(ss, cs),
        ],
      ),
    );
  }

  Widget _buildTopRightText(ServerStatus ss, ServerState cs) {
    final topRightStr = _getTopRightStr(
      cs,
      ss.temps.first,
      ss.uptime,
      ss.failedInfo,
    );
    return Text(
      topRightStr,
      style: textSize12Grey,
      textScaleFactor: 1.0,
    );
  }

  Widget _buildExplainText(String text) {
    return SizedBox(
      width: _media.size.height * 0.2,
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
        textAlign: TextAlign.center,
        textScaleFactor: 1.0,
      ),
    );
  }

  String _getTopRightStr(
    ServerState cs,
    double? temp,
    String upTime,
    String? failedInfo,
  ) {
    switch (cs) {
      case ServerState.disconnected:
        return _s.disconnected;
      case ServerState.connected:
        final tempStr = temp == null ? '' : '${temp.toStringAsFixed(1)}°C';
        final items = [tempStr, upTime];
        final str = items.where((element) => element.isNotEmpty).join(' | ');
        if (str.isEmpty) return _s.serverTabLoading;
        return str;
      case ServerState.connecting:
        return _s.serverTabConnecting;
      case ServerState.failed:
        if (failedInfo == null) {
          return _s.serverTabFailed;
        }
        if (failedInfo.contains('encypted')) {
          return _s.serverTabPlzSave;
        }
        return failedInfo;
      default:
        return _s.serverTabUnkown;
    }
  }

  Widget _buildIOData(String up, String down) {
    final statusTextStyle = TextStyle(
        fontSize: 13, color: _theme.textTheme.bodyLarge!.color!.withAlpha(177));
    return SizedBox(
      width: _media.size.height * 0.23,
      child: Column(
        children: [
          const SizedBox(height: 5),
          Text(
            up,
            style: statusTextStyle,
            textAlign: TextAlign.center,
            textScaleFactor: 1.0,
          ),
          const SizedBox(height: 3),
          Text(
            down,
            style: statusTextStyle,
            textAlign: TextAlign.center,
            textScaleFactor: 1.0,
          )
        ],
      ),
    );
  }

  Widget _buildPercentCircle(double percent) {
    if (percent <= 0) percent = 0.01;
    if (percent >= 100) percent = 99.9;
    return SizedBox(
      width: _media.size.height * 0.23,
      child: Stack(
        children: [
          Center(
            child: CircleChart(
              progressColor: primaryColor,
              progressNumber: percent,
              animationDuration: const Duration(milliseconds: 377),
              maxNumber: 100,
              width: _media.size.width * 0.22,
              height: _media.size.width * 0.22,
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Text(
                '${percent.toStringAsFixed(1)}%',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
                textScaleFactor: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Future<void> afterFirstLayout(BuildContext context) async {
    await GetIt.I.allReady();
    await _serverProvider.loadLocalData();
    await _serverProvider.refreshData();
    await doUpdate(context);
    if (!Analysis.enabled) {
      await Analysis.init();
    }
  }
}