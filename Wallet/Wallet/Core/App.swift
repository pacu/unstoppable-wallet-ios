class App {
    static let shared = App()

    private let fallbackLanguage = "en"

    let secureStorage: ISecureStorage
    let localStorage: ILocalStorage
    let wordsManager: IWordsManager

    let pinManager: IPinManager
    let lockRouter: ILockRouter
    let lockManager: ILockManager
    let blurManager: IBlurManager

    let localizationManager: LocalizationManager
    let languageManager: ILanguageManager

    var adapterManager: IAdapterManager!
    var exchangeRateManager: IExchangeRateManager!

    init() {
        secureStorage = KeychainStorage()
        localStorage = UserDefaultsStorage()
        wordsManager = WordsManager(secureStorage: secureStorage, localStorage: localStorage)

        pinManager = PinManager(secureStorage: secureStorage)
        lockRouter = LockRouter()
        lockManager = LockManager(localStorage: localStorage, wordsManager: wordsManager, lockRouter: lockRouter)
        blurManager = BlurManager(lockManager: lockManager)

        localizationManager = LocalizationManager()
        languageManager = LanguageManager(localizationManager: localizationManager, localStorage: localStorage, fallbackLanguage: fallbackLanguage)

        initLoggedInState()
    }

    func initLoggedInState() {
        if let words = wordsManager.words {
            adapterManager = AdapterManager(words: words)
            exchangeRateManager = ExchangeRateManager()

            adapterManager.start()
        }
    }

}
