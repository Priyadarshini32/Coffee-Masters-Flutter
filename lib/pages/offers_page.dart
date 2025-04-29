import 'package:flutter/material.dart';

class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.brown[50]!,
            Colors.brown[100]!,
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 16),
          Text(
            'Special Offers',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.brown[800],
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Offer(
            title: 'Buy 1 Get 1 Free',
            description: 'On all cappuccinos this weekend only!',
            icon: Icons.local_cafe,
            color: Colors.brown[300]!,
          ),
          Offer(
            title: 'Happy Hour ☕',
            description: 'Espresso shots at half price, 4–6 PM daily.',
            icon: Icons.access_time,
            color: Colors.brown[400]!,
          ),
          Offer(
            title: 'New Launch: Iced Latte',
            description: 'Cool down with our latest iced treat!',
            icon: Icons.ac_unit,
            color: Colors.brown[500]!,
          ),
          Offer(
            title: 'Loyalty Perk',
            description: 'Collect 5 stars, get a free Americano.',
            icon: Icons.star,
            color: Colors.brown[600]!,
          ),
        ],
      ),
    );
  }
}

class Offer extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const Offer({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.brown[800],
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.brown[600],
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 