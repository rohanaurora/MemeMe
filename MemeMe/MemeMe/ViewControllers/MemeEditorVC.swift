//
//  ViewController.swift
//  MemeMe
//
//  Created by Rohan Aurora on 2021-01-16.
//

import UIKit

class MemeEditorVC: UIViewController,
                    UIImagePickerControllerDelegate,
                    UINavigationControllerDelegate,
                    UITextFieldDelegate {
    
    @IBOutlet weak var memeToolBar: UIToolbar!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var albumButton: UIBarButtonItem!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    @IBOutlet weak var navBar: UINavigationBar!
    
    var currentTextField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    private func setupViews() {
        navigationController?.navigationBar.topItem?.title = Constants.appTitle
        view.backgroundColor = .clear
        topTextField.delegate = self
        bottomTextField.delegate = self
        setupButtons()
        setupTextFields()
    }
    
    private func setupTextFields() {
        for tf in [topTextField, bottomTextField] {
            memeTextAttributes(tf!)
            showPlaceholderText(textField: tf!)
            tf?.textAlignment = .center
            tf?.autocapitalizationType = .allCharacters
            tf?.backgroundColor = UIColor.clear
            tf?.adjustsFontSizeToFitWidth = false
        }
    }
    
    private func setupButtons() {
        let closeButton = UIBarButtonItem(barButtonSystemItem:.cancel, target: self, action: #selector(self.cancelButtonPressed))
        navigationItem.rightBarButtonItem = closeButton

        let shareButton = UIBarButtonItem(barButtonSystemItem:.action, target: self, action: #selector(self.shareButtonPressed))
        navigationItem.leftBarButtonItem = shareButton
    }
    
    // After picking an image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        selectedImageView.image = image
        dismiss(animated: true)
    }
    
    // Helper method
    private func memeTextAttributes(_ textField: UITextField)  {
        let customAttr: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.strokeColor: UIColor.black,
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
            NSAttributedString.Key.strokeWidth:  -3
        ]
        textField.defaultTextAttributes = customAttr
    }
    
    // MARK: - Keyboard
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector:  #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @IBAction func keyboardWillShow(_ notification: Notification) {
        if bottomTextField.isFirstResponder {
            view.frame.origin.y -= getKeyboardHeight(notification)
        }
    }
    
    @IBAction func keyboardWillHide(_ notification: Notification) {
        if bottomTextField.isFirstResponder {
            view.frame.origin.y = 0
        }
    }
    
    func getKeyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    // MARK: - TextField Delegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        hidePlaceholderText(textField: textField)
        currentTextField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        showPlaceholderText(textField: textField)
        currentTextField = nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    private func hidePlaceholderText(textField: UITextField) {
        if textField == topTextField && textField.text! == Constants.topPlaceholderText {
            textField.text = ""
        }
        if textField == bottomTextField && textField.text! == Constants.bottomPlaceholderText {
            textField.text = ""
        }
    }
    
    private func showPlaceholderText(textField: UITextField) {
        if textField == topTextField && textField.text! == "" {
            textField.attributedPlaceholder = NSAttributedString(string: Constants.topPlaceholderText, attributes: [NSAttributedString.Key.foregroundColor : UIColor.white])

        }
        if textField == bottomTextField && textField.text! == "" {
            textField.attributedPlaceholder = NSAttributedString(string: Constants.bottomPlaceholderText, attributes: [NSAttributedString.Key.foregroundColor : UIColor.white])
        }
    }

    private func hideBars(_ isHidden: Bool) {
        memeToolBar.isHidden = !isHidden
        navigationController?.navigationBar.isHidden = !isHidden
    }
    
    // MARK: Memed image
    
    private func generateMemedImage() -> UIImage {
        hideBars(false)
        
        UIGraphicsBeginImageContextWithOptions(view.frame.size, view.isOpaque, 0.0)
        view.drawHierarchy(in: view.frame, afterScreenUpdates: true)
        let memedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        hideBars(true)
        
        return memedImage
    }
    
    private func saveMeme(_ memedImage: UIImage) -> Meme {
        let meme = Meme(topText: topTextField.text!, bottomText: bottomTextField.text!, originalImage: selectedImageView, memedImage: memedImage)
        return meme
    }
}

extension MemeEditorVC {

// MARK: - Actions

    @IBAction func openPhotos(_ sender: UIBarButtonItem) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = true
        pickerController.sourceType = .photoLibrary
        present(pickerController, animated: true, completion: nil)
    }
    
    @IBAction func openCamera(_ sender: UIBarButtonItem) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonPressed() {
        selectedImageView.image = nil
        topTextField.text = Constants.topPlaceholderText
        bottomTextField.text = Constants.bottomPlaceholderText
    }

    @IBAction func shareButtonPressed() {
        let memedImage = generateMemedImage()
        let avc = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
        present(avc, animated: true)
        avc.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed: Bool, arrayReturnedItems: [Any]?, error: Error?) in
            if completed {
                _ = self.saveMeme(memedImage)
            }
        }
    }
}
