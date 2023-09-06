import 'package:flutter/material.dart';
import 'package:smart/utils/fonts.dart';
import 'package:smart/widgets/textField/under_line_text_field.dart';
import '../../utils/colors.dart';

class PriceWidget extends StatelessWidget {

  const PriceWidget({super.key});

  get priseController => null;
  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        height: 70,
        child: Column(children: [
          Row(children: [
            Image.asset('assets/images/Frame.png',width: 24,),
            const SizedBox(width: 12,),
             Text(
                'Prix',
                style: AppTypography.font18gray )]),
          const SizedBox(height: 14,),
          Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children: [
             SizedBox(height:24,
                child: UnderLineTextField(width: double.infinity,
    hintText: '',
    keyBoardType: TextInputType.number,
    suffixIcon: 'DZD',
    controller: priseController,
    onChange: (String value) {  },) ),
            SizedBox(
                 width: 17,
                  child: Text(
                      '—',
                      textAlign: TextAlign.center,
                      style: AppTypography.font18gray.copyWith(fontSize: 16,fontWeight: FontWeight.w400)
                      )),
            ]),
              SizedBox(height:24,
                child:UnderLineTextField(
                  width: double.infinity,
                  hintText: '',
                  keyBoardType: TextInputType.number,
                  suffixIcon: 'DZD',
                  controller: priseController,
                  onChange: (String value) {  },) )])
        ,);
  }
}