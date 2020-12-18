//
//  PreviewModalController.swift
//  UrbanMapper
//
//  Created by Prajnya Prabhu on 11/28/20.
//
import MobileCoreServices
import UIKit;
import SceneKit;
import SceneKit.ModelIO;
import VideoToolbox

class PreviewModalController: UIViewController, UIScrollViewDelegate {
    
    var asset: MDLAsset!
    var scene = SCNScene()
    var pictureArray: [CVPixelBuffer]!
    var image: UIImage!
    @IBOutlet var sceneView: SCNView!
    @IBOutlet var imageDisplayView: UIView!
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!
    var taggingObject: SCNText!
   

    @IBAction func upload(_ sender: UIButton) {
        
        
        // Setting the path to export the OBJ file to
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let urlOBJ = documentsPath.appendingPathComponent("scanwlabel.obj")

        // Exporting the OBJ file
        if MDLAsset.canExportFileExtension("obj") {
            
                sceneView.scene!.write(to: urlOBJ,delegate: nil)
                // Sharing the OBJ file
                let activityController = UIActivityViewController(activityItems: [urlOBJ], applicationActivities: nil)
                activityController.popoverPresentationController?.sourceView = sender
                self.present(activityController, animated: true, completion: nil)
        
    }
    }
    
    func convertImages(_ picArray: [CVPixelBuffer]) -> [UIImage]{
        
        var imageArray = [UIImage]()
        
        
        for image in picArray{
            
            var cgImage: CGImage!
            
            VTCreateCGImageFromCVPixelBuffer(image, options: nil, imageOut: &cgImage)
            
            
            if (cgImage != nil) { let converted = UIImage(cgImage: cgImage,scale: 3, orientation: UIImage.Orientation.right)
                imageArray.append(converted)
//            let imgView = UIImageView(image: converted)
//            imgView.contentMode = UIImageView.ContentMode.scaleAspectFit;
//            //imgView.layer.masksToBounds = true
//             imgView.clipsToBounds = true;
//            imgView.center = CGPoint(x: imageDisplayView.frame.size.width  / 2,
//                                             y: imageDisplayView.frame.size.height / 2)
        }
        
           
    }
        return imageArray;
    }
    func setupImages(_ images: [UIImage]){

        for i in 0..<images.count {

            let imageView = UIImageView()
            imageView.image = images[i]
            let xPosition = UIScreen.main.bounds.width * CGFloat(i)
            imageView.frame = CGRect(x: xPosition, y: 0, width: scrollView.frame.width, height: scrollView.frame.height)
            imageView.contentMode = .scaleAspectFit
            imageView.isUserInteractionEnabled = true
            imageView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(imageTapped(_:))))

