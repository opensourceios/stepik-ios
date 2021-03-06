//
//  Section+CoreDataProperties.swift
//  Stepic
//
//  Created by Alexander Karpov on 08.10.15.
//  Copyright © 2015 Alex Karpov. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import CoreData
import Foundation

extension Section {
    @NSManaged var managedId: NSNumber?
    @NSManaged var managedPosition: NSNumber?
    @NSManaged var managedTitle: String?
    @NSManaged var managedBeginDate: Date?
    @NSManaged var managedEndDate: Date?
    @NSManaged var managedSoftDeadline: Date?
    @NSManaged var managedHardDeadline: Date?
    @NSManaged var managedActive: NSNumber?
    @NSManaged var managedProgressId: String?
    @NSManaged var managedTestSectionAction: String?
    @NSManaged var managedIsExam: NSNumber?
    @NSManaged var managedCourseId: NSNumber?
    @NSManaged var managedDiscountingPolicy: String?
    @NSManaged var managedUnitsArray: NSObject?
    // Required section
    @NSManaged var managedIsRequirementSatisfied: NSNumber?
    @NSManaged var managedRequiredSectionID: NSNumber?
    @NSManaged var managedRequiredPercent: NSNumber?
    // Relationships
    @NSManaged var managedUnits: NSOrderedSet?
    @NSManaged var managedCourse: Course?
    @NSManaged var managedProgress: Progress?

    static var oldEntity: NSEntityDescription {
        NSEntityDescription.entity(forEntityName: "Section", in: CoreDataHelper.shared.context)!
    }

    convenience init() {
        self.init(entity: Section.oldEntity, insertInto: CoreDataHelper.shared.context)
    }

    var id: Int {
        set(newId) {
            self.managedId = newId as NSNumber?
        }
        get {
             managedId?.intValue ?? -1
        }
    }

    var progressId: String? {
        get {
             managedProgressId
        }
        set(value) {
            managedProgressId = value
        }
    }

    var testSectionAction: String? {
        get {
             managedTestSectionAction
        }
        set(value) {
            managedTestSectionAction = value
        }
    }

    var position: Int {
        set(value) {
            self.managedPosition = value as NSNumber?
        }
        get {
             managedPosition?.intValue ?? -1
        }
    }

    var title: String {
        set(value) {
            self.managedTitle = value
        }
        get {
             managedTitle ?? "No title"
        }
    }

    var beginDate: Date? {
        set(date) {
            self.managedBeginDate = date
        }
        get {
             managedBeginDate
        }
    }

    var endDate: Date? {
        set {
            self.managedEndDate = newValue
        }
        get {
             managedEndDate
        }
    }

    var softDeadline: Date? {
        set(date) {
            self.managedSoftDeadline = date
        }
        get {
             managedSoftDeadline
        }
    }

    var hardDeadline: Date? {
        set(date) {
            self.managedHardDeadline = date
        }
        get {
             managedHardDeadline
        }
    }

    var isActive: Bool {
        set(value) {
            self.managedActive = value as NSNumber?
        }
        get {
             managedActive?.boolValue ?? false
        }
    }

    var isExam: Bool {
        set(value) {
            self.managedIsExam = value as NSNumber?
        }
        get {
             managedIsExam?.boolValue ?? false
        }
    }

    var courseId: Int {
        set(newId) {
            self.managedCourseId = newId as NSNumber?
        }
        get {
             managedCourseId?.intValue ?? -1
        }
    }

    var course: Course? {
        get {
             managedCourse
        }
        set {
            managedCourse = newValue
        }
    }

    var progress: Progress? {
        get {
             managedProgress
        }
        set(value) {
            managedProgress = value
        }
    }

    var units: [Unit] {
        get {
             (managedUnits?.array as? [Unit]) ?? []
        }
        set(value) {
            managedUnits = NSOrderedSet(array: value)
        }
    }

    var unitsArray: [Int] {
        set(value) {
            self.managedUnitsArray = value as NSObject?
        }
        get {
             (self.managedUnitsArray as? [Int]) ?? []
        }
    }

    var discountingPolicy: String? {
        get {
             self.managedDiscountingPolicy
        }
        set {
            self.managedDiscountingPolicy = newValue
        }
    }

    var discountingPolicyType: DiscountingPolicy {
        DiscountingPolicy(rawValue: self.discountingPolicy ?? "") ?? .noDiscount
    }

    var isRequirementSatisfied: Bool {
        get {
             self.managedIsRequirementSatisfied?.boolValue ?? true
        }
        set {
            self.managedIsRequirementSatisfied = newValue as NSNumber?
        }
    }

    var requiredSectionID: Section.IdType? {
        get {
             self.managedRequiredSectionID?.intValue
        }
        set {
            self.managedRequiredSectionID = newValue as NSNumber?
        }
    }

    var requiredPercent: Int {
        get {
             self.managedRequiredPercent?.intValue ?? 0
        }
        set {
            self.managedRequiredPercent = newValue as NSNumber?
        }
    }
}
