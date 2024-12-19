import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shopify_flutter/shopify_flutter.dart';
import 'package:shopify_test_app/constants.dart';

import 'checkout_webview.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isLoading = false;
  List<LineItem> cartItems = [];

  Future<void> testCheckoutProcess() async {
    final shopifyStore = ShopifyStore.instance;
    final shopifyAuth = ShopifyAuth.instance;
    // ignore: deprecated_member_use
    final shopifyCheckout = ShopifyCheckout.instance;

    try {
      setState(() => _isLoading = true);
      await shopifyAuth.signInWithEmailAndPassword(
          email: kUserEmail, password: kUserPassword);

      final bestSellingProducts = await shopifyStore.getNProducts(
        10,
        sortKey: SortKeyProduct.BEST_SELLING,
      );
      if (bestSellingProducts == null) {
        throw Exception('No best selling products found');
      }

      var items = List<LineItem>.empty(growable: true);
      items.add(LineItem(
          quantity: 1,
          variantId: bestSellingProducts[0].productVariants[0].id,
          title: bestSellingProducts[0].title,
          id: bestSellingProducts[0].id));

      var address = Address(
        address1: '11 Hinkler Avenue',
        city: 'Sydney',
        country: 'Australia',
        countryCode: 'AU',
        firstName: 'Anderson',
        lastName: 'Fetter',
        phone: '044444444',
        zip: '2229',
      );

      Checkout checkout = await shopifyCheckout.createCheckout(
        lineItems: items,
        shippingAddress: address,
        email: kUserEmail,
      );
      setState(() => _isLoading = false);
      if (!mounted) return;
      final status = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WebViewCheckout(checkoutUrl: checkout.webUrl!),
        ),
      );
      if (status != null && status) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('Checkout Success'),
            ),
          );
      }
    } on Exception catch (e) {
      log('error: $e');
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('$e')),
        );
    }
  }

  Future<void> testCheckoutCompleteWithTokenizedPaymentV3() async {
    final shopifyStore = ShopifyStore.instance;
    final shopifyAuth = ShopifyAuth.instance;
    // ignore: deprecated_member_use
    final shopifyCheckout = ShopifyCheckout.instance;

    try {
      setState(() => _isLoading = true);
      await shopifyAuth.signInWithEmailAndPassword(
          email: kUserEmail, password: kUserPassword);

      final bestSellingProducts = await shopifyStore.getNProducts(
        10,
        sortKey: SortKeyProduct.BEST_SELLING,
      );
      if (bestSellingProducts == null) {
        throw Exception('No best selling products found');
      }

      var items = List<LineItem>.empty(growable: true);

      final product = bestSellingProducts.first;

      items.add(LineItem(
        quantity: 1,
        variantId: product.productVariants.first.id,
        title: product.title,
        id: product.id,
      ));

      var address = Address(
        address1: '11 Hinkler Avenue',
        city: 'Sydney',
        country: 'Australia',
        countryCode: 'AU',
        firstName: 'Anderson',
        lastName: 'Fetter',
        phone: '044444444',
        zip: '2229',
      );

      Checkout checkout = await shopifyCheckout.createCheckout(
        lineItems: items,
        shippingAddress: address,
        email: kUserEmail,
      );

      /// add line items to current checkout
      // checkout = await shopifyCheckout.addLineItemsToCheckout(
      //   lineItems: items,
      //   checkoutId: checkout.id,
      // );

      /// update line items to current checkout
      ///
      /// updates the lineitems of provided id's quantity to 2
      // checkout = await shopifyCheckout.updateLineItemsInCheckout(
      //   lineItems: [
      //     LineItem(
      //       quantity: 2,
      //       variantId: bestSellingProducts[0].productVariants[0].id,
      //       title: bestSellingProducts[0].title,
      //       id: bestSellingProducts[0].id,
      //     ),
      //   ],
      //   checkoutId: checkout.id,
      // );

      /// remove line items from current checkout
      ///
      /// removes the lineitems of provided id
      // checkout = await shopifyCheckout.removeLineItemsFromCheckout(
      //   lineItems: [
      //     LineItem(
      //       quantity: 1,
      //       variantId: bestSellingProducts[0].productVariants[0].id,
      //       title: bestSellingProducts[0].title,
      //       id: bestSellingProducts[0].id,
      //     ),
      //   ],
      //   checkoutId: checkout.id,
      // );

      final idempotencyKey = UniqueKey().toString();
      await shopifyCheckout.shippingAddressUpdate(checkout.id, address);
      final tokanizedCheckout =
          await shopifyCheckout.checkoutCompleteWithTokenizedPaymentV3(
        checkout.id,
        checkout: checkout,
        token: r'CQ32pyIRCmIEfekpX8x=',
        paymentTokenType: PaymentTokenType.SHOPIFY_PAY,
        idempotencyKey: idempotencyKey,
        amount: '${product.price}',
        currencyCode: product.currencyCode,
        billingAddress: address,
      );
      setState(() => _isLoading = false);
      log('tokanizedCheckout: $tokanizedCheckout');
      if (tokanizedCheckout.errorMessage != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(tokanizedCheckout.errorMessage!)),
          );
        return;
      }
      if (tokanizedCheckout.ready && tokanizedCheckout.nextActionUrl != null) {
        if (!mounted) return;
        final status = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WebViewCheckout(checkoutUrl: checkout.webUrl!),
          ),
        );
        if (status != null && status) {
          if (!mounted) return;
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              const SnackBar(
                content: Text('Checkout Success'),
              ),
            );
        }
      }
    } on Exception catch (e) {
      setState(() => _isLoading = false);
      log('error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Checkout'),
            Text(
              'Depreciated in version 2024-07. Use ShopifyCart instead',
              style: Theme.of(context).textTheme.bodySmall,
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                cartItems = [];
                _isLoading = false;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Checkout Process'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: testCheckoutProcess,
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Checkout Complete With Tokenized Payment V3'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: testCheckoutCompleteWithTokenizedPaymentV3,
          ),
          if (cartItems.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return ListTile(
                    title: Text("${item.variant?.product?.title}"),
                    subtitle: Text('Quantity: ${item.quantity}'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