            scrollView.contentSize.width = scrollView.frame.width * CGFloat(i + 1)
            scrollView.addSubview(imageView)
            scrollView.delegate = self

        }

    }
    
    @objc func imageTapped(_ recognizer: UILongPressGestureRecognizer){
        
    if recognizer.state == .ended {
        // handling code
        
        let tappedPoint: CGPoint = recognizer.location(in: recognizer.view)
          let x: CGFloat = tappedPoint.x
          let y: CGFloat = tappedPoint.y

          print(tappedPoint)
          print(x)
          print(y)
       
        getTextLabelPopup(X:x,Y:y,recognizer:recognizer)
        
    }
    }
    
    func getTextLabelPopup(X: CGFloat,Y:CGFloat,recognizer: UILongPressGestureRecognizer) {
        
        //Step : 1
        let alert = UIAlertController(title: "Label Picture", message: "Please label areas of interest", preferredStyle: UIAlertController.Style.alert )
        //Step : 2
        let save = UIAlertAction(title: "Save", style: .default) { [self] (alertAction) in
            let textField = alert.textFields![0] as UITextField
            if textField.text != "" {
                //let text = UILabel(frame:CGRect(origin: CGPoint(x: X,y :Y), size: CGSize(width: 90, height: 50)))
                let text = UILabel(frame:CGRect(origin: CGPoint(x: X,y :Y), size: CGSize(width: 100, height: 27)))
                text.text = textField.text
                text.font = UIFont(name: text.font.fontName, size: 27)
                text.backgroundColor = UIColor.white
                text.textColor = UIColor.blue
                text.numberOfLines = 0
                text.lineBreakMode = .byWordWrapping
                text.textAlignment = NSTextAlignment.center
                recognizer.view?.addSubview(text)
                print("Alert submitted: \(textField.text!)")
                                
            } else {
                print("TF 1 is Empty...")
                
            }    }
        //Step : 3
        //For first TF
        alert.addTextField { (textField) in
            textField.placeholder = "Enter label name"
            textField.textColor = .blue
        }

        //Step : 4
        alert.addAction(save)
        //Cancel action
        let cancel = UIAlertAction(title: "Cancel", style: .default) { (alertAction) in }
        alert.addAction(cancel)
        //OR single line action
        //alert.addAction(UIAlertAction(title: "Cancel", style: .default) { (alertAction) in })

        self.present(alert, animated:true, completion: nil)
        print("Alert presented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        print("Number of images")
        print(pictureArray.count)
        
        let ui_images = convertImages(pictureArray)
        
        setupImages(ui_images)
        //imageDisplayView.addSubview(imgView)
        

//        print("assigning image to the imageView")
//        let imgView = UIImageView(image: image!)
//        imageDisplayView.addSubview(imgView)
        
        scene = SCNScene(mdlAsset: asset)

               // 2: Add camera node
               let cameraNode = SCNNode()
               cameraNode.camera = SCNCamera()
               // 3: Place camera
               cameraNode.position = SCNVector3(x: 0, y: 5, z: 35)
               // 4: Set camera on scene
               scene.rootNode.addChildNode(cameraNode)

               // 5: Adding light to scene
               let lightNode = SCNNode()
               lightNode.light = SCNLight()
               lightNode.light?.type = .omni
               lightNode.position = SCNVector3(x: 0, y: 5, z: 35)
               scene.rootNode.addChildNode(lightNode)

               // 6: Creating and adding ambien light to scene
               let ambientLightNode = SCNNode()
               ambientLightNode.light = SCNLight()
               ambientLightNode.light?.type = .ambient
               ambientLightNode.light?.color = UIColor.darkGray
               scene.rootNode.addChildNode(ambientLightNode)
                let longTap = UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap))
                sceneView.addGestureRecognizer(longTap)
               // Allow user to manipulate camera
               sceneView.allowsCameraControl = true

               // Show FPS logs and timming
               // sceneView.showsStatistics = true

               // Set background color
               sceneView.backgroundColor = UIColor.white

               // Allow user translate image
               sceneView.cameraControlConfiguration.allowsTranslation = false
        
