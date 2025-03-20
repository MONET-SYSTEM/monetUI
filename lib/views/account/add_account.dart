import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monet/controller/account.dart';
import 'package:monet/controller/account_type.dart';
import 'package:monet/controller/currency.dart';
import 'package:monet/models/account_type.dart';
import 'package:monet/models/currency.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_routes.dart';
import 'package:monet/resources/app_spacing.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/utils/helper.dart';
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

  AccountTypeModel? selectedAccountType;
  List<AccountTypeModel> accountTypes = [];

  TextEditingController balance = TextEditingController(text: '0');
  TextEditingController name = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  FocusNode balanceFocus = FocusNode();
  FocusNode nameFocus = FocusNode();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColours.primaryColour,
        appBar: buildAppBar(context, AppStrings.addNewAccount,
            backgroundColor: AppColours.primaryColour,
            foregroundColor: Colors.white),
        body: Form (
          key: _formKey,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSpacing.vertical(size: MediaQuery
                        .of(context)
                        .size
                        .height / 5),
                    Text(AppStrings.balance, style: AppStyles.semibold(
                        color: Colors.white.withOpacity(0.7))),
                    Row(
                      children: [
                        Text(selectedCurrency?.code ?? '',
                            style: AppStyles.semibold(
                                size: 48, color: Colors.white)),
                        AppSpacing.horizontal(size: 8),
                        Expanded(child: TextFormField(
                          enabled: !_isLoading,
                          controller: balance,

                          style: AppStyles.semibold(size: 48, color: Colors
                              .white),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            errorStyle: TextStyle(color: Colors.white)
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          focusNode: balanceFocus,
                          cursorColor: Colors.white,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'))
                          ],
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) {
                            if(value == null || value.isEmpty){
                              return AppStrings.inputIsRequired.replaceAll(":input", AppStrings.balance);
                            }
                            return null;
                          },
                        )),
                      ],
                    )
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(32),
                        topRight: Radius.circular(32))
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      AppSpacing.vertical(size: 16),
                      TextInputComponent(label: AppStrings.name,
                          textEditingController: name, focusNode: nameFocus, isRequired: true, isEnabled: !_isLoading),
                      AppSpacing.vertical(),
                      SelectInputComponent(label: AppStrings.currency,
                          items: currencies,
                          selectedItem: selectedCurrency,
                          onChanged: (CurrencyModel? value) {
                            setState(() => selectedCurrency = value);
                          },
                          compareFn: (item1, item2) => item1.isEqual(item2),
                          showSearchBox: true, isRequired: true, isEnabled: !_isLoading),

                      AppSpacing.vertical(),

                      SelectInputComponent(label: AppStrings.accountType,
                          items: accountTypes,
                          onChanged: (AccountTypeModel? value) {
                            setState(() => selectedAccountType = value);
                          },
                          compareFn: (item1, item2) => item1.isEqual(item2), isRequired: true, isEnabled: !_isLoading),

                      AppSpacing.vertical(),

                      ButtonComponent(
                          label: AppStrings.continueText, onPressed:_handleSubmit, isLoading: _isLoading),

                      AppSpacing.vertical(size: 48),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final initialBalance = Helper.parseInputAmount(balance.text.trim());
    final result = await AccountController.create(initialBalance, name.text.trim(), selectedCurrency?.id ?? '', selectedAccountType?.id ?? '');
    setState(() => _isLoading = false);

    if(!result.isSuccess) {
      Helper.snackBar(context, message: result.message, isSuccess: false);
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.signupSuccess, (Route<dynamic> route) => false);
  }

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  _initScreen(){
    _loadCurrencies();
    _loadAccountTypes();

  }

  _loadCurrencies() async {
    // Load currencies
    final result = await CurrencyController.load();
    if (result.isSuccess && result.results != null) {
      setState(() => currencies = result.results);
    }
  }

  _loadAccountTypes() async {
    // Load account types
    final result = await AccountTypeController.load();
    if (result.isSuccess && result.results != null) {
      setState(() => accountTypes = result.results);
    }
  }

}