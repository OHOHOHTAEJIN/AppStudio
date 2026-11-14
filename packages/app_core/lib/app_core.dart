import 'package:flutter/material.dart';

class StudioApp extends StatelessWidget {
  const StudioApp({super.key, required this.title, required this.accent, required this.home});
  final String title;
  final Color accent;
  final Widget home;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: title,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B1020),
      colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark)),
    home: home,
  );
}

class StudioScreen extends StatelessWidget {
  const StudioScreen({super.key, required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
    body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final maxWidth = width >= 840 ? 1080.0 : width >= 600 ? 760.0 : 560.0;
      return SingleChildScrollView(child: Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: EdgeInsets.symmetric(horizontal: width < 360 ? 12 : 20, vertical: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(subtitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
            const SizedBox(height: 18), child, const SizedBox(height: 30),
          ])),
      )));
    })),
  );
}

class StudioCard extends StatelessWidget {
  const StudioCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(clipBehavior: Clip.antiAlias,
    child: Padding(padding: const EdgeInsets.all(18), child: child));
}

class StatBox extends StatelessWidget {
  const StatBox({super.key, required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => StudioCard(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
    ]));
}

class AdaptiveStatGrid extends StatelessWidget {
  const AdaptiveStatGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final columns = constraints.maxWidth >= 680 ? 4 : 2;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true, itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8, mainAxisSpacing: 8,
        mainAxisExtent: constraints.maxWidth < 360 ? 132 : 120,
      ),
      itemBuilder: (context, i) => children[i],
    );
  });
}
