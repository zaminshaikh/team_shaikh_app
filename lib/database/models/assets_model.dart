/// Represents an individual asset within a fund.
///
/// Each asset has a display title, an amount, and an optional first deposit date.
class Asset {
  /// The display title of the asset.
  final String displayTitle;

  /// The amount associated with the asset.
  final double amount;

  /// The date of the first deposit, if any.
  final DateTime? firstDepositDate;

  /// Creates an [Asset] instance with the given parameters.
  Asset({
    required this.displayTitle,
    required this.amount,
    this.firstDepositDate,
  });

  /// Creates an [Asset] instance from a [Map] representation.
  factory Asset.fromMap(Map<String, dynamic> data) => Asset(
        displayTitle: data['displayTitle'] as String,
        amount: (data['amount'] as num).toDouble(),
        firstDepositDate: data['firstDepositDate'] as DateTime?,
      );

  /// Converts the [Asset] instance into a [Map] representation.
  Map<String, dynamic> toMap() => {
        'displayTitle': displayTitle,
        'amount': amount,
        'firstDepositDate': firstDepositDate,
      };
}

/// Represents a fund containing multiple assets with variable properties.
///
/// The `Fund` class now contains a map of asset names to their corresponding [Asset] objects.
class Fund {
  /// A map of asset names to their corresponding [Asset] objects.
  final Map<String, Asset> assets;

  final double total;

  final String name;

  /// Creates a [Fund] instance with the given assets.
  Fund({
    required this.assets,
    required this.total,
    required this.name,
  });

  /// Creates a [Fund] instance from a [Map] representation.
  ///
  /// This method parses each asset in the map and constructs [Asset] objects.
  factory Fund.fromMap(Map<String, dynamic> data) {
    final assets = <String, Asset>{};
    String name = '';
    double total = 0.0;
    data.forEach((key, value) {
      if (key == 'total') {
        total = (value as num).toDouble();
      } else if (key == 'fund') {
        name = value as String;
      } else {
        assets[key] = Asset.fromMap(value as Map<String, dynamic>);
      }
    });
    return Fund(assets: assets, total: total, name: name);
  }

  /// Converts the [Fund] instance into a [Map] representation.
  Map<String, dynamic> toMap() => assets.map(
        (key, value) => MapEntry(key, value.toMap()),
      );

  /// Creates an empty [Fund] instance with no assets.
  Fund.empty() : assets = {}, total = 0.0, name = '';
}

/// Represents the assets of a client, including various funds and totals.
///
/// The `Assets` class aggregates all the financial assets of a client, including individual funds
/// and overall totals for year-to-date (YTD) and total assets.
class Assets {
  /// A map of fund names to their corresponding [Fund] objects.
  final Map<String, Fund> funds;

  /// The total year-to-date amount for the client, including their connected users.
  final double? totalYTD;

  /// The year-to-date amount for the client.
  final double? ytd;

  /// The total assets amount for the client.
  final double? totalAssets;

  /// Creates an [Assets] instance with the given parameters.
  ///
  /// The [funds], [ytd], and [totalAssets] parameters are required.
  Assets({
    required this.funds,
    required this.ytd,
    required this.totalAssets,
    this.totalYTD,
  });

  /// Creates an [Assets] instance from a [Map] representation.
  ///
  /// [fundsData] is a map of fund names to their data maps.
  /// [general] contains general information such as totals.
  factory Assets.fromMap(
    Map<String, Fund> funds,
    Map<String, dynamic> general,
  ) => Assets(
      totalYTD: (general['totalYTD'] as num?)?.toDouble(),
      ytd: (general['ytd'] as num?)?.toDouble(),
      totalAssets:
          (general['totalAssets'] ?? general['total'] as num?)?.toDouble(),
      funds: funds,
    );

  /// Creates an empty [Assets] instance with default values.
  Assets.empty()
      : funds = {},
        totalYTD = 0.0,
        ytd = 0.0,
        totalAssets = 0.0;

  /// Converts the [Assets] instance into a [Map] representation.
  Map<String, dynamic> toMap() => {
        'funds': funds.map(
          (key, value) => MapEntry(key, value.toMap()),
        ),
        'totalYTD': totalYTD,
        'ytd': ytd,
        'totalAssets': totalAssets,
      };
}
