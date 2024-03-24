import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart/localization/app_localizations.dart';
import 'package:smart/utils/price_type.dart';
import 'package:smart/utils/routes/route_names.dart';
import 'package:smart/widgets/parameters_selection/input_parameter_widget.dart';
import 'package:smart/widgets/parameters_selection/select_parameter_widget.dart';
import '../../../managers/creating_announcement_manager.dart';
import '../../../models/item/item.dart';
import '../../../utils/colors.dart';
import '../../../utils/fonts.dart';
import '../../../widgets/button/custom_text_button.dart';
import '../../../widgets/textField/under_line_text_field.dart';

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({super.key});

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  final priceController = TextEditingController(text: '0');
  final _formKey = GlobalKey<FormState>();
  bool buttonActive = true;

  late final List<PriceType> _availableTypes;
  late PriceType _priceType;
  List<Parameter> _parametersList = [];

  @override
  void initState() {
    super.initState();
    final repository =
        RepositoryProvider.of<CreatingAnnouncementManager>(context);
    _availableTypes = PriceTypeExtendion.availableTypesFor(
        repository.creatingData.subcategoryId ?? '');
    _priceType = _availableTypes.first;
    _parametersList = repository.getParametersList();
  }

  @override
  Widget build(BuildContext context) {
    final repository =
        RepositoryProvider.of<CreatingAnnouncementManager>(context);

    final localizations = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          iconTheme: const IconThemeData.fallback(),
          backgroundColor: AppColors.empty,
          elevation: 0,
          title: Text(
            AppLocalizations.of(context)!.features,
            style: AppTypography.font20black,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 16,
                ),
                Text(
                  AppLocalizations.of(context)!.price,
                  style: AppTypography.font16black.copyWith(fontSize: 18),
                ),
                UnderLineTextField(
                  width: double.infinity,
                  hintText: '',
                  controller: priceController,
                  keyBoardType: TextInputType.number,
                  priceType: _priceType,
                  availableTypes: _availableTypes,
                  onChangePriceType: (priceType) {
                    setState(() {
                      _priceType = priceType;
                    });
                  },
                  validator: (value) {
                    double? n;
                    try {
                      n = double.parse(priceController.text);
                    } catch (e) {
                      n = -1;
                    }
                    if (n < 0) {
                      buttonActive = false;
                      return localizations.errorReviewOrEnterOther;
                    }
                    buttonActive = true;
                    return null;
                  },
                  onChange: (String value) {
                    setState(() {
                      _formKey.currentState!.validate();
                    });
                  },
                  onEditingComplete: () {
                    setState(() {
                      priceController.text =
                          double.parse(priceController.text).toString();
                    });
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                  onTapOutside: (e) {
                    setState(() {
                      priceController.text =
                          double.parse(priceController.text).toString();
                    });
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  child: Column(
                    children:
                        _parametersList.map((e) => buildParameter(e)).toList() +
                            [const SizedBox(height: 120)],
                    // children: (repository.currentItem != null
                    //             ? repository.getParametersList()
                    //             : <Parameter>[])
                    //         .map((e) => buildParameter(e))
                    //         .toList() +
                    //     [const SizedBox(height: 120)],
                  ),
                )
              ],
            ),
          ),
        ),
        floatingActionButton: CustomTextButton.orangeContinue(
          width: MediaQuery.of(context).size.width - 30,
          text: localizations.continue_,
          callback: () {
            if (buttonActive) {
              repository.setPrice(
                  _priceType.fromPriceString(priceController.text) ?? 0);

              repository.setPriceType(_priceType);
              repository.setInfoFormItem();
              Navigator.pushNamed(
                context,
                AppRoutesNames.announcementCreatingPlace,
              );
            }
          },
          active: buttonActive,
        ),
      ),
    );
  }

  Widget buildParameter(Parameter parameter) {
    if (parameter is SelectParameter) {
      return SelectParameterWidget(parameter: parameter);
    } else if (parameter is InputParameter) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: InputParameterWidget(parameter: parameter),
      );
    } else {
      return Container();
    }
  }
}
