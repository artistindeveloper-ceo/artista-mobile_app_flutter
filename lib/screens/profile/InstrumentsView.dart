// import 'package:flutter/material.dart';
//
// import '../../model/InstrumentModel.dart';
// import '../../theme/app_theme.dart';
// import '../../widgets/showAddInstrumentSheet.dart';
// import 'InstrumentCard.dart';
//
// /// Renders the "Instruments" tab (a user's gear / gadgets), split into
// /// Primary and Secondary instrument sections, with an "Add" action for
// /// the profile owner.
// class InstrumentsView extends StatelessWidget {
//   final List<InstrumentModel> instruments;
//   final bool isLoading;
//   final bool isOwnProfile;
//
//   /// Called after an instrument is successfully added, so the parent can
//   /// reload the list.
//   final VoidCallback onInstrumentAdded;
//
//   const InstrumentsView({
//     super.key,
//     required this.instruments,
//     required this.isLoading,
//     required this.isOwnProfile,
//     required this.onInstrumentAdded,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return const SizedBox(
//         height: 200,
//         child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
//       );
//     }
//
//     final primary = instruments.where((i) => i.isPrimary).toList();
//     final secondary = instruments.where((i) => !i.isPrimary).toList();
//
//     if (instruments.isEmpty) {
//       return SizedBox(
//         height: 220,
//         child: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.music_off_outlined,
//                   size: 40, color: AppColors.textGrey),
//               const SizedBox(height: 10),
//               const Text('No instruments added yet',
//                   style: TextStyle(color: AppColors.textGrey)),
//               if (isOwnProfile) ...[
//                 const SizedBox(height: 12),
//                 OutlinedButton.icon(
//                   onPressed: () => showAddInstrumentSheet(
//                     context,
//                     onAdded: onInstrumentAdded,
//                   ),
//                   icon: const Icon(Icons.add, size: 16, color: AppColors.gold),
//                   label: const Text('Add Instrument',
//                       style: TextStyle(color: AppColors.gold)),
//                   style: OutlinedButton.styleFrom(
//                     side: const BorderSide(color: AppColors.gold),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       );
//     }
//
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (isOwnProfile)
//             Align(
//               alignment: Alignment.centerRight,
//               child: TextButton.icon(
//                 onPressed: () => showAddInstrumentSheet(
//                   context,
//                   onAdded: onInstrumentAdded,
//                 ),
//                 icon: const Icon(Icons.add, size: 16, color: AppColors.gold),
//                 label:
//                     const Text('Add', style: TextStyle(color: AppColors.gold)),
//               ),
//             ),
//           if (primary.isNotEmpty) ...[
//             const Text('Primary Instrument',
//                 style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                     color: AppColors.textPrimary)),
//             const SizedBox(height: 8),
//             ...primary.map((ins) => InstrumentCard(instrument: ins)),
//             const SizedBox(height: 20),
//           ],
//           if (secondary.isNotEmpty) ...[
//             const Text('Secondary Instrument',
//                 style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                     color: AppColors.textPrimary)),
//             const SizedBox(height: 8),
//             ...secondary.map((ins) => InstrumentCard(instrument: ins)),
//           ],
//         ],
//       ),
//     );
//   }
// }