//                let geoText = SCNText(string: "Hello", extrusionDepth: 1.0)
//        geoText.font = UIFont(name: "Helvetica", size: 0.5)
//                    let textNode = SCNNode(geometry: geoText)
//                    scene.rootNode.addChildNode(textNode)
//                    textNode.position = SCNVector3(x: 0, y: 0, z: 0)
        
               

               // Set scene settings
               sceneView.scene = scene}
    
    func alertWithTF(hits: [SCNHitTestResult]){
        
        print("Alert started")
        //Step : 1
        let alert = UIAlertController(title: "Label 3D", message: "Please input something", preferredStyle: UIAlertController.Style.alert )
        //Step : 2
        let save = UIAlertAction(title: "Save", style: .default) { [self] (alertAction) in
            let textField = alert.textFields![0] as UITextField
            if textField.text != "" {
                //Read TextFields text data
                let geoText = SCNText(string: textField.text, extrusionDepth: 0.1)
                geoText.font = UIFont(name: "Helvetica", size: 0.5)
                geoText.flatness = 0.2
                geoText.firstMaterial?.diffuse.contents = UIColor.blue
                let textNode = SCNNode(geometry: geoText)
                textNode.scale=SCNVector3Make(0.4, 0.4, 0.4)
                
                scene.rootNode.addChildNode(textNode)
                textNode.position = hits.last!.worldCoordinates
                
                sceneView.scene = scene
                print("Alert submitted: \(textField.text!)")
                                
            } else {
                print("TF 1 is Empty...")
                
            }
        }

        //Step : 3
        //For first TF
        alert.addTextField { (textField) in
            textField.placeholder = "Enter your first name"
            textField.textColor = .red
        }

        //Step : 4
        alert.addAction(save)
        //Cancel action
        let cancel = UIAlertAction(title: "Cancel", style: .default) { (alertAction) in }
        alert.addAction(cancel)
        //OR single line action
        //alert.addAction(UIAlertAction(title: "Cancel", style: .default) { (alertAction) in })

        self.present(alert, animated:true, completion: nil)
        print("Alert presented")
    }
    @objc
    func handleLongTap(sender: UILongPressGestureRecognizer) {
        
        if sender.state == .ended {
            
            // handling code
            let touchPoint = sender.location(in: sceneView)
            print(touchPoint)
            let hits = sceneView.hitTest(touchPoint, options: nil)
//            if let tappednode = hits. {
//                     //do something with tapped object
//                 }
            
            alertWithTF(hits: hits)
            
            
            //Perform hittest
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    // Create request
 
//    func createRequest(fileURL: String) throws -> URLRequest {
//
//        let boundary = generateBoundaryString()
//
//        let url = URL(string: "https://example.com/imageupload.php")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//
//        let fileURL = Bundle.main.url(forResource: "image1", withExtension: "png")!
//        request.httpBody = try createBody(with: parameters, filePathKey: "file", urls: [fileURL], boundary: boundary)
//
//        return request
//    }

    /// Create body of the `multipart/form-data` request
    ///
    /// - parameter parameters:   The optional dictionary containing keys and values to be passed to web service.
    /// - parameter filePathKey:  The optional field name to be used when uploading files. If you supply paths, you must supply filePathKey, too.
    /// - parameter urls:         The optional array of file URLs of the files to be uploaded.
    /// - parameter boundary:     The `multipart/form-data` boundary.
    ///
    /// - returns:                The `Data` of the body of the request.

    private func createBody(with parameters: [String: String]?, filePathKey: String, urls: [URL], boundary: String) throws -> Data {
        var body = Data()

        parameters?.forEach { (key, value) in
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        for url in urls {
            let filename = url.lastPathComponent
            let data = try Data(contentsOf: url)
            let mimetype = mimeType(for: filename)

            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(filename)\"\r\n")
            body.append("Content-Type: \(mimetype)\r\n\r\n")
            body.append(data)
            body.append("\r\n")
        }

        body.append("--\(boundary)--\r\n")
        return body
    }

    /// Create boundary string for multipart/form-data request
    ///
    /// - returns:            The boundary string that consists of "Boundary-" followed by a UUID string.

    private func generateBoundaryString() -> String {
        return "Boundary-\(UUID().uuidString)"
    }

    /// Determine mime type on the basis of extension of a file.
    ///
    /// This requires `import MobileCoreServices`.
    ///
    /// - parameter path:         The path of the file for which we are going to determine the mime type.
    ///
    /// - returns:                Returns the mime type if successful. Returns `application/octet-stream` if unable to determine mime type.

    private func mimeType(for path: String) -> String {
        let pathExtension = URL(fileURLWithPath: path).pathExtension as NSString

        guard
            let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, nil)?.takeRetainedValue(),
            let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue()
        else {
            return "application/octet-stream"
        }

        return mimetype as String
    }

}
