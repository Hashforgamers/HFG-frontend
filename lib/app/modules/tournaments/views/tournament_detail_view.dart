import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TournamentDetailView extends StatelessWidget {
  const TournamentDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xffDE3A3A),
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Schedule'),
              Tab(text: 'Teams'),
              Tab(text: 'Credentials'),
              Tab(text: 'Results'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OverviewTab(),
            ScheduleTab(),
            TeamsTab(),
            CredentialsTab(),
            ResultsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoIcon(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(width: 5),
        Text(text, style: GoogleFonts.inter(color: Colors.white)),
      ],
    );
  }

  Widget _buildJoiningInfo(String title, String detail) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          detail,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildEventDetail(String title, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$title: ',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
            ),
            TextSpan(
              text: detail,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeDistribution(String prize, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              prize,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            ),
            Text(
              '₹ $amount',
              style: GoogleFonts.inter(color: Colors.yellow, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundDetail(String round, String type, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              round,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 5),
            Text(
              type,
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              detail,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    'https://t4.ftcdn.net/jpg/05/57/61/79/360_F_557617905_iSt6BAH73qgXHULb0ZpHOwADFj7tX6q8.jpg'), // Replace with actual image URL
                fit: BoxFit.cover,
              ),
            ),
            child: const Stack(
              children: [
                Positioned(
                  top: 10,
                  right: 10,
                  child: Icon(Icons.bookmark_border, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'NOV 18 2023, 12:00AM  Registration ends in 4 days',
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            'Tournament Name Will Come Here',
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoIcon(Icons.monetization_on, '50k'),
              _buildInfoIcon(Icons.group, 'Squad'),
              _buildInfoIcon(Icons.people, '120/2000'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildJoiningInfo('Joining Time', '15 min before start'),
              ),
              Expanded(
                child: _buildJoiningInfo('Slots Available', '3290'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Get ready to showcase your gaming prowess and experience thrilling team-based battles in the heart of Delhi. This is your chance to engage in epic showdowns, forge new strategies, and meet a gaming icon—all in one thrilling event.',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 10),
          _buildEventDetail('Date', 'WILL BE DISCLOSED SOON'),
          _buildEventDetail('Location', 'WILL BE DISCLOSED SOON'),
          _buildEventDetail('Time', 'WILL BE DISCLOSED SOON'),
          const SizedBox(height: 10),
          Text(
            'PRIZE DISTRIBUTION',
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 10),
          _buildPrizeDistribution('1ST PRIZE', '30000'),
          _buildPrizeDistribution('2ND PRIZE', '20000'),
          const SizedBox(height: 20),
          _buildRoundDetail(
              'Round 1', 'Single Elimination', 'Top 1 Team Per Group'),
          _buildRoundDetail(
              'Round 2', 'Single Elimination', 'Top 1 Team Per Group'),
          _buildRoundDetail(
              'Round 3', 'Single Elimination', 'Top 1 Team Per Group'),
          _buildRoundDetail('Round 4', 'Single Elimination', 'Winner'),
        ],
      ),
    );
  }

  Widget _buildInfoIcon(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 5),
        Text(text, style: GoogleFonts.inter(color: Colors.white)),
      ],
    );
  }

  Widget _buildJoiningInfo(String title, String detail) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          detail,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildEventDetail(String title, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$title: ',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
            ),
            TextSpan(
              text: detail,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeDistribution(String prize, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              prize,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            ),
            Text(
              '₹ $amount',
              style: GoogleFonts.inter(color: Colors.yellow, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundDetail(String round, String type, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              round,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 5),
            Text(
              type,
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              detail,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduleTab extends StatelessWidget {
  const ScheduleTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Schedule Content',
          style: GoogleFonts.inter(color: Colors.white)),
    );
  }
}

class TeamsTab extends StatelessWidget {
  const TeamsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Teams Content',
        style: GoogleFonts.inter(color: Colors.white),
      ),
    );
  }
}

class CredentialsTab extends StatelessWidget {
  const CredentialsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Credentials Content',
        style: GoogleFonts.inter(color: Colors.white),
      ),
    );
  }
}

class ResultsTab extends StatelessWidget {
  const ResultsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Results Content',
        style: GoogleFonts.inter(color: Colors.white),
      ),
    );
  }
}
