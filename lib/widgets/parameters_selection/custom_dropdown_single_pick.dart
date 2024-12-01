import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:smart/main.dart';
import 'package:smart/services/parameters_parser.dart';
import 'package:smart/utils/fonts.dart';
import 'package:smart/widgets/checkBox/custom_check_box.dart';
import 'package:smart/widgets/parameters_selection/single_pick_with_search.dart';

import '../../utils/colors.dart';

class CustomDropDownSingleCheckBox extends StatefulWidget {
  const CustomDropDownSingleCheckBox({
    super.key,
    required this.parameter,
    required this.onChange,
    required this.currentKey,
    required this.isClickable,
    this.icon,
    this.useLocalizationKeys = false,
  });

  final Function(ParameterOption) onChange;
  final dynamic parameter;
  final String currentKey;
  final String? icon;
  final bool isClickable;

  final bool useLocalizationKeys;

  @override
  State<CustomDropDownSingleCheckBox> createState() => _CustomDropDownSingleCheckBoxState();
}

class _CustomDropDownSingleCheckBoxState extends State<CustomDropDownSingleCheckBox> {
  bool isOpen = true;
  bool showAll = false;

  @override
  Widget build(BuildContext context) {
    final currentLocale = MyApp.getLocale(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      child: Column(children: [
        Material(
          color: Colors.transparent,
          clipBehavior: Clip.hardEdge,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: InkWell(
            onTap: widget.isClickable
                ? () {
                    isOpen = !isOpen;
                    setState(() {});
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.icon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: SvgPicture.asset(
                        widget.icon!,
                        width: 24,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      currentLocale == 'fr' ? widget.parameter.frName : widget.parameter.arName,
                      style: AppTypography.font16black.copyWith(fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isClickable)
                    !isOpen
                        ? const Icon(
                            Icons.arrow_forward_ios_outlined,
                            size: 16,
                            color: AppColors.lightGray,
                          )
                        : const Icon(
                            Icons.keyboard_arrow_down_sharp,
                            color: AppColors.lightGray,
                          )
                ],
              ),
            ),
          ),
        ),
        if (isOpen) ...[
          !showAll
              ? buildSimplePicker()
              : SinglePickWithSearch(
                  parameter: widget.parameter,
                  onChange: (parametrOption) {
                    widget.onChange(parametrOption);
                  },
                )
        ]
      ]),
    );
  }

  Widget buildSimplePicker() {
    int maximum = 0;

    if (widget.parameter.variants.length < 7) {
      maximum = widget.parameter.variants.length;
    } else {
      maximum = 7;
    }

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(left: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...(widget.parameter.variants.sublist(0, maximum))
              .map(
                (parametrOption) => InkWell(
                  onTap: () {
                    setState(() {});
                    widget.onChange(parametrOption);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {});
                        widget.onChange(parametrOption);
                      },
                      child: Row(
                        children: [
                          CustomCheckBox(
                            isActive: parametrOption.key.toString() == widget.currentKey,
                            onChanged: () {
                              setState(() {});
                              widget.onChange(parametrOption);
                            },
                          ),
                          Expanded(
                            child: Text(
                              MyApp.getLocale(context) == 'fr' ? parametrOption.nameFr : parametrOption.nameAr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.font14black.copyWith(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
          if (widget.parameter.variants.length > 7) ...[
            GestureDetector(
              onTap: () {
                setState(() {
                  showAll = true;
                });
              },
              child: Text(
                "${MyApp.getLocale(context) == 'fr' ? 'Afficher tout' : 'عرض الكل'} ${widget.parameter.variants.length}",
                overflow: TextOverflow.ellipsis,
                style: AppTypography.font12lightGray.copyWith(color: AppColors.red),
              ),
            )
          ]
        ],
      ),
    );
  }
}
