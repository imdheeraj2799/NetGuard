import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/features/system_controls/domain/entities/dns_resolver_entity.dart';
import 'package:net_guard/features/system_controls/presentation/bloc/system_controls_bloc.dart';
import 'package:net_guard/features/system_controls/presentation/bloc/system_controls_event.dart';
import 'package:net_guard/features/system_controls/presentation/bloc/system_controls_state.dart';
import 'package:net_guard/features/system_controls/presentation/widgets/dns_selection_dialog.dart';

class MockSystemControlsBloc extends Mock implements SystemControlsBloc {}

void main() {
  late MockSystemControlsBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(
      const SelectDnsResolverEvent(DnsResolverEntity.cloudflare),
    );
  });

  setUp(() {
    mockBloc = MockSystemControlsBloc();
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockBloc.state).thenReturn(
      const SystemControlsLoaded(
        currentResolver: DnsResolverEntity.cloudflare,
        availableResolvers: DnsResolverEntity.predefined,
      ),
    );
  });

  testWidgets('DnsSelectionDialog renders predefined options and triggers selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<SystemControlsBloc>.value(
            value: mockBloc,
            child: const DnsSelectionDialog(),
          ),
        ),
      ),
    );

    expect(find.text('SELECT DNS RESOLVER'), findsOneWidget);
    expect(find.text('Cloudflare'), findsOneWidget);
    expect(find.text('Google Public DNS'), findsOneWidget);
    expect(find.text('AdGuard DNS'), findsOneWidget);
    expect(find.text('Custom IPv4 Resolver'), findsOneWidget);

    await tester.tap(find.text('Google Public DNS'));
    await tester.pump();

    await tester.tap(find.text('APPLY'));
    await tester.pump();

    verify(
      () => mockBloc.add(
        any(
          that: isA<SelectDnsResolverEvent>().having(
            (e) => e.resolver.id,
            'resolver.id',
            'google',
          ),
        ),
      ),
    ).called(1);
  });
}
