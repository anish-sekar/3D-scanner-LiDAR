
import ARKit
import RealityKit

/// An Entity which has an anchoring component and a screen space view component, where the screen space view is a StickyNoteView.
class LabelEntity: Entity, HasAnchoring, HasScreenSpaceView {
    // ...

    var screenSpaceComponent = ScreenSpaceComponent()
    
    init(frame: CGRect, worldTransform: simd_float4x4) {
        super.init()
        self.transform.matrix = worldTransform
        // ...
        screenSpaceComponent.view = LabelView(frame: frame, note: self)
    }
    required init() {
        fatalError("init() has not been implemented")
    }
}
