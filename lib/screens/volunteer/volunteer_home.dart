import '../auth/login_screen.dart';
import '../../core/session_manager.dart';

class VolunteerHome extends StatelessWidget {
  const VolunteerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Dashboard'),
        backgroundColor: Colors.orange,
         actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
               await SessionManager.clearSession();
               if (!context.mounted) return;
               Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome, Volunteer!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
