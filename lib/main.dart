import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:link_compressor/stores/expiry_notifier.dart';
import 'package:link_compressor/stores/link_store.dart';
import 'package:link_compressor/widgets/link_form.dart';
import 'package:link_compressor/widgets/link_history.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LinkStore()..load()),
        ChangeNotifierProvider(create: (_) => ExpiryNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[200],
        centerTitle: true,
        title: const Text('Link Compressor'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'In this free website, you can compress and customize any links to a shorter version.\nAlso you can set expire date for links',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  LinkForm(),
                  SizedBox(height: 32),
                  LinkHistory(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
