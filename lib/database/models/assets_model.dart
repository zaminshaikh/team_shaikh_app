class Assets {
  final AssetDetails agq;
  final AssetDetails ak1;

  Assets({
    required this.agq,
    required this.ak1,
  });

  factory Assets.fromMap(Map<String, dynamic> data) => Assets(
        agq: AssetDetails.fromMap(data['agq']),
        ak1: AssetDetails.fromMap(data['ak1']),
      );

  // Empty constructor for Assets
  Assets.empty()
      : agq = AssetDetails.empty(),
        ak1 = AssetDetails.empty();

  Map<String, dynamic> toMap() => {
        'agq': agq.toMap(),
        'ak1': ak1.toMap(),
      };
}

class AssetDetails {
  final double personal;
  final double company;
  final double trad;
  final double roth;
  final double sep;
  final double nuviewTrad;
  final double nuviewRoth;

  AssetDetails({
    required this.personal,
    required this.company,
    required this.trad,
    required this.roth,
    required this.sep,
    required this.nuviewTrad,
    required this.nuviewRoth,
  });

  factory AssetDetails.fromMap(Map<String, dynamic> data) => AssetDetails(
        personal: data['personal'],
        company: data['company'],
        trad: data['trad'],
        roth: data['roth'],
        sep: data['sep'],
        nuviewTrad: data['nuviewTrad'],
        nuviewRoth: data['nuviewRoth'],
      );

  // Empty constructor for AssetDetails
  AssetDetails.empty()
      : personal = 0.0,
        company = 0.0,
        trad = 0.0,
        roth = 0.0,
        sep = 0.0,
        nuviewTrad = 0.0,
        nuviewRoth = 0.0;

  Map<String, dynamic> toMap() => {
        'personal': personal,
        'company': company,
        'trad': trad,
        'roth': roth,
        'sep': sep,
        'nuviewTrad': nuviewTrad,
        'nuviewRoth': nuviewRoth,
      };
}
