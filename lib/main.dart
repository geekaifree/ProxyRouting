import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const ProxyRoutingApp());
class ProxyRoutingApp extends StatelessWidget {
  const ProxyRoutingApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(title: '代理分流', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true, brightness: Brightness.dark),
    home: const ProxyHomePage());
}

class ProxyRule {
  String id, name, domain, proxy, mode;
  bool enabled;
  ProxyRule({required this.id, required this.name, required this.domain, required this.proxy, this.mode = 'direct', this.enabled = true});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'domain': domain, 'proxy': proxy, 'mode': mode, 'enabled': enabled};
  factory ProxyRule.fromJson(Map<String, dynamic> j) => ProxyRule(id: j['id'], name: j['name'], domain: j['domain'], proxy: j['proxy'] ?? '', mode: j['mode'] ?? 'direct', enabled: j['enabled'] ?? true);
}

class ProxyHomePage extends StatefulWidget {
  const ProxyHomePage({super.key});
  @override
  State<ProxyHomePage> createState() => _ProxyHomePageState();
}

class _ProxyHomePageState extends State<ProxyHomePage> {
  List<ProxyRule> _rules = [];
  bool _globalProxy = false;
  String _globalMode = '规则模式';
  int _upTraffic = 0, _downTraffic = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final d = p.getString('proxy_rules');
    if (d != null) { setState(() => _rules = (json.decode(d) as List).map((e) => ProxyRule.fromJson(e)).toList()); }
    else { _rules = [
      ProxyRule(id: '1', name: 'Google', domain: '*.google.com', proxy: 'SOCKS5 127.0.0.1:1080', mode: 'proxy', enabled: true),
      ProxyRule(id: '2', name: 'GitHub', domain: 'github.com', proxy: 'SOCKS5 127.0.0.1:1080', mode: 'proxy', enabled: true),
      ProxyRule(id: '3', name: '国内网站', domain: '*.cn', proxy: '', mode: 'direct', enabled: true),
      ProxyRule(id: '4', name: 'YouTube', domain: '*.youtube.com', proxy: 'SOCKS5 127.0.0.1:1080', mode: 'proxy', enabled: true),
    ]; _save(); }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('proxy_rules', json.encode(_rules.map((e) => e.toJson()).toList()));
  }

  void _addRule() {
    final nameC = TextEditingController(), domainC = TextEditingController(), proxyC = TextEditingController();
    String mode = 'proxy';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: const Text('添加规则'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, decoration: const InputDecoration(labelText: '规则名称', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: domainC, decoration: const InputDecoration(labelText: '域名/通配符', border: OutlineInputBorder(), hintText: '*.example.com')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: mode, decoration: const InputDecoration(labelText: '模式', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'direct', child: Text('直连')), DropdownMenuItem(value: 'proxy', child: Text('代理')), DropdownMenuItem(value: 'block', child: Text('阻止'))], onChanged: (v) => setS(() => mode = v!)),
        if (mode == 'proxy') ...[const SizedBox(height: 12), TextField(controller: proxyC, decoration: const InputDecoration(labelText: '代理地址', border: OutlineInputBorder(), hintText: 'SOCKS5 127.0.0.1:1080'))],
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), FilledButton(onPressed: () { if (nameC.text.isNotEmpty) { setState(() => _rules.add(ProxyRule(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameC.text, domain: domainC.text, proxy: proxyC.text, mode: mode))); _save(); } Navigator.pop(ctx); }, child: const Text('添加'))],
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔀 代理分流'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.add), onPressed: _addRule)]),
      body: Column(children: [
        Card(margin: const EdgeInsets.all(12), child: SwitchListTile(title: const Text('启用代理', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(_globalMode), value: _globalProxy, onChanged: (v) => setState(() => _globalProxy = v), secondary: Icon(_globalProxy ? Icons.shield : Icons.shield_outlined, color: _globalProxy ? Colors.green : Colors.grey))),
        Expanded(child: _rules.isEmpty ? const Center(child: Text('点击 + 添加规则')) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: _rules.length, itemBuilder: (ctx, i) {
          final r = _rules[i];
          final modeIcon = r.mode == 'proxy' ? Icons.cloud : r.mode == 'direct' ? Icons.link : Icons.block;
          final modeColor = r.mode == 'proxy' ? Colors.blue : r.mode == 'direct' ? Colors.green : Colors.red;
          return Card(margin: const EdgeInsets.only(bottom: 8), child: SwitchListTile(
            secondary: Icon(modeIcon, color: modeColor),
            title: Text(r.name, style: TextStyle(fontWeight: FontWeight.bold, color: r.enabled ? null : Colors.grey)),
            subtitle: Text(r.domain, style: const TextStyle(fontSize: 12)),
            value: r.enabled, onChanged: (v) { setState(() => r.enabled = v); _save(); },
          ));
        })),
      ]),
    );
  }
}
