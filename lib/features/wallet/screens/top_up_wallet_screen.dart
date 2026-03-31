import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/image_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/loader_widget.dart';
import 'package:ride_sharing_user_app/features/wallet/controllers/wallet_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/screens/digital_payment_screen.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class TopUpWalletScreen extends StatefulWidget {
  const TopUpWalletScreen({super.key});

  @override
  State<TopUpWalletScreen> createState() => _TopUpWalletScreenState();
}

class _TopUpWalletScreenState extends State<TopUpWalletScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _loadingGateways = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGateways());
  }

  Future<void> _loadGateways() async {
    final walletController = Get.find<WalletController>();
    await walletController.getPaymentGetWayList();
    walletController.selectChapaOrFirstGateway();
    if (mounted) {
      setState(() => _loadingGateways = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onPayNow() {
    final walletController = Get.find<WalletController>();
    final raw = _amountController.text.trim();
    final amount = double.tryParse(raw);
    if (raw.isEmpty || amount == null || amount <= 0) {
      showCustomSnackBar('enter_valid_payment_amount'.tr);
      return;
    }
    if (walletController.paymentGateways == null ||
        walletController.paymentGateways!.isEmpty ||
        walletController.paymentGatewayIndex < 0 ||
        walletController.gateWay.isEmpty) {
      showCustomSnackBar('currently_no_payment_method_is_available'.tr);
      return;
    }
    Get.to(() => DigitalPaymentScreen(
          paymentMethod: walletController.gateWay,
          totalAmount: raw,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'top_up_wallet'.tr,
          style: textSemiBold.copyWith(
            color: Theme.of(context).cardColor,
            fontSize: Dimensions.fontSizeLarge,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).cardColor,
        elevation: 0,
      ),
      body: _loadingGateways
          ? const Center(child: LoaderWidget())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: GetBuilder<WalletController>(builder: (walletController) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'payment_amount'.tr,
                      style: textSemiBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: InputDecoration(
                        hintText: 'amount'.tr,
                        hintStyle: textRegular.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                        prefixIcon: Icon(
                          Icons.payments_outlined,
                          color: Theme.of(context).hintColor,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          borderSide: BorderSide(
                            color: Theme.of(context).hintColor.withValues(alpha: 0.35),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          borderSide: BorderSide(
                            color: Theme.of(context).hintColor.withValues(alpha: 0.35),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 1.2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                          vertical: Dimensions.paddingSizeDefault,
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                    Text(
                      'payment_method'.tr,
                      style: textSemiBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    if (walletController.paymentGateways == null ||
                        walletController.paymentGateways!.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        decoration: BoxDecoration(
                          color: Theme.of(context).hintColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                        child: Text(
                          'currently_no_payment_method_is_available'.tr,
                          style: textRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      )
                    else
                      ...List.generate(walletController.paymentGateways!.length, (index) {
                        final g = walletController.paymentGateways![index];
                        final selected = walletController.paymentGatewayIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                          child: InkWell(
                            onTap: () => walletController.setDigitalPaymentType(
                              index,
                              g.gateway ?? '',
                            ),
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeDefault,
                                vertical: Dimensions.paddingSizeSmall,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                border: Border.all(
                                  color: selected
                                      ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                                      : Theme.of(context).hintColor.withValues(alpha: 0.25),
                                ),
                                color: Theme.of(context).cardColor,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: selected
                                        ? Icon(
                                            Icons.radio_button_checked,
                                            color: Theme.of(context).primaryColor,
                                            size: 22,
                                          )
                                        : Icon(
                                            Icons.radio_button_off,
                                            color: Theme.of(context).hintColor,
                                            size: 22,
                                          ),
                                  ),
                                  const SizedBox(width: Dimensions.paddingSizeSmall),
                                  Expanded(
                                    child: Text(
                                      g.gatewayTitle ?? g.gateway ?? '',
                                      style: textMedium.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                      ),
                                    ),
                                  ),
                                  if (g.gatewayImage != null && g.gatewayImage!.isNotEmpty)
                                    ImageWidget(
                                      image:
                                          '${AppConstants.baseUrl}/storage/app/public/payment_modules/gateway_image/${g.gatewayImage}',
                                      height: 28,
                                      width: 28,
                                      fit: BoxFit.contain,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    SizedBox(height: Get.height * 0.06),
                    ButtonWidget(
                      buttonText: 'pay_now'.tr,
                      onPressed: _onPayNow,
                      radius: Dimensions.radiusExtraLarge,
                      height: 52,
                    ),
                  ],
                );
              }),
            ),
    );
  }
}
