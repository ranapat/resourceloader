package org.ranapat.resourceloader {
	
	internal final class ResourceLoaderConstants {
		public static const PENDING:uint = 0;
		public static const LOADING:uint = 1;
		public static const COMPLETE:uint = 2;
		public static const ERROR:uint = 3;
		public static const TIMEOUT:uint = 4;
		
		public static const DEFAULT_BUNDLE_NAME:String = "default";
		public static const FAIL_REASON_TIMEOUT:String = "timeout";
		public static const PARAMETER_LOAD_ALL_CLASSES_FROM_APPLICATION_DOMAIN:String = "loadAppClassesFromApplicationDomain";
		
		public function ResourceLoaderConstants() {
			Tools.ensureAbstractClass(this, ResourceLoaderConstants);
		}
	}
}
