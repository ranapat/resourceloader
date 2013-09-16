package org.ranapat.resourceloader {
	final public class ResourceLoaderSettings {
		public static var RESOURCE_LOADER_AUTO_RESET_ON_EMPTY_QUEUE:Boolean = true;
		public static var RESOURCE_LOADER_TIMEOUT_INTERVAL:uint = 60 * 1000;
		public static var RESOURCE_LOADER_CACHE_DISPATCH_TIMER_INTERVAL:uint = .05 * 1000;
		public static var RESOURCE_LOADER_AUTO_LOAD_ALL_CLASSES:Boolean = true;
		public static var RESOURCE_LOADER_TIMEOUT_AUTO_RETRIES:uint = 0;
		public static var RESOURCE_LOADER_GENERAL_AUTO_RETRIES:uint = 0;
		
		public function ResourceLoaderSettings() {
			Tools.ensureAbstractClass(this, ResourceLoaderSettings);
		}
	}
}
