import 'package:flutter_test/flutter_test.dart';
import 'package:auraday/core/constants/iap_constants.dart';
import 'package:auraday/core/services/iap_config_service.dart';
import 'package:auraday/models/shop_item.dart';

void main() {
  test('Aura Day IAP ids and N319 endpoint', () {
    expect(IapConstants.productPrefix, 'au');
    expect(IapConstants.remoteConfigUrl, 'https://api2.blwsmartware.net/N319.json');
    expect(IapConstants.coinPackIds.first, 'au_pack_1');
    expect(IapConstants.coinPackIds.last, 'au_pack_10');
    expect(IapConstants.coinPackIds, hasLength(10));
    expect(IapConstants.removeAdsProductId, 'au_remove_ads');
    expect(IapConstants.proProductId, 'au_pro');
    expect(IapConstants.allProductIds, containsAll([...IapConstants.coinPackIds, 'au_remove_ads', 'au_pro']));
    expect(IapConstants.coinsForProduct('au_pack_5'), 500);
    expect(IapConstants.freeArchiveLimit, 3);
    expect(IapConstants.proArchiveLimit, 99);
  });

  test('disable=1 hides billing only', () {
    final off = IapRemoteConfig.fromJson({'disable': 1, 'name': 'Aura Day'});
    expect(off.billingDisabled, isTrue);
    final on = IapRemoteConfig.fromJson({'disable': 0, 'name': 'Aura Day', 'code': 'FULL_IAP'});
    expect(on.billingDisabled, isFalse);
    expect(on.name, 'Aura Day');
  });

  test('shop catalog extras can be applied and reverted', () {
    expect(ShopCatalog.items.where((e) => e.id.startsWith('theme_')), isNotEmpty);
    expect(ShopCatalog.find(ShopCatalog.featPro), isNotNull);
    expect(ShopCatalog.find('remove_ads'), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featHint), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featSound), isNotNull);
    expect(ShopCatalog.isDefaultId(ShopCatalog.defaultThemeId), isTrue);
  });
}
