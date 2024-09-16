class Assets {
  final Map<String, Fund> funds;
  final double? totalYTD;
  final double? ytd;
  final double? totalAssets;

  Assets({
    required this.funds,
    required this.ytd,
    required this.totalAssets,
    this.totalYTD,
  });

  factory Assets.fromMap(Map<String, Fund> funds, Map<String, dynamic> general) => Assets(
        totalYTD: (general['totalYTD'] as num?)?.toDouble(),
        ytd: (general['ytd'] as num?)?.toDouble(),
        totalAssets: (general['totalAssets'] ?? general['total'] as num?)?.toDouble(),
        funds: funds,
      );

  // Empty constructor for Assets
  Assets.empty()
      : funds = {},
        totalYTD = 0.0,
        ytd = 0.0,
        totalAssets = 0.0;

  Map<String, dynamic> toMap() => {
        'funds': funds.map((key, value) => MapEntry(key, value.toMap())),
        'totalYTD': totalYTD,
        'ytd': ytd,
        'totalAssets': totalAssets,
      };
}

class Fund {
  final double personal;
  final double company;
  final double trad;
  final double roth;
  final double sep;
  final double nuviewTrad;
  final double nuviewRoth;
  final double total;

  Fund({
    required this.personal,
    required this.company,
    required this.trad,
    required this.roth,
    required this.sep,
    required this.nuviewTrad,
    required this.nuviewRoth,
    required this.total
  });

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

  // Empty constructor for Fund
  Fund.empty()
      : personal = 0.0,
        company = 0.0,
        trad = 0.0,
        roth = 0.0,
        sep = 0.0,
        nuviewTrad = 0.0,
        nuviewRoth = 0.0,
        total = 0.0;

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