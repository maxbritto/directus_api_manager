class MockNullValue {
  final bool isNUll = true;
  const MockNullValue();
}

mixin MockMixin {
  final Set<String> calledFunctions = {};
  final List<dynamic> _preparedObjects = [];
  final Map<String, dynamic> receivedObjects = {};
  dynamic _lastReceivedObject;
  set lastReceivedObject(dynamic object) {
    receivedObjects[object.toString()] = object;
    _lastReceivedObject = object;
  }

  dynamic get lastReceivedObject => _lastReceivedObject;

  addReceivedObject(dynamic object, {required String name}) {
    receivedObjects[name] = object;
    _lastReceivedObject = object;
  }

  dynamic get nextReturnedObject {
    if (_preparedObjects.isEmpty) {
      return null;
    } else {
      return _preparedObjects[0];
    }
  }

  set nextReturnedObject(dynamic nextObject) {
    addNextReturnFutureObject(nextObject);
  }

  bool wasCalled({required String functionName}) {
    return calledFunctions.contains(functionName);
  }

  resetAllTestValues() {
    calledFunctions.clear();
    lastReceivedObject = null;
    _preparedObjects.clear();
    receivedObjects.clear();
  }

  ///Receives a regular object and save it for the next function that will need to return something
  addNextReturnFutureObject(dynamic object) {
    _preparedObjects.add(object ?? const MockNullValue());
  }

  dynamic popNextReturnedObject() {
    if (_preparedObjects.isEmpty) {
      return null;
    }
    final returnedObject = _preparedObjects.removeAt(0);
    if (returnedObject is MockNullValue) {
      //we store a basic Object to mock a null return
      return null;
    } else if (returnedObject is Error || returnedObject is Exception) {
      throw returnedObject;
    } else {
      return returnedObject;
    }
  }
}
