class PinManager {
    private let secureStorage: ISecureStorage

    init(secureStorage: ISecureStorage) {
        self.secureStorage = secureStorage
    }

}

extension PinManager: IPinManager {

    var isPinned: Bool {
        return secureStorage.pin != nil
    }

    func store(pin: String?) throws {
        try secureStorage.set(pin: pin)
    }

    func validate(pin: String) -> Bool {
        return secureStorage.pin == pin
    }

}
