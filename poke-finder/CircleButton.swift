//
//  CircleButton.swift
//  poke-finder
//
//  Created by Maureen Biro on 2017-05-25.
//  Copyright © 2017 Aaryn Biro. All rights reserved.
//

import Foundation
import UIKit


//to make button circle

@IBDesignable

class CircleButton: UIButton {
    
    @IBInspectable var cornerRadius: CGFloat = 10.0 {  //round to half of width/height for perfect circle
        
        
        //need didSet to work
        didSet{
            setupView()
            
        }
        
    }
    
    override func prepareForInterfaceBuilder() {
        setupView()
    }
    
    func setupView(){
        layer.cornerRadius = cornerRadius
        
    }
    
    
    
    
}
