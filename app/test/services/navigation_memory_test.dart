import 'package:flutter_test/flutter_test.dart';
import 'package:smart_travel_app/services/navigation_memory.dart';

void main() {
  group('NavigationMemory', () {
    setUp(() {
      NavigationMemory.clearStationContext();
      NavigationMemory.routePlanLocation = null;
    });

    tearDown(() {
      NavigationMemory.clearStationContext();
      NavigationMemory.routePlanLocation = null;
    });

    group('updateStationContext', () {
      test('sets stationId when provided', () {
        NavigationMemory.updateStationContext(
          stationId: 'tong_ji_university',
        );
        expect(NavigationMemory.currentStationId, 'tong_ji_university');
      });

      test('sets stationName when provided', () {
        NavigationMemory.updateStationContext(
          stationName: '同济大学',
        );
        expect(NavigationMemory.currentStationName, '同济大学');
      });

      test('sets nodeId when provided', () {
        NavigationMemory.updateStationContext(
          nodeId: '1',
        );
        expect(NavigationMemory.currentNodeId, '1');
      });

      test('sets all fields simultaneously', () {
        NavigationMemory.updateStationContext(
          stationId: 'tong_ji_university',
          stationName: '同济大学',
          nodeId: '20',
        );
        expect(NavigationMemory.currentStationId, 'tong_ji_university');
        expect(NavigationMemory.currentStationName, '同济大学');
        expect(NavigationMemory.currentNodeId, '20');
      });

      test('does not overwrite existing values when null is passed', () {
        NavigationMemory.updateStationContext(
          stationId: 'tong_ji_university',
          nodeId: '5',
        );
        NavigationMemory.updateStationContext(
          stationName: '同济大学',
        );
        // stationId and nodeId should be preserved
        expect(NavigationMemory.currentStationId, 'tong_ji_university');
        expect(NavigationMemory.currentStationName, '同济大学');
        expect(NavigationMemory.currentNodeId, '5');
      });
    });

    group('clearStationContext', () {
      test('clears all station context fields', () {
        NavigationMemory.updateStationContext(
          stationId: 'tong_ji_university',
          stationName: '同济大学',
          nodeId: '1',
        );
        NavigationMemory.lastStepIndex = 5;

        NavigationMemory.clearStationContext();

        expect(NavigationMemory.currentStationId, isNull);
        expect(NavigationMemory.currentStationName, isNull);
        expect(NavigationMemory.currentNodeId, isNull);
        expect(NavigationMemory.lastStepIndex, 0);
      });
    });

    group('lastStepIndex', () {
      test('defaults to 0', () {
        expect(NavigationMemory.lastStepIndex, 0);
      });

      test('can be set and read', () {
        NavigationMemory.lastStepIndex = 3;
        expect(NavigationMemory.lastStepIndex, 3);
      });
    });

    group('routePlanLocation', () {
      test('defaults to null', () {
        expect(NavigationMemory.routePlanLocation, isNull);
      });

      test('can be set and read', () {
        NavigationMemory.routePlanLocation = '/ai-planning?start=同济大学&end=陕西南路';
        expect(
          NavigationMemory.routePlanLocation,
          '/ai-planning?start=同济大学&end=陕西南路',
        );
      });
    });

    group('integration: station context lifecycle', () {
      test('full lifecycle: update → read → clear', () {
        // Simulate: user enters AI planning at 同济大学
        NavigationMemory.updateStationContext(
          stationId: 'tong_ji_university',
          stationName: '同济大学',
          nodeId: '1',
        );
        NavigationMemory.routePlanLocation = '/ai-planning?start=同济大学&end=陕西南路';
        NavigationMemory.lastStepIndex = 2;

        // Verify service page can read it
        expect(NavigationMemory.currentStationId, 'tong_ji_university');
        expect(NavigationMemory.currentStationName, '同济大学');
        expect(NavigationMemory.currentNodeId, '1');
        expect(NavigationMemory.routePlanLocation, contains('ai-planning'));

        // Simulate: user returns to route plan
        NavigationMemory.routePlanLocation = '/route-plan';
        NavigationMemory.clearStationContext();

        expect(NavigationMemory.currentStationId, isNull);
        expect(NavigationMemory.routePlanLocation, '/route-plan');
      });
    });
  });
}
