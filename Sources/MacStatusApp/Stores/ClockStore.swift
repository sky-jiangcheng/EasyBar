import Foundation
import Observation

@Observable
@MainActor
final class ClockStore {
    private var timer: Timer?

    var now = Date()

    func start() {
        timer?.invalidate()
        now = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.now = Date()
            }
        }
    }
}
