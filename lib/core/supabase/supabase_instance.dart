import 'package:supabase_flutter/supabase_flutter.dart';

late final SupabaseClient supabase;

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: 'https://kjkitypxpuqzoajautly.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtqa2l0eXB4cHVxem9hamF1dGx5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYzODYwNDksImV4cCI6MjA3MTk2MjA0OX0.ugh30Y2_o3Tf4wFoBMjRzRu585awYX1vJPLG1DEE9Xo',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  supabase = Supabase.instance.client;
}
