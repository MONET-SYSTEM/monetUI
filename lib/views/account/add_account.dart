import 'package:flutter/material.dart';
import 'package:monet/controller/currency.dart';
import 'package:monet/models/currency.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_routes.dart';
import 'package:monet/resources/app_spacing.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/views/components/form/select_input.dart';
import 'package:monet/views/components/form/text_signup.dart';
import 'package:monet/views/components/ui/app_bar.dart';
import 'package:monet/views/components/ui/button.dart';


class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  CurrencyModel? selectedCurrency;
  List<CurrencyModel> currencies = [];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColours.primaryColour,
        appBar: buildAppBar(context, AppStrings.addNewAccount,
            backgroundColor: AppColours.primaryColour,
            foregroundColor: Colors.white),
        body: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSpacing.vertical(size: MediaQuery.of(context).size.height / 5),
                  Text(AppStrings.balance, style: AppStyles.semibold(color: Colors.white.withOpacity(0.7))),
                  Row(
                    children: [
                      Text(selectedCurrency?.code ?? '', style: AppStyles.semibold(size: 48, color: Colors.white)),
                      AppSpacing.horizontal(size: 8),
                      Expanded(child: TextFormField(
                        controller: TextEditingController(text: '0.00'),
                        style: AppStyles.semibold(size: 48, color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        cursorColor: Colors.white,
                      )),
                    ],
                  )
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    AppSpacing.vertical(size: 16),
                    TextInputComponent(label: AppStrings.appName, textEditingController: TextEditingController()),
                    AppSpacing.vertical(),
                    SelectInputComponent(label: AppStrings.currency, items: currencies, selectedItem: selectedCurrency, onChanged: (CurrencyModel? value) {
                      setState(() => selectedCurrency = value);
                    }, compareFn: (item1, item2) => item1.isEqual(item2)),
                    AppSpacing.vertical(),
                    SelectInputComponent(label: AppStrings.accountType, items: ["Savings", "Current"], onChanged: (String? value) {
                      print(value);
                    }),
                    AppSpacing.vertical(),
                    ButtonComponent(label: AppStrings.continueText, onPressed: (){
                      Navigator.of(context).pushNamed(AppRoutes.signupSuccess);
                    }),
                    AppSpacing.vertical(size: 48),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  _initScreen() async {
    // Load currencies
    final result = await CurrencyController.load();
    if(result.isSuccess && result.results != null) {
      setState(() => currencies = result.results);
    }
  }
 }