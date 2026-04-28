import 'package:flutter/material.dart';
import '../data/user.dart';

class FindFriendsPage extends StatefulWidget {
  final List<User> potentialFriends;
  final Future<void> Function(User) onFollow;
  final Future<void> Function(User) onUnfollow;
  final List<User> following;

  const FindFriendsPage({
    super.key,
    required this.potentialFriends,
    required this.onFollow,
    required this.onUnfollow,
    required this.following,
  });

  @override
  State<FindFriendsPage> createState() => _FindFriendsPageState();
}

class _FindFriendsPageState extends State<FindFriendsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Find Friends', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          // Find New Friends Section
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Find New Friends',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...widget.potentialFriends.map((user) => Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user.avatarUrl),
                  ),
                  title: Text(user.name, style: const TextStyle(color: Colors.white)),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      if (widget.following.contains(user)) {
                        await widget.onUnfollow(user);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Unfollowed ${user.name}')),
                        );
                      } else {
                        await widget.onFollow(user);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Followed ${user.name}')),
                        );
                      }
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    child: Text(widget.following.contains(user) ? 'Unfollow' : 'Follow'),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}