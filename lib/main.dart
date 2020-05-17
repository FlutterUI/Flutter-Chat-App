import 'package:chat_app/features/login/presentation/pages/loading_page.dart';
import 'package:chat_app/injection_container.dart';
import 'package:chat_app/src/pages/image_message_view.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sailor/sailor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/login/presentation/bloc/login_bloc.dart';
import 'features/login/presentation/pages/login_page.dart';
import 'features/login/presentation/widgets/custom_snackbar.dart';
import 'src/pages/chat_page.dart';
import 'src/pages/home_page.dart';
import 'src/pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init();
  Routes.createRoutes();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = serviceLocator<LoginBloc>();
        bloc.add(CheckLoggedInStateEvent());
        return bloc;
      },
      child: MaterialApp(
        title: 'Chat App',
        theme: ThemeData(
          primarySwatch: Colors.deepOrange,
        ),
        home: BlocListener<LoginBloc, LoginState>(
          listener: (ctx, state) {
            if (state is AlertMessageState) {
              _displaySnackBar(
                context: ctx,
                message: state.message,
                isSuccessful: true,
              );
            } else if (state is ErrorState) {
              _displaySnackBar(
                context: ctx,
                message: state.message,
                isSuccessful: false,
              );
            }
          },
          child: BlocBuilder<LoginBloc, LoginState>(
            builder: (ctx, state) {
              if (state is LoggedInState) {
                try {
                  serviceLocator.registerLazySingleton(() => state);
                } catch (err) {}
                return HomePage();
              } else if (state is LoggedOutState) {
                serviceLocator.unregister(
                    instance: serviceLocator<LoggedInState>());
                return LoginPage();
              } else if (state is LoadingState) {
                return LoadingPage();
              } else if (state is AlertMessageState) {
                return LoginPage();
              } else if (state is ErrorState) {
                try {
                  final loggedState = serviceLocator<LoggedInState>();
                  return HomePage();
                } catch (error) {
                  return LoginPage();
                }
              } else {
                return Center(
                  child: Text('Error Loading Screen'),
                );
              }
            },
          ),
        ),
        onGenerateRoute: Routes.sailor.generator(),
        navigatorKey: Routes.sailor.navigatorKey,
      ),
    );
  }

  void _displaySnackBar({
    BuildContext context,
    String message,
    bool isSuccessful,
  }) {
    Flushbar(
      margin: const EdgeInsets.all(8.0),
      borderRadius: 10.0,
      padding: const EdgeInsets.all(0.0),
      messageText: CustomSnackBar(
        message: message,
        isSuccessful: isSuccessful,
      ),
      duration: Duration(seconds: 3),
    ).show(context);
  }
}

class Routes {
  static Sailor sailor = Sailor();

  static void createRoutes() {
    sailor.addRoutes([
      SailorRoute(
        name: LoginPage.routeName,
        builder: (_, args, params) => LoginPage(),
      ),
      SailorRoute(
        name: HomePage.routeName,
        builder: (_, args, params) => HomePage(),
      ),
      SailorRoute(
        name: SettingsPage.routeName,
        builder: (_, args, params) => SettingsPage(),
      ),
      SailorRoute(
        name: ChatPage.routeName,
        builder: (_, args, params) => ChatPage(
          peerId: params.param('peerId'),
          peerName: params.param('peerName'),
        ),
        params: [
          SailorParam(
            name: 'peerId',
            defaultValue: '',
            isRequired: true,
          ),
          SailorParam(
            name: 'peerName',
            defaultValue: '',
            isRequired: true,
          ),
        ],
      ),
      SailorRoute(
        name: ImageMessageView.routeName,
        builder: (ctx, args, params) => ImageMessageView(
          imageUrl: params.param('imageUrl'),
        ),
        params: [
          SailorParam(
            name: 'imageUrl',
            isRequired: true,
          ),
        ],
      ),
    ]);
  }
}
