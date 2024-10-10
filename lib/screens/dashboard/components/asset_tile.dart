
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:team_shaikh_app/screens/utils/utilities.dart';

// ignore: constant_identifier_names
enum FundName { AGQ, AK1 }

// ignore: must_be_immutable
class AssetTile extends StatelessWidget {

  final String fieldName;
  final double amount;
  final FundName fund;
  final String? companyName;
  String title = '';

  AssetTile({super.key, required this.fieldName, required this.amount, required this.fund, this.companyName});

  @override
  Widget build(BuildContext context) {

    String sectionName = getSectionName(fieldName);
    title = sectionName;
    Widget fundIcon = getFundIcon(fund);

    return ListTile(
      leading: fundIcon,
      title: Text(
        sectionName,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: 'Titillium Web',
        ),
      ),
      trailing: Text(
        currencyFormat(amount),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontFamily: 'Titillium Web',
        ),
      ),
    );
  }


  String getSectionName(String fieldName) {
    switch (fieldName) {
      case 'nuviewTrad':
        return 'Nuview Cash IRA';
      case 'nuviewRoth':
        return 'Nuview Cash Roth IRA';
      case 'nuviewSepIRA':
        return 'Nuview Cash SEP IRA';
      case 'roth':
        return 'Roth IRA';
      case 'trad':
        return 'Traditional IRA';
      case 'sep':
        return 'SEP IRA';
      case 'personal':
        return 'Personal';
      case 'company':
        try {
          return companyName!;
        } catch (e) {
          log('dashboard.dart: Error building asset tile for company: $e');
          return '';
        }
      default:
        return fieldName;
    }
  }

  Widget getFundIcon(FundName fund) {
    switch (fund) {
      case FundName.AGQ:
        return SvgPicture.asset('assets/icons/agq_logo.svg');
      case FundName.AK1:
        return SvgPicture.asset('assets/icons/ak1_logo.svg');
      default:
        return const Icon(Icons.account_balance, color: Colors.white);
    }
  }

}