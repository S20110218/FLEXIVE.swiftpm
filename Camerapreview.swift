import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        // 縦向き（ポートレート）に設定
        previewLayer.connection?.videoOrientation = .portrait
        
        view.layer.addSublayer(previewLayer)
        
        // レイアウト更新を監視
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        
        // Coordinatorに保存
        context.coordinator.previewLayer = previewLayer
        context.coordinator.parentView = view
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
        var parentView: UIView?
    }
}
