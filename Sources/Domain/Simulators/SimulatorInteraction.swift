public enum SimulatorButton: String, Sendable, Equatable {
    case home
    case lock
    case siri
    case sideButton = "side-button"
    case applePay = "apple-pay"
}

public enum SimulatorGesture: String, Sendable, Equatable {
    case scrollUp = "scroll-up"
    case scrollDown = "scroll-down"
    case scrollLeft = "scroll-left"
    case scrollRight = "scroll-right"
    case swipeFromLeftEdge = "swipe-from-left-edge"
    case swipeFromRightEdge = "swipe-from-right-edge"
    case swipeFromTopEdge = "swipe-from-top-edge"
    case swipeFromBottomEdge = "swipe-from-bottom-edge"
}
