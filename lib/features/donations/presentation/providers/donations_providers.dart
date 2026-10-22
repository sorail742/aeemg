import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/donations_repository.dart';

final donationsRepositoryProvider = Provider<DonationsRepository>((ref) {
  return DonationsRepository(ref.watch(supabaseClientProvider));
});

final donationCampaignsProvider = FutureProvider((ref) async {
  return ref.read(donationsRepositoryProvider).fetchCampaigns();
});

final myDonationsProvider = FutureProvider((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return <DonationRecord>[];
  return ref.read(donationsRepositoryProvider).fetchMyDonations(user.id);
});
