import 'package:flutter/material.dart';
import 'package:smart/widgets/parameters_selection/custom_dropdown_single_pick.dart';

class SelectParameterWidget extends StatefulWidget {
  const SelectParameterWidget({
    super.key,
    required this.parameter,
    required this.onChange,
    this.isClickable = true,
  });
  final dynamic parameter;
  final bool isClickable;
  final Function onChange;

  @override
  State<SelectParameterWidget> createState() => _SelectParameterWidgetState();
}

class _SelectParameterWidgetState extends State<SelectParameterWidget> {
  @override
  Widget build(BuildContext context) {
    return CustomDropDownSingleCheckBox(
      parameter: widget.parameter,
      isClickable: widget.isClickable,
      onChange: (dynamic value) {
        widget.parameter.setVariant(value!);
        setState(() {});
        widget.onChange();
      },
      currentKey: widget.parameter.currentValue.key,
    );
  }
}
