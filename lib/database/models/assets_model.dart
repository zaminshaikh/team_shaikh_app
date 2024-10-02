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
  /// [funds] is a map of fund names to [Fund] objects.
  /// [general] contains general information such as totals.
  factory Assets.fromMap(
          Map<String, Fund> funds, Map<String, dynamic> general) =>
      Assets(
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
        'funds': funds.map((key, value) => MapEntry(key, value.toMap())),
        'totalYTD': totalYTD,
        'ytd': ytd,
        'totalAssets': totalAssets,
      };
}

/// Represents an individual fund with various account types.
///
/// The `Fund` class encapsulates the different account types within a fund, such as personal,
/// company, traditional IRA, Roth IRA, SEP IRA, and NuView accounts.
class Fund {
  /// Personal account amount.
  final double personal;

  /// Company account amount.
  final double company;

  /// Traditional IRA account amount.
  final double trad;

  /// Roth IRA account amount.
  final double roth;

  /// SEP IRA account amount.
  final double sep;

  /// NuView Traditional IRA account amount.
  final double nuviewTrad;

  /// NuView Roth IRA account amount.
  final double nuviewRoth;

  /// Total amount across all accounts.
  final double total;

  /// Creates a [Fund] instance with the given parameters.
  Fund({
    required this.personal,
    required this.company,
    required this.trad,
    required this.roth,
    required this.sep,
    required this.nuviewTrad,
    required this.nuviewRoth,
    required this.total,
  });

  /// Creates a [Fund] instance from a [Map] representation.
  ///
  /// Typically used when decoding data from Firestore.
  factory Fund.fromMap(Map<String, dynamic> data) => Fund(
        personal: (data['personal'] as num).toDouble(),
        company: (data['company'] as num).toDouble(),
        trad: (data['trad'] as num).toDouble(),
        roth: (data['roth'] as num).toDouble(),
        sep: (data['sep'] as num).toDouble(),
        nuviewTrad: (data['nuviewTrad'] as num).toDouble(),
        nuviewRoth: (data['nuviewRoth'] as num).toDouble(),
        total: (data['total'] as num).toDouble(),
      );

  /// Creates an empty [Fund] instance with default values.
  Fund.empty()
      : personal = 0.0,
        company = 0.0,
        trad = 0.0,
        roth = 0.0,
        sep = 0.0,
        nuviewTrad = 0.0,
        nuviewRoth = 0.0,
        total = 0.0;

  /// Converts the [Fund] instance into a [Map] representation.
  Map<String, dynamic> toMap() => {
        'personal': personal,
        'company': company,
        'trad': trad,
        'roth': roth,
        'sep': sep,
        'nuviewTrad': nuviewTrad,
        'nuviewRoth': nuviewRoth,
        'total': total,
      };
}
