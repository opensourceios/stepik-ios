//
//  Progress+CoreDataProperties.swift
//  Stepic
//
//  Created by Alexander Karpov on 03.11.15.
//  Copyright © 2015 Alex Karpov. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import CoreData
import Foundation

extension Progress {
    @NSManaged var managedId: String?
    @NSManaged var managedIsPassed: NSNumber?
    @NSManaged var managedScore: NSNumber?
    @NSManaged var managedNumberOfSteps: NSNumber?
    @NSManaged var managedNumberOfStepsPassed: NSNumber?
    @NSManaged var managedCost: NSNumber?
    @NSManaged var managedLastViewed: NSNumber?

    @NSManaged var managedStep: Step?
    @NSManaged var managedSection: Section?
    @NSManaged var managedUnit: Unit?
    @NSManaged var managedCourse: Course?

    static var oldEntity: NSEntityDescription {
        NSEntityDescription.entity(forEntityName: "Progress", in: CoreDataHelper.shared.context)!
    }

    convenience init() {
        self.init(entity: Progress.oldEntity, insertInto: CoreDataHelper.shared.context)
    }

    var id: String {
        set(newId) {
            self.managedId = newId
        }
        get {
             managedId ?? ""
        }
    }

    var isPassed: Bool {
        get {
             managedIsPassed?.boolValue ?? false
        }
        set(value) {
            managedIsPassed = value as NSNumber?
        }
    }

    var lastViewed: Double {
        get {
             managedLastViewed?.doubleValue ?? 0
        }
        set(value) {
            managedLastViewed = value as NSNumber?
        }
    }

    var score: Int {
        get {
             managedScore?.intValue ?? 0
        }
        set(value) {
            managedScore = value as NSNumber?
        }
    }

    var numberOfSteps: Int {
        get {
             managedNumberOfSteps?.intValue ?? 0
        }
        set(value) {
            managedNumberOfSteps = value as NSNumber?
        }
    }

    var numberOfStepsPassed: Int {
        get {
             managedNumberOfStepsPassed?.intValue ?? 0
        }
        set(value) {
            managedNumberOfStepsPassed = value as NSNumber?
        }
    }

    var cost: Int {
        get {
             managedCost?.intValue ?? 0
        }
        set(value) {
            managedCost = value as NSNumber?
        }
    }
}
