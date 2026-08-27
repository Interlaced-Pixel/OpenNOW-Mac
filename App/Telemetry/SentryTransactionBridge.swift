import Foundation

@objc(SentryTransactionBridge)
public final class SentryTransactionBridge: NSObject {
    private var transaction: SentryTransaction?

    @objc(transactionWithName:operation:)
    static func transaction(name: String, operation: String) -> SentryTransactionBridge? {
        guard let transaction = Sentry.startTransaction(name: name, operation: operation, makeCurrent: true) else { return nil }
        return SentryTransactionBridge(transaction: transaction)
    }

    private init(transaction: SentryTransaction) {
        self.transaction = transaction
        super.init()
    }

    deinit {
        finish()
    }

    @objc(setTag:value:)
    func setTag(_ key: String, value: String) {
        guard let transaction else { return }
        transaction.setTag(key, value: value)
    }

    @objc(setData:value:)
    func setData(_ key: String, value: String) {
        guard let transaction else { return }
        transaction.setData(key, value: value)
    }

    @objc(setStatus:)
    func setStatus(_ success: Bool) {
        guard let transaction else { return }
        transaction.setStatus(success)
    }

    @objc
    func finish() {
        guard let transaction else { return }
        self.transaction = nil
        transaction.finish()
    }
}
