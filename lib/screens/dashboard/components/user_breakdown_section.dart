import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:team_shaikh_app/database/models/assets_model.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/screens/dashboard/components/asset_tile.dart';
import 'package:team_shaikh_app/screens/dashboard/utils/dashboard_helper.dart';
import 'package:team_shaikh_app/screens/utils/utilities.dart';

// ignore: must_be_immutable
class UserBreakdownSection extends StatelessWidget {

  final Client client;
  bool isConnectedUser;
  
  UserBreakdownSection({Key? key, required this.client, this.isConnectedUser = false}) : super(key: key);

  @override
  Widget build(BuildContext context)  {

    // Initialize empty lists for the tiles
    List<AssetTile> assetTilesAGQ = [];
    List<AssetTile> assetTilesAK1 = [];
    for (var fundEntry in client.assets!.funds.entries) {
      String fundName = fundEntry.key;
      Fund fund = fundEntry.value;

      for (var entry in fund.assets.entries) {
        final key = entry.key;
        final asset = entry.value;

        if (asset.amount != 0) {
          switch (fundName.toUpperCase()) {
            case 'AGQ':
              assetTilesAGQ.add(AssetTile(
                  asset: fund.assets[key]!, fund: FundName.AGQ,
                  companyName: client.companyName));
              break;
            case 'AK1':
              assetTilesAK1.add(AssetTile(
                  asset: fund.assets[key]!, fund: FundName.AK1,
                  companyName: client.companyName));
              break;
            default:
              break;
          }
        }
      }
    }

    // Sort tiles in order specified in _getAssetTileIndex
    assetTilesAGQ.sort((a, b) => getAssetTileIndex(a.title,
            companyName: client.companyName)
        .compareTo(getAssetTileIndex((b.title),
            companyName: client.companyName)));
    assetTilesAK1.sort((a, b) => getAssetTileIndex((a.title),
            companyName: client.companyName)
        .compareTo(getAssetTileIndex((b.title),
            companyName: client.companyName)));

    return Theme(
      data: ThemeData(
        splashColor: Colors.transparent, // removes splash effect
      ),
      child: Container(
        color: const Color.fromARGB(255, 17, 24, 39),
        child: ExpansionTile(
          title: Row(
            children: [
              Text(
                '${client.firstName} ${client.lastName}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                ),
              ),
              const SizedBox(width: 10),
              SvgPicture.asset(
                'assets/icons/YTD.svg',
                height: 13,
              ),
              const SizedBox(width: 5),
              Text(
                currencyFormat(client.assets?.ytd ?? 0),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ],
          ),
          subtitle: Text(
            currencyFormat(client.assets?.totalAssets ?? 0),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: Colors.white,
              fontFamily: 'Titillium Web',
            ),
          ),
          maintainState: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: isConnectedUser ? const BorderSide(color: Colors.white) : BorderSide.none,
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: isConnectedUser ? const BorderSide(color: Colors.white) : BorderSide.none,
          ),
          collapsedBackgroundColor: isConnectedUser ? Colors.transparent : const Color.fromARGB(255, 30, 41, 59),
          backgroundColor: isConnectedUser ? Colors.transparent : const Color.fromARGB(255, 30, 41, 59),
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  left: 25.0, right: 25.0, bottom: 10.0, top: 10.0),
              child: Divider(color: Colors.grey[300]),
            ),
            Column(
              children: assetTilesAK1,
            ),
            Column(
              children: assetTilesAGQ,
            ),
          ],
        ),
      ),
    );
  }


}