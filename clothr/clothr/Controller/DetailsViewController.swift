//
//  DetailsViewController.swift
//  clothr
//
//  Created by Andrew Guterres on 11/16/17.
//  Copyright © 2017 cmps115. All rights reserved.
//

import UIKit

class DetailsViewController: UIViewController, UICollectionViewDelegate,UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource {

    var originalCheck = false
    var imageIndex: NSInteger=0
    let tabs = ["Details", "Sizes", "Colors", "More"]
    var selected=[1,0,0,0]
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var whiteBackground: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var availability: UILabel!
    @IBOutlet weak var SaleCheckLabel: UILabel!
    
    @IBOutlet weak var imageFrame: UIView!
    @IBOutlet weak var retailer: UILabel!
    @IBOutlet var overallView: UIView!
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var sizeView: UIView!
    @IBOutlet weak var descriptionView: UIView!
    @IBOutlet weak var detailsView: UIView!
    @IBOutlet weak var tabCollection: UICollectionView!
    
    
    @IBOutlet weak var sizeTable: UITableView!
    @IBOutlet weak var colorTable: UITableView!
//    @IBOutlet weak var productDescription: UILabel!
    @IBOutlet weak var productDescription: UITextView!
    @IBOutlet weak var brandLabel: UILabel!
    var product = NSKeyedUnarchiver.unarchiveObject(with: UserDefaults.standard.object(forKey: "product") as! Data) as! PSSProduct
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        whiteBackground.layer.borderColor=UIColor.black.cgColor
        whiteBackground.layer.borderWidth=5
        whiteBackground.layer.cornerRadius=10.5
        imageFrame.layer.borderWidth=4
        imageFrame.layer.cornerRadius=5.5
        imageFrame.layer.borderColor=UIColor.black.cgColor
        get_image(image)
        colorTable.tableFooterView = UIView()
        sizeTable.tableFooterView = UIView()
        let changePic = UITapGestureRecognizer(target: self, action: #selector(changeImage))
        changePic.numberOfTapsRequired=1
        image.addGestureRecognizer(changePic)
        let goBack=UISwipeGestureRecognizer(target: self, action: #selector(backToSwipe(gestureRecognizer:)))
        goBack.direction=UISwipeGestureRecognizerDirection.down
        self.view.addGestureRecognizer(goBack)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//-------------------------------change the image--------------------------------------//
    
    @objc func changeImage()
    {
        get_image(image)
    }
//-------------------------------what will appear when page is opened------------------//
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
        nameLabel.text=product.name
//        productDescription.text=product.descriptionHTML
        let content = product.descriptionHTML
        let replacedString = content?.replacingOccurrences(of: "<[^>]+>", with: "", options: String.CompareOptions.regularExpression, range: nil)
        let returnedString = replacedString?.replacingOccurrences(of: "&[^;]+;", with: "", options: String.CompareOptions.regularExpression, range: nil)
        productDescription.text=returnedString
        if product.brand != nil
        {
            brandLabel.text="Brand: " + product.brand.name
        } else
        {
            brandLabel.text="Brand: Not available"
        }
        if product.retailer != nil
        {
            retailer.text = "Retailer: " + product.retailer.name
        } else
        {
            retailer.text = "Retailer: Not available"
        }
//        retailer.text = "Retailer: " + product.retailer.name
        if(product.isOnSale())
        {
            priceLabel.text=product.salePriceLabel
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: product.regularPriceLabel)
            attributeString.addAttribute(NSAttributedStringKey.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
            attributeString.addAttribute(NSAttributedStringKey.strikethroughColor, value: UIColor.red, range: NSMakeRange(0, attributeString.length))
            SaleCheckLabel.attributedText = attributeString
        } else
        {
            priceLabel.text=product.regularPriceLabel
            SaleCheckLabel.text=""
        }
        
        if(product.inStock)
        {
            availability.text="In Stock"
        } else
        {
            availability.text="Not In Stock"
            availability.textColor=UIColor.red
        }
    }
    
//---------------------------------get image for detail function--------------------------------//
    func get_image(_ imageView:UIImageView)
    {
        let url = get_url(product)
        let session = URLSession.shared
        
        let task = session.dataTask(with: url, completionHandler: {
            (
            data, response, error) in
            if data != nil
            {
                let image = UIImage(data: data!)
                if(image != nil)
                {
                    DispatchQueue.main.async(execute: {
                        imageView.image = image
                        imageView.contentMode = .scaleAspectFit
                    })
                }
            }
        })
        imageIndex = imageIndex+1
        task.resume()
    }
    
    func get_url(_ product:PSSProduct) -> (URL)
    {
        let images=product.alternateImages
        if((images?.count)==nil)
        {
            return product.image.url //there's no alternative images
        }
        let check = images![imageIndex] as! PSSProductImage
        let check2 = images![(images?.count)!-1] as! PSSProductImage
        
        if(originalCheck==false)    //if it's the original photo
        {
            originalCheck=true
            return product.image.url
        } else if (check.url==check2.url) //if its the last in the array, circle back
        {
            imageIndex=0
            originalCheck=false
            return check2.url
        } else  //anywhere else
        {
            return check.url
        }
    }
    
//------------------------------UI functions-------------------------------//
    @objc func backToSwipe(gestureRecognizer: UISwipeGestureRecognizer)
    {
        dismiss(animated: true, completion: nil)
    }
    
//=============================detail stuff================================//
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
            return tabs.count;
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let detailCell=collectionView.dequeueReusableCell(withReuseIdentifier: "tab", for: indexPath) as! DetailsCollectionViewCell
            detailCell.layer.borderWidth=2
            detailCell.layer.cornerRadius=10.5
            if(selected[indexPath.row]==1)
            {
                detailCell.backgroundColor = UIColor.darkGray
                detailCell.tabLabel.textColor=UIColor.white
            } else {
                detailCell.backgroundColor = UIColor.white
                detailCell.tabLabel.textColor=UIColor.black
            }
            detailCell.tabLabel.text=tabs[indexPath.row]
            return detailCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(collectionView==tabCollection)
        {
            switch indexPath.row
            {
            case 1:
            do {
                resetLabels()
                selected[1]=1
                self.overallView.bringSubview(toFront: sizeView)
            }
            case 2:
            do
            {
                resetLabels()
                selected[2]=1
                self.overallView.bringSubview(toFront: colorView)
            }
            case 3:
            do
            {
                resetLabels()
                selected[3]=1
                self.overallView.bringSubview(toFront: descriptionView)
            }
            default:
            do
            {
                resetLabels()
                selected[0]=1
                self.overallView.bringSubview(toFront: detailsView)
            }
            }
            tabCollection.reloadData()
        }
    }
    
    func resetLabels()
    {
        selected=[0,0,0,0]
    }
//-----------------------------table stuff--------------------------------//
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView==sizeTable)
        {
            if(product.sizes==nil)
            {
                return 1
            }
            return product.sizes.count
        }
        if(product.colors==nil)
        {
            return 1
        }
        return product.colors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(tableView==sizeTable)
        {
            let sizeCell = tableView.dequeueReusableCell(withIdentifier: "sizeCell") as! DetailsTableViewCell
            if(product.sizes==nil)
            {
                sizeCell.sizeLabel.text="Sorry, no sizes available"
                return sizeCell
            }
            let size: PSSProductSize? = product.sizes[indexPath.row] as? PSSProductSize
            sizeCell.sizeLabel.text=size?.name
            return sizeCell
        }
        let colorCell = tableView.dequeueReusableCell(withIdentifier: "colorCell") as! DetailsTableViewCell
        if(product.colors==nil)
        {
            colorCell.colorLabel.text="Sorry, no colors Available"
            return colorCell
        }
        let color: PSSProductColor? = product.colors[indexPath.row] as? PSSProductColor
        colorCell.colorLabel.text=color?.name
        return colorCell
    }
}
