import 'package:flutter/material.dart';

/// Shared responsive design system for the four standalone AppStudio apps.
class StudioApp extends StatelessWidget {
  const StudioApp({
    super.key,
    required this.title,
    required this.accent,
    required this.home,
  });

  final String title;
  final Color accent;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    final palette = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      surface: const Color(0xFF141B2D),
    );
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: palette,
        scaffoldBackgroundColor: const Color(0xFF090F1D),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF090F1D),
          centerTitle: false,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF172036),
          surfaceTintColor: Colors.transparent,
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF273149), width: .8),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1D2940),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      home: home,
    );
  }
}

class StudioScreen extends StatelessWidget {
  const StudioScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions,
  });
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          actions: actions,
        ),
        body: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            final maxWidth = width >= 840 ? 1000.0 : width >= 600 ? 760.0 : 560.0;
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(width < 360 ? 12 : 18, 12,
                        width < 360 ? 12 : 18, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFFAAB6CC), height: 1.5)),
                        const SizedBox(height: 18),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
}

class StudioHero extends StatelessWidget {
  const StudioHero({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: .34), const Color(0xFF17233A)],
        ),
        border: Border.all(color: accent.withValues(alpha: .27)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .25),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, size: 27, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(description, style: const TextStyle(
                  color: Color(0xFFD4D9E5), fontSize: 13, height: 1.4)),
            ],
          )),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class StudioCard extends StatelessWidget {
  const StudioCard({super.key, required this.child, this.padding = 18});
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) =>
      Card(child: Padding(padding: EdgeInsets.all(padding), child: child));
}

class StudioSectionTitle extends StatelessWidget {
  const StudioSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(subtitle!, style: const TextStyle(
                      fontSize: 12, color: Color(0xFFA7B3C9))),
                ),
            ],
          )),
          if (trailing != null) trailing!,
        ]),
      );
}

class StudioNotice extends StatelessWidget {
  const StudioNotice({super.key, required this.message, this.icon = Icons.info_outline});
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2940),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: const Color(0xFF9BB5DC)),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
              style: const TextStyle(color: Color(0xFFC4CDE0), height: 1.45))),
        ]),
      );
}

class StatBox extends StatelessWidget {
  const StatBox({super.key, required this.label, required this.value, this.icon});
  final String label;
  final String value;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => StudioCard(
        padding: 14,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 5),
            ],
            Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFA7B3C9), fontSize: 12))),
          ]),
          const SizedBox(height: 8),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(
                fontSize: 23, fontWeight: FontWeight.w800))),
        ]),
      );
}

class AdaptiveStatGrid extends StatelessWidget {
  const AdaptiveStatGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 4 : 2;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            mainAxisExtent: constraints.maxWidth < 360 ? 108 : 94,
          ),
          itemBuilder: (context, i) => children[i],
        );
      });
}
