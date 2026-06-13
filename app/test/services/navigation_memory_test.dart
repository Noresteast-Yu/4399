import 'package:flutter_test/flutter_test.dart';
import 'package:smart_travel_app/services/navigation_memory.dart';

void main() {
  setUp(NavigationMemory.clearStationContext);

  test('new route plan clears the previous indoor guide progress', () {
    NavigationMemory.updateStationContext(
      stationId: 'tong_ji_university',
      stationName: '同济大学',
      nodeId: '5',
    );
    NavigationMemory.lastStepIndex = 6;

    NavigationMemory.beginNewRoutePlan();

    expect(NavigationMemory.currentStationId, isNull);
    expect(NavigationMemory.currentStationName, isNull);
    expect(NavigationMemory.currentNodeId, isNull);
    expect(NavigationMemory.lastStepIndex, 0);
  });

  test('reopening a guide resets its step but keeps the station context', () {
    NavigationMemory.updateStationContext(
      stationId: 'tong_ji_university',
      stationName: '同济大学',
      nodeId: '1',
    );
    NavigationMemory.lastStepIndex = 4;

    NavigationMemory.restartIndoorGuide();

    expect(NavigationMemory.currentStationId, 'tong_ji_university');
    expect(NavigationMemory.currentStationName, '同济大学');
    expect(NavigationMemory.currentNodeId, isNull);
    expect(NavigationMemory.lastStepIndex, 0);
  });

  test('switching tabs does not change the active guide progress', () {
    NavigationMemory.updateStationContext(
      stationId: 'tong_ji_university',
      stationName: '同济大学',
      nodeId: '3',
    );
    NavigationMemory.lastStepIndex = 2;

    expect(NavigationMemory.currentNodeId, '3');
    expect(NavigationMemory.lastStepIndex, 2);
  });
}
