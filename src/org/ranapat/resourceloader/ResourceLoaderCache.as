package org.ranapat.resourceloader {
	import flash.utils.Dictionary;

	internal class ResourceLoaderCache {
		private var cache:Dictionary;

		public function ResourceLoaderCache() {
			this.cache = new Dictionary();
		}

		public function add(key:String, value:ResourceLoaderCacheObject):void {
			this.cache[key] = value;
		}

		public function get(key:String):ResourceLoaderCacheObject {
			return this.cache[key];
		}

		public function check(key:String):Boolean {
			return this.cache[key] != null;
		}

		public function remove(key:String):void {
			this.cache[key] = null;
			delete this.cache[key];
		}
	}
}
