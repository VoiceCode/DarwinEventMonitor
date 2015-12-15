/*
 (nullable instancetype)observerWithName:(nullable NSString *)name; // DEPRECATED
 (nullable instancetype)observerWithPath:(nullable NSString *)fullPath;
 (nullable instancetype)observerWithURL:(nullable NSURL *)url;
 (nullable instancetype)observerWithBundleIdentifier:(nullable NSString *)bundleIdentifier;
 (nullable instancetype)observerWithPid:(pid_t)pid;
 (nullable instancetype)observerForInfoWithPath:(nullable NSString *)fullPath;
 (nullable instancetype)observerForInfoWithURL:(nullable NSURL *)url;
 (nullable instancetype)observerForInfoWithBundleIdentifier:(nullable NSString *)bundleIdentifier;
 (nullable instancetype)observerForInfoWithPid:(pid_t)pid;
 (nullable instancetype)observerWithName:(nullable NSString *)name notificationDelegate:(nullable id)callbackDelegate callbackSelector:(nullable SEL)callback;; // DEPRECATED
 (nullable instancetype)observerWithPath:(nullable NSString *)fullPath notificationDelegate:(nullable id)callbackDelegate callbackSelector:(nullable SEL)callback;
 (nullable instancetype)observerWithURL:(nullable NSURL *)url notificationDelegate:(nullable id)callbackDelegate callbackSelector:(nullable SEL)callback;
 (nullable instancetype)observerWithBundleIdentifier:(nullable NSString *)bundleIdentifier notificationDelegate:(nullable id)callbackDelegate callbackSelector:(nullable SEL)callback;
 (nullable instancetype)observerWithPid:(pid_t)pid notificationDelegate:(nullable id)callbackDelegate callbackSelector:(nullable SEL)callback;
 (nullable instancetype)observerForInfoWithPath:(nullable NSString *)fullPath notificationDelegate:(nullable id)callbackDelegate infoCallbackSelector:(nullable SEL)callback;
 (nullable instancetype)observerForInfoWithURL:(nullable NSURL *)url notificationDelegate:(nullable id)callbackDelegate infoCallbackSelector:(nullable SEL)callback;
 (nullable instancetype)observerForInfoWithBundleIdentifier:(nullable NSString *)bundleIdentifier notificationDelegate:(nullable id)callbackDelegate infoCallbackSelector:(nullable SEL)callback;
 (nullable instancetype)observerForInfoWithPid:(pid_t)pid notificationDelegate:(nullable id)callbackDelegate infoCallbackSelector:(nullable SEL)callback;
 (NSArray<__kindof PFObserver *> *)observersForPath:(NSString *)fullPath; // array of PFObserver* (__kindof only to allow for new subclasses)
 (NSArray<__kindof PFObserver *> *)observersForURL:(NSURL *)url; // array of PFObserver* (__kindof only to allow for new subclasses)
 (NSArray<__kindof PFObserver *> *)observersForBundleIdentifier:(NSString *)bundleIdentifier; // array of PFObserver* (__kindof only to allow for new subclasses)
 (NSArray<__kindof PFObserver *> *)observersForPid:(pid_t)pid; // array of PFObserver* (__kindof only to allow for new subclasses)
 (void)removeObserversForPath:(NSString *)fullPath;
 (void)removeObserversForURL:(NSURL *)url;
 (void)removeObserversForBundleIdentifier:(NSString *)bundleIdentifier;
 (void)removeObserversForPid:(pid_t)pid;