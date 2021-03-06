//
//  CKSubscription.swift
//  OpenCloudKit
//
//  Created by Ben Johnson on 12/07/2016.
//
//

import Foundation

public protocol CustomDictionaryConvertible {
    var dictionary: [String: Any] { get }
}

public enum CKSubscriptionType : Int, CustomStringConvertible {
    
    case query
    
    case recordZone
    
    public var description: String {
        switch self {
        case .query:
            return "query"
        case .recordZone:
            return "zone"
        }
    }
}

public class CKSubscription: NSObject {
    
    public let subscriptionID: String
    
    public let subscriptionType: CKSubscriptionType
    
    public var notificationInfo: CKNotificationInfo?

    init(subscriptionID: String, subscriptionType: CKSubscriptionType) {
        
        self.subscriptionID = subscriptionID
        
        self.subscriptionType = subscriptionType
        
    }
    
     init?(dictionary: [String: Any]) {
        
       guard let subscriptionID = dictionary["subscriptionID"] as? String,
        let subscriptionTypeValue = dictionary["subscriptionType"] as? String else {
            return nil
        }
        
        self.subscriptionID = subscriptionID
        
        let subscriptionType: CKSubscriptionType
        switch(subscriptionTypeValue) {
        case "zone":
            subscriptionType = CKSubscriptionType.recordZone
        default:
            subscriptionType = CKSubscriptionType.query
        }
        
        self.subscriptionType = subscriptionType
    }
}

extension CKSubscription {
    public var subscriptionDictionary: [String : Any] {
        switch self {
        case let querySub as CKQuerySubscription where self.subscriptionType == .query:
            return querySub.dictionary
        case let recordZoneSubscript as CKRecordZoneSubscription where self.subscriptionType == .recordZone:
            return recordZoneSubscript.dictionary
        default:
            return [:]
        }
    }
}



public struct CKQuerySubscriptionOptions : OptionSet {
    
    public var rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public static var firesOnRecordCreation: CKQuerySubscriptionOptions { return CKQuerySubscriptionOptions(rawValue: 1) }
    
    public static var firesOnRecordUpdate: CKQuerySubscriptionOptions { return CKQuerySubscriptionOptions(rawValue: 2)  }
    
    public static var firesOnRecordDeletion: CKQuerySubscriptionOptions { return CKQuerySubscriptionOptions(rawValue: 4)  }
    
    public static var firesOnce: CKQuerySubscriptionOptions {  return CKQuerySubscriptionOptions(rawValue: 8) }
    
    var firesOnArray: [String] {
        var array: [String] = []
        if contains(CKQuerySubscriptionOptions.firesOnRecordCreation) {
            array.append("create")
        }
        
        if contains(CKQuerySubscriptionOptions.firesOnRecordUpdate) {
            array.append("update")
        }
        
        if contains(CKQuerySubscriptionOptions.firesOnRecordDeletion) {
            array.append("delete")
        }
        
        return array
    }
}


public class CKQuerySubscription : CKSubscription {
    
    public convenience init(recordType: String, predicate: NSPredicate, options querySubscriptionOptions: CKQuerySubscriptionOptions) {
        
        let subscriptionID = NSUUID().uuidString
        self.init(recordType: recordType, predicate: predicate, subscriptionID: subscriptionID, options: querySubscriptionOptions)
    }
    
    public init(recordType: String, predicate: NSPredicate, subscriptionID: String, options querySubscriptionOptions: CKQuerySubscriptionOptions) {
        
        self.predicate = predicate
        
        self.recordType = recordType
        
        self.querySubscriptionOptions = querySubscriptionOptions
        
        super.init(subscriptionID: subscriptionID, subscriptionType: CKSubscriptionType.query)
        
       
    }
    
    /* The record type that this subscription watches */
    public let recordType: String
    
    /* A predicate that determines when the subscription fires. */
    public var predicate: NSPredicate
    
    /* Optional property.  If set, a query subscription is scoped to only record changes in the indicated zone. */
    public var zoneID: CKRecordZoneID?
    
    public let querySubscriptionOptions: CKQuerySubscriptionOptions
    
}


