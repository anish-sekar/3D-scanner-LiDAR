
import Foundation
import RealityKit
import ARKit
import ModelIO
import MetalKit
import QuickLook
import SceneKit
import UIKit
import Combine

class NewScanViewController: UIViewController, ARSessionDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @IBOutlet weak var arView: ARView!
    @IBOutlet var resetButton: UIButton!
    

    @IBOutlet weak var planeDetectionButton: UIButton!
    var subscription: Cancellable!
    var asset: MDLAsset!
    var pictureArray: [CVPixelBuffer] = []
    @IBOutlet var saveButton: UIButton!
    let coachingOverlay = ARCoachingOverlayView()
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var chooseBuuton: UIButton!
    var imagePicker = UIImagePickerController()
    var sendingImage: UIImage!
        
        /// - Tag: ViewDidLoad
        override func viewDidLoad() {
            super.viewDidLoad()
            
            arView.session.delegate = self
            
            setupCoachingOverlay()

            arView.environment.sceneUnderstanding.options = []
            
            // Turn on occlusion from the scene reconstruction's mesh.
            arView.environment.sceneUnderstanding.options.insert(.occlusion)
            
            // Turn on physics for the scene reconstruction's mesh.
            arView.environment.sceneUnderstanding.options.insert(.physics)

            // Display a debug visualization of the mesh.
            arView.debugOptions.insert(.showSceneUnderstanding)
            
            // For performance, disable render options that are not required for this app.
            arView.renderOptions = [.disablePersonOcclusion, .disableDepthOfField, .disableMotionBlur]
            
            // Enable gesture recognizer to capture taps
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedOnARView))
            arView.addGestureRecognizer(tapGesture)
            
            // Manually configure what kind of AR session to run
            arView.automaticallyConfigureSession = false
            let configuration = ARWorldTrackingConfiguration()
            configuration.sceneReconstruction = .mesh

            configuration.environmentTexturing = .automatic
            arView.session.run(configuration)
        }
    
    
        /// Tap gesture input handler.
        /// - Tag: TapHandler
        @objc
        func tappedOnARView(_ sender: UITapGestureRecognizer) {
        
            // Get the user's tap screen location.
            let touchLocation = sender.location(in: arView)
            
            //Defining the alertbox for improper click
            let alert = UIAlertController(title: "Oops!", message: "Was not a valid surface, try again", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            // Cast a ray to check for its intersection with any planes.
            guard let raycastResult = arView.raycast(from: touchLocation, allowing: .estimatedPlane, alignment: .any).first else {
                self.present(alert, animated: true)
                return
            }
            
            // Create a new sticky note positioned at the hit test result's world position.
            let frame = CGRect(origin: touchLocation, size: CGSize(width: 200, height: 200))
            let label = LabelEntity(frame: frame, worldTransform: raycastResult.worldTransform)
            label.setPositionCenter(touchLocation)

        
    }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            // Prevent the screen from being dimmed to avoid interrupting the AR experience.
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        
        override var prefersHomeIndicatorAutoHidden: Bool {
            return true
        }
        
        
        override var prefersStatusBarHidden: Bool {
            return true
        }
        
    @IBAction func resetButtonPressed(_ sender: Any) {
        print("rest pressed")
        if let configuration = arView.session.configuration {
            arView.session.run(configuration, options: .resetSceneReconstruction)
        }
    }
    
    @IBAction func snapImage(_ sender: UIButton) {
        
        if let pixBuf = arView.session.currentFrame?.capturedImage {
        pictureArray.append(pixBuf)
        }
    }      
 
    
        /// - Tag: TogglePlaneDetection
        @IBAction func togglePlaneDetectionButtonPressed(_ button: UIButton) {
            guard let configuration = arView.session.configuration as? ARWorldTrackingConfiguration else {
                return
            }
            if configuration.planeDetection == [] {
                configuration.planeDetection = [.horizontal, .vertical]
                button.setTitle("Stop Plane Detection", for: [])
            } else {
                configuration.planeDetection = []
                button.setTitle("Start Plane Detection", for: [])
            }
            arView.session.run(configuration)
    }
    
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        print("Save button was pressed")
        guard let frame = arView.session.currentFrame else {
            fatalError("Couldn't get the current ARFrame")
        }
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Failed to get the system's default Metal device!")
        }
        
        print("Basic setup done")
        

        let allocator = MTKMeshBufferAllocator(device: device)
        asset = MDLAsset(bufferAllocator: allocator)
        
        // Fetch all ARMeshAncors
        let meshAnchors = frame.anchors.compactMap({ $0 as? ARMeshAnchor })
        
        // Convert the geometry of each ARMeshAnchor into a MDLMesh and add it to the MDLAsset
        for meshAncor in meshAnchors {
            
            // Some short handles, otherwise stuff will get pretty long in a few lines
            let geometry = meshAncor.geometry
            let vertices = geometry.vertices
            let faces = geometry.faces
            let verticesPointer = vertices.buffer.contents()
            let facesPointer = faces.buffer.contents()
            
            // Converting each vertex of the geometry from the local space of their ARMeshAnchor to world space
            for vertexIndex in 0..<vertices.count {
                
                // Extracting the current vertex with an extension method provided by Apple in Extensions.swift
                let vertex = geometry.vertex(at: UInt32(vertexIndex))
                
                // Building a transform matrix with only the vertex position
                // and apply the mesh anchors transform to convert into world space
                var vertexLocalTransform = matrix_identity_float4x4
                vertexLocalTransform.columns.3 = SIMD4<Float>(x: vertex.0, y: vertex.1, z: vertex.2, w: 1)
                let vertexWorldPosition = (meshAncor.transform * vertexLocalTransform).position
                
                // Writing the world space vertex back into it's position in the vertex buffer
                let vertexOffset = vertices.offset + vertices.stride * vertexIndex
                let componentStride = vertices.stride / 3
                verticesPointer.storeBytes(of: vertexWorldPosition.x, toByteOffset: vertexOffset, as: Float.self)
                verticesPointer.storeBytes(of: vertexWorldPosition.y, toByteOffset: vertexOffset + componentStride, as: Float.self)
                verticesPointer.storeBytes(of: vertexWorldPosition.z, toByteOffset: vertexOffset + (2 * componentStride), as: Float.self)
            }
            
            // Initializing MDLMeshBuffers with the content of the vertex and face MTLBuffers
            let byteCountVertices = vertices.count * vertices.stride
            let byteCountFaces = faces.count * faces.indexCountPerPrimitive * faces.bytesPerIndex
            let vertexBuffer = allocator.newBuffer(with: Data(bytesNoCopy: verticesPointer, count: byteCountVertices, deallocator: .none), type: .vertex)
            let indexBuffer = allocator.newBuffer(with: Data(bytesNoCopy: facesPointer, count: byteCountFaces, deallocator: .none), type: .index)
            
            // Creating a MDLSubMesh with the index buffer and a generic material
            let indexCount = faces.count * faces.indexCountPerPrimitive
            let material = MDLMaterial(name: "mat1", scatteringFunction: MDLPhysicallyPlausibleScatteringFunction())
            let submesh = MDLSubmesh(indexBuffer: indexBuffer, indexCount: indexCount, indexType: .uInt32, geometryType: .triangles, material: material)
            
            // Creating a MDLVertexDescriptor to describe the memory layout of the mesh
            let vertexFormat = MTKModelIOVertexFormatFromMetal(vertices.format)
            let vertexDescriptor = MDLVertexDescriptor()
            vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: vertexFormat, offset: 0, bufferIndex: 0)
            vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: meshAncor.geometry.vertices.stride)
            
            // Finally creating the MDLMesh and adding it to the MDLAsset
            let mesh = MDLMesh(vertexBuffer: vertexBuffer, vertexCount: meshAncor.geometry.vertices.count, descriptor: vertexDescriptor, submeshes: [submesh])
            asset.add(mesh)
        }
        
        // Setting the path to export the OBJ file to
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let urlOBJ = documentsPath.appendingPathComponent("scan.obj")

        // Exporting the OBJ file
        if MDLAsset.canExportFileExtension("obj") {
            do {
                try asset.export(to: urlOBJ)

                // Sharing the OBJ file
                let activityController = UIActivityViewController(activityItems: [urlOBJ], applicationActivities: nil)
                activityController.popoverPresentationController?.sourceView = sender
                self.present(activityController, animated: true, completion: nil)
            } catch let error {
                fatalError(error.localizedDescription)
            }
        } else {
            fatalError("Can't export OBJ")
        }
    }

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                self.resetButtonPressed(self)
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is PreviewModalController
        {
            guard let frame = arView.session.currentFrame else {
                fatalError("Couldn't get the current ARFrame")
            }
            
            // Fetch the default MTLDevice to initialize a MetalKit buffer allocator with
            guard let device = MTLCreateSystemDefaultDevice() else {
                fatalError("Failed to get the system's default Metal device!")
            }
            
            print("Basic setup done")
            

            // Using the Model I/O framework to export the scan, so we're initialising an MDLAsset object,
            // which we can export to a file later, with a buffer allocator
            let allocator = MTKMeshBufferAllocator(device: device)
            asset = MDLAsset(bufferAllocator: allocator)
            
            // Fetch all ARMeshAncors
            let meshAnchors = frame.anchors.compactMap({ $0 as? ARMeshAnchor })
            
            // Convert the geometry of each ARMeshAnchor into a MDLMesh and add it to the MDLAsset
            for meshAncor in meshAnchors {
                
                // Some short handles, otherwise stuff will get pretty long in a few lines
                let geometry = meshAncor.geometry
                let vertices = geometry.vertices
                let faces = geometry.faces
                let verticesPointer = vertices.buffer.contents()
                let facesPointer = faces.buffer.contents()
                
                // Converting each vertex of the geometry from the local space of their ARMeshAnchor to world space
                for vertexIndex in 0..<vertices.count {
                    
                    // Extracting the current vertex with an extension method provided by Apple in Extensions.swift
                    let vertex = geometry.vertex(at: UInt32(vertexIndex))
                    
                    // Building a transform matrix with only the vertex position
                    // and apply the mesh anchors transform to convert into world space
                    var vertexLocalTransform = matrix_identity_float4x4
                    vertexLocalTransform.columns.3 = SIMD4<Float>(x: vertex.0, y: vertex.1, z: vertex.2, w: 1)
                    let vertexWorldPosition = (meshAncor.transform * vertexLocalTransform).position
                    
                    // Writing the world space vertex back into it's position in the vertex buffer
                    let vertexOffset = vertices.offset + vertices.stride * vertexIndex
                    let componentStride = vertices.stride / 3
                    verticesPointer.storeBytes(of: vertexWorldPosition.x, toByteOffset: vertexOffset, as: Float.self)
                    verticesPointer.storeBytes(of: vertexWorldPosition.y, toByteOffset: vertexOffset + componentStride, as: Float.self)
                    verticesPointer.storeBytes(of: vertexWorldPosition.z, toByteOffset: vertexOffset + (2 * componentStride), as: Float.self)
                }
                
                // Initializing MDLMeshBuffers with the content of the vertex and face MTLBuffers
                let byteCountVertices = vertices.count * vertices.stride
                let byteCountFaces = faces.count * faces.indexCountPerPrimitive * faces.bytesPerIndex
                let vertexBuffer = allocator.newBuffer(with: Data(bytesNoCopy: verticesPointer, count: byteCountVertices, deallocator: .none), type: .vertex)
                let indexBuffer = allocator.newBuffer(with: Data(bytesNoCopy: facesPointer, count: byteCountFaces, deallocator: .none), type: .index)
                
                // Creating a MDLSubMesh with the index buffer and a generic material
                let indexCount = faces.count * faces.indexCountPerPrimitive
                let material = MDLMaterial(name: "mat1", scatteringFunction: MDLPhysicallyPlausibleScatteringFunction())
                let submesh = MDLSubmesh(indexBuffer: indexBuffer, indexCount: indexCount, indexType: .uInt32, geometryType: .triangles, material: material)
                
                // Creating a MDLVertexDescriptor to describe the memory layout of the mesh
                let vertexFormat = MTKModelIOVertexFormatFromMetal(vertices.format)
                let vertexDescriptor = MDLVertexDescriptor()
                vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: vertexFormat, offset: 0, bufferIndex: 0)
                vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: meshAncor.geometry.vertices.stride)
                
                // Finally creating the MDLMesh and adding it to the MDLAsset
                let mesh = MDLMesh(vertexBuffer: vertexBuffer, vertexCount: meshAncor.geometry.vertices.count, descriptor: vertexDescriptor, submeshes: [submesh])
                asset.add(mesh)
            
            let vc = segue.destination as? PreviewModalController
            vc?.asset = asset
            //vc?.image=sendingImage
            vc?.pictureArray = pictureArray
            
        }
        }
    }
}
