package org.ranapat.resourceloader {
	import flash.system.ApplicationDomain;

	internal class ResourceLoaderCacheObject {
		public var uid:uint;
		public var target:Object;
		public var applicationDomain:ApplicationDomain;

		public function ResourceLoaderCacheObject(uid:uint, target:Object, applicationDomain:ApplicationDomain) {
			this.uid = uid;
			this.target = target;
			this.applicationDomain = applicationDomain;
		}
	}
}