extension CKQuerySubscription {
     public var dictionary: [String: Any] {
        
        let query = CKQuery(recordType: recordType, predicate: predicate)
       
        var subscription: [String: Any] =  ["subscriptionID": subscriptionID.bridge(),
                "subscriptionType": subscriptionType.description.bridge(),
                "query": query.dictionary.bridge() as Any,
                "firesOn": querySubscriptionOptions.firesOnArray.bridge()]
        if querySubscriptionOptions.contains(CKQuerySubscriptionOptions.firesOnce) {
            subscription["firesOnce"] = NSNumber(value: true)
        }
        
        if let notificationInfo = notificationInfo {
            subscription["notificationInfo"] = notificationInfo.dictionary.bridge()

        }
    
        return subscription
    }
}

public class CKRecordZoneSubscription : CKSubscription {
    
    public convenience init(zoneID: CKRecordZoneID) {
        let subscriptionID = NSUUID().uuidString
        self.init(zoneID: zoneID, subscriptionID: subscriptionID)
    }
    
    public init(zoneID: CKRecordZoneID, subscriptionID: String) {
        self.zoneID = zoneID

        super.init(subscriptionID: subscriptionID, subscriptionType: CKSubscriptionType.recordZone)
    }
    
    public let zoneID: CKRecordZoneID
    
    public var recordType: String?
    
}

extension CKRecordZoneSubscription {
    
    public var dictionary: [String: Any] {
        
        var subscription: [String: Any] =  ["subscriptionID": subscriptionID.bridge(),
                                                  "subscriptionType": subscriptionType.description.bridge(),
                                                  "zoneID": zoneID.dictionary.bridge() as Any
                                                ]
       

        if let notificationInfo = notificationInfo {
            subscription["notificationInfo"] = notificationInfo.dictionary.bridge() as NSDictionary
        }
        
        return subscription
    }
}

public class CKNotificationInfo : NSObject {
    
    
    public var alertBody: String?
    
    
    public var alertLocalizationKey: String?
    
    
    public var alertLocalizationArgs: [String]?
    
    
    public var alertActionLocalizationKey: String?
    
    
    public var alertLaunchImage: String?
    
    
    public var soundName: String?
    
    
    public var desiredKeys: [String]?
    
    
    public var shouldBadge: Bool = false
    
    
    public var shouldSendContentAvailable: Bool = false
    
    
    public var category: String?
    
}

extension CKNotificationInfo {
    
    
    var dictionary: [String: Any] {
        
        var notificationInfo: [String: Any] = [:]
        
        notificationInfo[CKNotificationInfoDictionary.alertBodyKey] = alertBody?.bridge()
        
        notificationInfo[CKNotificationInfoDictionary.alertLocalizationKey] = alertLocalizationKey?.bridge()
        
        #if os(Linux)
        notificationInfo[CKNotificationInfoDictionary.alertLocalizationArgsKey] = alertLocalizationArgs?.bridge()
        #else
        notificationInfo[CKNotificationInfoDictionary.alertLocalizationArgsKey] = alertLocalizationArgs
        #endif

        notificationInfo[CKNotificationInfoDictionary.alertActionLocalizationKeyKey] = alertActionLocalizationKey?.bridge()
        
        notificationInfo[CKNotificationInfoDictionary.alertLaunchImageKey] = alertLaunchImage?.bridge()
        
        notificationInfo[CKNotificationInfoDictionary.soundName] = soundName?.bridge()
        
        notificationInfo[CKNotificationInfoDictionary.shouldBadge] = NSNumber(value: shouldBadge)
        
        notificationInfo[CKNotificationInfoDictionary.shouldSendContentAvailable] = NSNumber(value: shouldSendContentAvailable)
        
        
        return notificationInfo
        
    }
}

struct CKNotificationInfoDictionary {
    
    static let alertBodyKey = "alertBody"
    
    static let alertLocalizationKey = "alertLocalizationKey"
    
    static let alertLocalizationArgsKey = "alertLocalizationArgs"
    
    static let alertActionLocalizationKeyKey = "alertActionLocalizationKey"
    
    static let alertLaunchImageKey = "alertLaunchImage"
    
    static let soundName = "soundName"
    
    static let shouldBadge = "shouldBadge"
    
    static let shouldSendContentAvailable = "shouldSendContentAvailable"
    
}

