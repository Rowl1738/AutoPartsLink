import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A single-series column chart drawn with plain widgets.
///
/// Tap (or hover, on web/desktop) a column to read its exact value; the most
/// recent column is selected by default. Gridlines are recessive and the
/// value axis always starts at zero.
class ColumnChart extends StatefulWidget {
  final List<String> labels;
  final List<double> values;
  final String Function(double value) format;

  /// Shorter format for the value axis; defaults to [format].
  final String Function(double value)? axisFormat;
  final Color color;
  final double height;

  /// Spoken before each column's value, e.g. "Requests".
  final String seriesName;

  const ColumnChart({
    super.key,
    required this.labels,
    required this.values,
    required this.format,
    required this.seriesName,
    this.axisFormat,
    this.color = AppColors.primary,
    this.height = 180,
  }) : assert(labels.length == values.length);

  @override
  State<ColumnChart> createState() => _ColumnChartState();
}

class _ColumnChartState extends State<ColumnChart> {
  late int _selected = widget.values.length - 1;

  @override
  void didUpdateWidget(covariant ColumnChart old) {
    super.didUpdateWidget(old);
    if (_selected >= widget.values.length) _selected = widget.values.length - 1;
  }

  /// Rounds [max] up to a 1/2/2.5/5 × 10ⁿ step so the gridlines land on round numbers.
  static double _niceMax(double max) {
    if (max <= 0) return 1;
    final magnitude = math.pow(10, (math.log(max) / math.ln10).floor()).toDouble();
    for (final step in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (step * magnitude >= max) return step * magnitude;
    }
    return 10 * magnitude;
  }

  @override
  Widget build(BuildContext context) {
    final maxValue = widget.values.fold<double>(0, math.max);
    final top = _niceMax(maxValue);
    const labelStyle = TextStyle(fontSize: 11, color: AppColors.textSecondary);
    const valueLabelHeight = 20.0;
    const axisWidth = 44.0;

    return SizedBox(
      height: widget.height + 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Value axis: 0, half and top, aligned with the gridlines.
          SizedBox(
            width: axisWidth,
            height: widget.height,
            child: Padding(
              padding: const EdgeInsets.only(top: valueLabelHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final v in [top, top / 2, 0.0])
                    Transform.translate(
                      offset: const Offset(-6, 0),
                      child: FractionalTranslation(
                        translation: Offset(0, v == top ? -0.5 : (v == 0 ? 0.5 : 0)),
                        child: Text((widget.axisFormat ?? widget.format)(v), style: labelStyle, maxLines: 1),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: widget.height,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        top: valueLabelHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (var i = 0; i < 3; i++)
                              Container(height: 1, color: i == 2 ? AppColors.textSecondary.withValues(alpha: 0.35) : AppColors.border),
                          ],
                        ),
                      ),
                      Positioned.fill(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < widget.values.length; i++)
                              Expanded(child: _column(i, top, valueLabelHeight)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (var i = 0; i < widget.labels.length; i++)
                      Expanded(
                        child: Text(
                          widget.labels[i],
                          textAlign: TextAlign.center,
                          style: labelStyle.copyWith(
                            fontWeight: i == _selected ? FontWeight.w700 : FontWeight.w400,
                            color: i == _selected ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _column(int i, double top, double valueLabelHeight) {
    final value = widget.values[i];
    final selected = i == _selected;
    final plotHeight = widget.height - valueLabelHeight;
    // Non-zero values always get a visible sliver so "1" never looks like "0".
    final barHeight = value <= 0 ? 0.0 : math.max(3.0, plotHeight * value / top);

    return Semantics(
      button: true,
      selected: selected,
      label: "${widget.labels[i]}: ${widget.seriesName} ${widget.format(value)}",
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _selected = i),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque, // the whole column slot is the hit target
          onTap: () => setState(() => _selected = i),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: valueLabelHeight,
                child: selected
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(widget.format(value),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      )
                    : null,
              ),
              LayoutBuilder(
                builder: (context, constraints) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  height: barHeight,
                  width: math.min(constraints.maxWidth * 0.6, 32),
                  decoration: BoxDecoration(
                    color: selected ? widget.color : widget.color.withValues(alpha: 0.72),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
