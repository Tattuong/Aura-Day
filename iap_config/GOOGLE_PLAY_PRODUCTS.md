# Google Play IAP — Aura Day

Package: `com.AuraDayMNG.AuraDay`

Remote config: `https://api2.blwsmartware.net/N319.json`  
If JSON field `disable` is `1`, hide Google Play purchase popups. Shop stays open for coin unlocks.

## Consumable coin packs (buy many times)

| Product ID | Coins |
| --- | --- |
| `au_pack_1` | 50 |
| `au_pack_2` | 100 |
| `au_pack_3` | 200 |
| `au_pack_4` | 350 |
| `au_pack_5` | 500 |
| `au_pack_6` | 750 |
| `au_pack_7` | 1000 |
| `au_pack_8` | 1500 |
| `au_pack_9` | 2200 |
| `au_pack_10` | 3000 |

## One-time

| Product ID | Unlock |
| --- | --- |
| `au_remove_ads` | Hide the banner |
| `au_pro` | More than 3 habits |

Create these IDs in Play Console → Monetize → In-app products. Coin packs must be **consumable**. Remove ads and Pro must be **non-consumable**.
