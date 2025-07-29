import 'package:flutter/material.dart';
import 'mobile/add_products_mobile.dart';
import 'mobile/cart_mobile.dart';
import 'mobile/payment_mobile.dart';
import 'mobile/add_client_mobile.dart';

class SaleMobileView extends StatefulWidget {
  const SaleMobileView({Key? key}) : super(key: key);

  @override
  State<SaleMobileView> createState() => _SaleMobileViewState();
}

class _SaleMobileViewState extends State<SaleMobileView> {
  int _step = 0;

  void _goToStep(int step) {
    setState(() {
      _step = step;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (_step) {
      case 0:
        content = AddProductsMobile(onNext: () => _goToStep(1));
        break;
      case 1:
        content = CartMobile(
          onBack: () => _goToStep(0),
          onNext: () => _goToStep(2),
        );
        break;
      case 2:
        content = PaymentMobile(
          onBack: () => _goToStep(1),
          onAddClient: () => _goToStep(3),
        );
        break;
      case 3:
        content = AddClientMobile(
          onBack: () => _goToStep(2),
          onSave: () => _goToStep(2),
        );
        break;
      default:
        content = AddProductsMobile(onNext: () => _goToStep(1));
    }
    return Scaffold(body: SafeArea(child: content));
  }
}
