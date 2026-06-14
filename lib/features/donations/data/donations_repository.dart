import 'package:supabase_flutter/supabase_flutter.dart';

class DonationCampaign {
  const DonationCampaign({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.goalAmount,
    required this.raisedAmount,
    required this.isActive,
  });

  final String id;
  final String title;
  final String? description;
  final String category;
  final double goalAmount;
  final double raisedAmount;
  final bool isActive;

  double get progress =>
      goalAmount > 0 ? (raisedAmount / goalAmount).clamp(0, 1) : 0;

  factory DonationCampaign.fromJson(Map<String, dynamic> json) =>
      DonationCampaign(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        category: json['category'] as String? ?? 'general',
        goalAmount: (json['goal_amount'] as num).toDouble(),
        raisedAmount: (json['raised_amount'] as num).toDouble(),
        isActive: json['is_active'] as bool? ?? true,
      );
}

class DonationRecord {
  const DonationRecord({
    required this.id,
    required this.amount,
    required this.category,
    required this.status,
    required this.createdAt,
    this.campaignTitle,
  });

  final String id;
  final double amount;
  final String category;
  final String status;
  final DateTime createdAt;
  final String? campaignTitle;

  factory DonationRecord.fromJson(Map<String, dynamic> json) => DonationRecord(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String? ?? 'general',
        status: json['status'] as String? ?? 'pending',
        createdAt: DateTime.parse(json['created_at'] as String),
        campaignTitle: (json['donation_campaigns'] as Map<String, dynamic>?)?['title']
            as String?,
      );

  String get statusLabel => switch (status) {
        'completed' => 'Confirmé',
        'failed' => 'Échoué',
        _ => 'En attente',
      };
}

class DonationsRepository {
  DonationsRepository(this._client);

  final SupabaseClient? _client;

  Future<List<DonationCampaign>> fetchCampaigns() async {
    final rows = await _client
        ?.from('donation_campaigns')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return (rows as List? ?? [])
        .map((e) => DonationCampaign.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DonationRecord>> fetchMyDonations(String userId) async {
    final rows = await _client
        ?.from('donations')
        .select('*, donation_campaigns(title)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List? ?? [])
        .map((e) => DonationRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> createDonation({
    required String userId,
    required double amount,
    required String category,
    String? campaignId,
    bool isAnonymous = false,
  }) async {
    final row = await _client
        ?.from('donations')
        .insert({
          'user_id': userId,
          'amount': amount,
          'category': category,
          'campaign_id': campaignId,
          'is_anonymous': isAnonymous,
          'status': 'pending',
          'payment_method': 'orange_money',
        })
        .select('id')
        .single();
    return row!['id'] as String;
  }

  Future<Map<String, dynamic>> initiateOrangeMoney({
    required String donationId,
    required double amount,
    required String phone,
  }) async {
    final response = await _client?.functions.invoke(
      'orange-money-init',
      body: {
        'donation_id': donationId,
        'amount': amount,
        'phone': phone,
      },
    );
    return (response?.data as Map?)?.cast<String, dynamic>() ?? {};
  }
}
