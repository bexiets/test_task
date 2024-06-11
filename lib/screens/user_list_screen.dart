import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:test_task/screens/user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
   
List<Map<String, dynamic>> _users = [];
int _page = 1;
bool _isLoading = false;
bool _hasMore = true;



  @override
  void initState() {
    super.initState();
    
    _checkInternet();
  }

   Future<void> _checkInternet() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      
      _showNoInternetSnackBar();
    } else {
      _fetchGitHubUsers();
    }
  }

  void _showNoInternetSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Нет подключения к интернету'),
      ),
    );
  }

  Future<void> _fetchGitHubUsers() async {
    print('connection successfull');
    setState(() {
      _isLoading = true;
    });
    final response = await http.get(Uri.parse('https://api.github.com/users?per_page=10&page=$_page'));
    
   if (response.statusCode == 200) {
    List<dynamic> users_info = json.decode(response.body);
    setState(() {
      for (var user in users_info) {
        // Check if the user already exists in the _users list
        bool userExists = _users.any((existingUser) => existingUser['login'] == user['login']);
        if (!userExists) {
          _users.add({
            'login': user['login'],
            'avatar_url': user['avatar_url'],
            'type': user['type'],
            'repos_url': user['repos_url']
          });
        }
      }

      _isLoading = false;
      _hasMore = users_info.length >= 10;
    });
  }  else {
    print('Status code: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Не удалось загрузить пользователей');
    }
  }
  void _loadMoreUsers() {
    setState(() {
      _page++;
    });
    _fetchGitHubUsers();
  }

   void _navigateToUserDetail(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(user: user),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Пользователи GitHub'),
      ),
      body: _isLoading && _users.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if(index < _users.length){
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(_users[index]['avatar_url']),
                    ),
                    title: Text(_users[index]['login']),
                    onTap: () => _navigateToUserDetail(_users[index]),
                  );
                }else {
                  return ListTile(
                    title: Center(
                        child: _isLoading
                            ? CircularProgressIndicator()
                            : _hasMore
                                ? Text('Load More')
                                : Text('No more users')),
                    onTap: _hasMore ? _loadMoreUsers : null,
                  );
                }
              } 
            ),
    );
  }
}