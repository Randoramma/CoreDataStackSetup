import UIKit
import CoreData

typealias DatabaseManagerCompletionHandler = (result: Bool, failureError: NSError?) -> Void

class DatabaseManager {

  private let fileName = "MyDataModel"
	
  private(set) var mainThreadManagedObjectContext: NSManagedObjectContext
  private var saveManagedObjectContext: NSManagedObjectContext
  
  init (completion: DatabaseManagerCompletionHandler) {
    let modelURL = NSBundle.mainBundle().URLForResource(self.fileName, withExtension: "momd")!
    let mom = NSManagedObjectModel(contentsOfURL: modelURL)!

    var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: mom)
    
    var saveMoc : NSManagedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
    saveMoc.persistentStoreCoordinator = coordinator
    saveManagedObjectContext = saveMoc

    var mainThreadMoc : NSManagedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
    mainThreadMoc.parentContext = saveManagedObjectContext
    mainThreadManagedObjectContext = mainThreadMoc
    
    let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    dispatch_async(queue, { () -> Void in
      let folderUrls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
      let folderUrl = folderUrls[folderUrls.count-1] as! NSURL
      let dataFileUrl = folderUrl.URLByAppendingPathComponent(self.fileName).URLByAppendingPathExtension("sqlite")
    
      var error: NSError? = nil
      let storeOptions = [ NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true ]
      if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: dataFileUrl, options: storeOptions, error: &error) == nil {
//        // You can return a custom error
//        var dict = [String: AnyObject]()
//        dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
//        dict[NSLocalizedFailureReasonErrorKey] = NSLocalizedString("There was an error creating or loading the application's saved data.", comment: "Core Data Stack Setup Failure Error")
//        dict[NSUnderlyingErrorKey] = error
//        error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
        completion(result: false, failureError: error)
        return
      } else {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
          completion(result: true, failureError: nil)
          return
        })
      }
    })
  }
  
  func saveDataWithCompletionHandler(completion: DatabaseManagerCompletionHandler) {
    if (!NSThread.isMainThread()) {
      dispatch_sync(dispatch_get_main_queue(), { () -> Void in
        self.saveDataWithCompletionHandler(completion)
      })
      return
    }
    
    if !self.mainThreadManagedObjectContext.hasChanges && !self.saveManagedObjectContext.hasChanges {
      completion(result: true, failureError: nil)
    }
    
    if (self.mainThreadManagedObjectContext.hasChanges) {
      var error: NSError? = nil
      if !self.mainThreadManagedObjectContext.save(&error) {
        completion(result: false, failureError: error)
        return;
      }
    }
    
    self.saveManagedObjectContext.performBlock { () -> Void in
      var error: NSError? = nil
      if !self.saveManagedObjectContext.save(&error) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
          completion(result: false, failureError: error)
          return;
        })
      } else {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
          completion(result: true, failureError: nil)
          return;
        })
      }
    }
  }
  
}
