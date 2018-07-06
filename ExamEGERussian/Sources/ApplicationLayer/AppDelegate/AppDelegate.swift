//
//  AppDelegate.swift
//  ExamEGERussian
//
//  Created by Ivan Magda on 03/07/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import UIKit

// MARK: AppDelegate: UIResponder, UIApplicationDelegate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Instance Properties
    
    var window: UIWindow?
    
    private lazy var rootNavigationManager: RootNavigationManager = {
        return RootNavigationManager(serviceComponents: self.serviceComponents)
    }()
    
    private lazy var serviceComponents: ServiceComponents = {
        return ServiceComponentsAssembly(
            authAPI: AuthAPI(),
            stepicsAPI: StepicsAPI(),
            profilesAPI: ProfilesAPI(),
            defaultsStorageManager: DefaultsStorageManager(),
            randomCredentialsGenerator: RandomCredentialsGeneratorImplementation()
        )
    }()
    
    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = window else {
            fatalError("Failed to instantiate window")
        }
        
        rootNavigationManager.setup(with: window)
        
        return true
    }
    
}
